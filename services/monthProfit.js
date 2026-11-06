// Report and closing use the same historical prices, receipt costs and per-line rounding.
const linesSql = `
        WITH sales AS (
            SELECT id, reading_date AS d, nozzle_name, fuel_type AS product,
                   liters_sold AS qty, 'fuel'::text AS kind
            FROM meter_readings
            WHERE user_id = $1 AND reading_date BETWEEN $2::date AND $3::date AND liters_sold > 0
            UNION ALL
            SELECT id, sale_date, 'Mobiloil Counter', item_name, liters_sold, 'lubricants'
            FROM lubricant_shift_sales
            WHERE user_id = $1 AND sale_date BETWEEN $2::date AND $3::date AND liters_sold > 0
        ), receipts AS (
            SELECT day.work_date AS d, category.kind, item.key AS product,
                   (item.value->>'amount')::numeric / NULLIF((item.value->>'qty')::numeric, 0) AS unit_cost
            FROM meter_flow_days day
            CROSS JOIN (VALUES ('fuel'), ('lubricants')) category(kind)
            CROSS JOIN LATERAL jsonb_each(day.inputs -> category.kind) item
            WHERE day.user_id = $1 AND day.work_date <= $3::date
              AND (item.value->>'qty')::numeric > 0 AND (item.value->>'amount')::numeric > 0
        ), priced AS (
            SELECT s.*, COALESCE(receipt.unit_cost, NULLIF(price.purchase_price, 0)) AS cost,
                   NULLIF(price.rate_per_litre, 0) AS selling,
                   CASE WHEN receipt.unit_cost IS NOT NULL THEN 'Receipt ' || receipt.d::text
                        WHEN price.purchase_price > 0 THEN 'Pricing ' || price.rate_date::text END AS cost_source
            FROM sales s
            LEFT JOIN LATERAL (
                SELECT unit_cost, d FROM receipts r
                WHERE r.kind=s.kind AND lower(trim(r.product))=lower(trim(s.product)) AND r.d<=s.d
                ORDER BY r.d DESC LIMIT 1
            ) receipt ON true
            LEFT JOIN LATERAL (
                SELECT purchase_price, rate_per_litre, rate_date FROM fuel_rates f
                WHERE (f.user_id=$1 OR f.user_id IS NULL) AND f.rate_date<=s.d
                  AND (lower(trim(s.product)) IN (lower(trim(f.product_name)),lower(trim(f.specific_category)))
                    OR (s.kind='fuel' AND lower(trim(s.product))=lower(trim(f.product_type))))
                ORDER BY (f.user_id IS NOT NULL) DESC, f.rate_date DESC, f.id DESC LIMIT 1
            ) price ON true
        ), lines AS (
            SELECT id, d::text AS reading_date, nozzle_name, product AS fuel_type, kind, qty AS quantity,
                   cost AS cost_rate, selling AS selling_rate, cost_source,
                   round(qty*cost,2) AS total_cost_pkr, round(qty*selling,2) AS total_revenue_pkr,
                   round(qty*selling,2)-round(qty*cost,2) AS gross_profit_pkr
            FROM priced
        )`;

const reportSql = `${linesSql}, totals AS (
            SELECT COALESCE(sum(quantity) FILTER (WHERE kind='fuel'),0) AS total_liters_sold,
                   COALESCE(sum(quantity) FILTER (WHERE kind='lubricants'),0) AS total_lubricant_units,
                   CASE WHEN count(*)=count(total_revenue_pkr) THEN COALESCE(sum(total_revenue_pkr),0) END AS total_revenue_pkr,
                   CASE WHEN count(*)=count(total_cost_pkr) THEN COALESCE(sum(total_cost_pkr),0) END AS total_cost_pkr,
                   count(*) FILTER (WHERE gross_profit_pkr IS NULL) AS missing_rate_rows
            FROM lines
        ), expenses AS (
            SELECT COALESCE(sum(debit_udhaar),0) AS total_expenses_pkr FROM daily_sheets
            WHERE user_id=$1 AND sheet_date BETWEEN $2::date AND $3::date
              AND lower(trim(search_id))=ANY($4::text[])
        )
        SELECT (SELECT COALESCE(jsonb_agg(to_jsonb(l) ORDER BY reading_date,kind,id),'[]'::jsonb) FROM lines l) AS data,
               to_jsonb(t) || to_jsonb(e) || jsonb_build_object(
                   'gross_profit_pkr', total_revenue_pkr-total_cost_pkr,
                   'total_profit_pkr', total_revenue_pkr-total_cost_pkr-total_expenses_pkr
               ) AS summary
        FROM totals t CROSS JOIN expenses e`;

const { createHash } = require('node:crypto');

function postingKey(userId, end, category) {
    const hex = createHash('sha256').update('bhatti:month-profit:v1:'+userId+':'+end+':'+category).digest('hex');
    return [hex.slice(0,8), hex.slice(8,12), '8'+hex.slice(13,16), '8'+hex.slice(17,20), hex.slice(20,32)].join('-');
}

function rejectClosing(message) {
    const error = new Error(message);
    error.status = 409;
    throw error;
}

async function postClosedMonth(client, userId, end) {
    const start = end.slice(0,7)+'-01';
    const legacy = await client.query(`SELECT id FROM daily_sheets WHERE user_id=$1
        AND sheet_date BETWEEN $2::date AND $3::date
        AND description LIKE 'Month-End Profit Return (%' LIMIT 1`, [userId,start,end]);
    if (legacy.rows.length) rejectClosing('Existing month-end posting for '+end.slice(0,7)+' (row '+legacy.rows[0].id+'). Reconcile it before closing to avoid double debit.');

    const result = await client.query(`${linesSql}
        SELECT CASE WHEN kind='lubricants' THEN 'lub' WHEN lower(trim(fuel_type))='diesel' THEN 'dl'
                    WHEN lower(trim(fuel_type))='super' THEN 'super' ELSE 'unknown' END AS category,
               sum(gross_profit_pkr) AS profit, count(*) FILTER (WHERE gross_profit_pkr IS NULL) AS missing
        FROM lines GROUP BY 1`, [userId,start,end]);

    const amounts = new Map();
    for (const row of result.rows) {
        if (Number(row.missing)>0 || row.category==='unknown') rejectClosing('Check missing purchase/sale rates or product mapping in Dispenser Profit for '+start+' to '+end+'.');
        amounts.set(row.category,row.profit);
    }
    for (const [category, label] of [['dl','Diesel'],['super','Super'],['lub','Mobil Oil']]) {
        const key = postingKey(userId,end,category);
        const amount = amounts.get(category) || '0';
        if (Number(amount)<=0) {
            // Remove only our own previously positive posting when a correction eliminates its profit.
            await client.query('DELETE FROM daily_sheets WHERE user_id=$1 AND client_row_id=$2::uuid',[userId,key]);
            continue;
        }
        let account=category;
        if (category==='super') {
            const existing=await client.query(`SELECT search_id FROM daily_customers
                WHERE user_id=$1 AND lower(trim(search_id))='sup' LIMIT 1`,[userId]);
            account=existing.rows.length?'sup':'sp';
        }
        await client.query(`INSERT INTO daily_customers(customer_name,search_id,user_id)
            VALUES ($1,$2,$3) ON CONFLICT (search_id,user_id) DO NOTHING`,[label+' Khata',account,userId]);
        await client.query(`INSERT INTO daily_sheets
            (search_id,debit_udhaar,credit_vasooli,total_balance,description,sheet_date,user_id,client_row_id)
            VALUES ($1,$2::numeric,0,-($2::numeric),$3,$4::date,$5,$6::uuid)
            ON CONFLICT (user_id,client_row_id) DO UPDATE SET search_id=EXCLUDED.search_id,
            debit_udhaar=EXCLUDED.debit_udhaar,credit_vasooli=0,total_balance=EXCLUDED.total_balance,
            description=EXCLUDED.description`,[account,amount,'Month-end profit | '+label+' | '+start+' to '+end,end,userId,key]);
    }
}
module.exports = { reportSql, postClosedMonth };
