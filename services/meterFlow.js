'use strict';
const { postClosedMonth } = require('./monthProfit');
const crypto = require('crypto');
const M = require('./meterMath');
const { FUELS, NOZZLES, fail, date, nextDate } = M;
function user(value) { if (!/^\d+$/.test(String(value)) || Number(value) < 1 || Number(value) > 2147483647) fail('Valid userId required.'); return Number(value); }
function uuid(value) { if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value || '')) fail('Valid request_id required.'); return value; }
function createService(db) {
    async function transaction(work, readOnly = false) {
        const client = await db.getClient();
        try {
            await client.query(readOnly ? 'BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY' : 'BEGIN');
            const result = await work(client);
            await client.query('COMMIT');
            return result;
        } catch (error) {
            try { await client.query('ROLLBACK'); } catch (_) { /* original error preserved */ }
            throw error;
        } finally { client.release(); }
    }
    const lock = (c, id) => c.query('SELECT pg_advisory_xact_lock(73142, $1::integer)', [id]);
    async function configuration(c, id) {
        return (await c.query("SELECT user_id, start_date::text AS start_date, baseline, legacy_snapshot, revision FROM meter_flow_setup WHERE user_id=$1", [id])).rows[0];
    }
    async function days(c, id) {
        return (await c.query('SELECT user_id, work_date::text AS work_date, inputs, snapshot, links, version FROM meter_flow_days WHERE user_id=$1 ORDER BY meter_flow_days.work_date', [id])).rows;
    }
    async function lastLegacyDate(c, id) {
        return (await c.query('SELECT MAX(reading_date)::text AS d FROM meter_readings WHERE user_id=$1', [id])).rows[0].d;
    }
    async function items(c, id) {
        const rows = (await c.query('SELECT item_name FROM lubricant_stocks WHERE user_id=$1 ORDER BY id', [id])).rows;
        return rows.length ? rows.map(r => r.item_name) : M.DEFAULT_LUBRICANTS;
    }
    async function rates(c, id, d, itemNames) {
        // User-specific rate wins over shared rate; no future rates, no sale-rate fallback.
        const rows = (await c.query(`SELECT * FROM fuel_rates
            WHERE (user_id=$1 OR user_id IS NULL) AND rate_date <= $2::date
            ORDER BY (user_id IS NOT NULL) DESC, rate_date DESC, id DESC`, [id, d])).rows;
        const out = { fuel: {}, lubricants: {} };
        const clean = s => String(s || '').trim().toLowerCase();
        for (const f of FUELS) {
            const r = rows.find(r => clean(r.product_type) === clean(f));
            out.fuel[f] = r ? Number(r.purchase_price) || 0 : 0;
        }
        for (const name of itemNames) {
            const r = rows.find(r => clean(r.product_name) === clean(name) || clean(r.specific_category) === clean(name));
            out.lubricants[name] = r ? Number(r.purchase_price) || 0 : 0;
        }
        return out;
    }
    async function setupInfo(c, id) {
        const latest = await lastLegacyDate(c, id);
        const d = latest ? nextDate(latest) : new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Karachi', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
        const prior = (await c.query(`SELECT DISTINCT ON (nozzle_name) nozzle_name, closing_reading
            FROM meter_readings WHERE user_id=$1 ORDER BY nozzle_name, reading_date DESC, id DESC`, [id])).rows;
        return { setup_required: true, default_date: d, latest_legacy_date: latest,
            nozzles: Object.fromEntries(NOZZLES.map(n => [n, prior.find(r => r.nozzle_name === n)?.closing_reading ?? null])),
            items: await items(c, id) };
    }
    async function getDay(rawUser, requestedDate) {
        const id = user(rawUser);
        return transaction(async c => {
            const config = await configuration(c, id);
            if (!config) return setupInfo(c, id);
            const records = await days(c, id);
            const defaultDate = records.length ? nextDate(records.at(-1).work_date) : config.start_date;
            const d = requestedDate ? date(requestedDate) : defaultDate;
            if (d < config.start_date) fail('This date belongs to the preserved pre-setup history. Choose ' + config.start_date + ' or later.');
            if (d > defaultDate) fail('Close days in order. Next working date: ' + defaultDate);
            const saved = records.find(r => r.work_date === d);
            const previous = records.filter(r => r.work_date < d).at(-1);
            const opening = saved ? saved.snapshot.opening : previous ? previous.snapshot.closing : config.baseline;
            const itemNames = Object.keys(config.baseline.lubricants);
            const price = await rates(c, id, d, itemNames);
            return { setup_required: false, date: d, default_date: defaultDate, start_date: config.start_date,
                last_saved_date: records.length ? records.at(-1).work_date : await lastLegacyDate(c, id),
                revision: config.revision, version: saved?.version || 0, saved: !!saved,
                opening, inputs: saved?.inputs || M.blankInputs(opening, price), rates: price,
                snapshot: saved?.snapshot || null, items: itemNames };
        }, true);
    }
    async function initialize(body) {
        const id = user(body.userId), start = date(body.start_date);
        return transaction(async c => {
            await lock(c, id);
            const existing = await configuration(c, id);
            if (existing) {
                const candidate = M.normalizeBaseline(body.baseline, Object.keys(existing.baseline.lubricants));
                if (existing.start_date === start && JSON.stringify(candidate) === JSON.stringify(existing.baseline)) return { default_date: start, already_initialized: true };
                // JSONB can reorder keys; compare normalized JSON structures instead.
                const same = (a, b) => JSON.stringify(Object.entries(a).sort()) === JSON.stringify(Object.entries(b).sort());
                if (existing.start_date === start && ['nozzles', 'fuel', 'lubricants'].every(k => same(candidate[k], existing.baseline[k]))) return { default_date: start, already_initialized: true };
                fail('Opening setup already exists. Refresh the page; it cannot be overwritten here.', 409);
            }
            const latest = await lastLegacyDate(c, id);
            if (latest && start <= latest) fail('Start date must be after the preserved meter history (' + latest + ').');
            const names = await items(c, id);
            const baseline = M.normalizeBaseline(body.baseline, names);
            const legacy = {
                fuel_stocks: (await c.query('SELECT * FROM fuel_stocks WHERE user_id=$1', [id])).rows,
                lubricant_stocks: (await c.query('SELECT * FROM lubricant_stocks WHERE user_id=$1', [id])).rows
            };
            await c.query(`INSERT INTO meter_flow_setup (user_id,start_date,baseline,legacy_snapshot)
                VALUES ($1,$2::date,$3::jsonb,$4::jsonb)`, [id,start,JSON.stringify(baseline),JSON.stringify(legacy)]);
            await publishStocks(c,id,baseline,{Diesel:0,Super:0},baseline);
            return { default_date: start };
        });
    }
    async function publishStocks(c,id,closing,receipts,baseline) {
        for (const f of FUELS) await c.query(`INSERT INTO fuel_stocks (fuel_type,current_stock,opening_stock,receipt_stock,user_id)
            VALUES ($1,$2,$3,$4,$5) ON CONFLICT (fuel_type,user_id) DO UPDATE SET
            current_stock=EXCLUDED.current_stock, opening_stock=EXCLUDED.opening_stock, receipt_stock=EXCLUDED.receipt_stock`,
            [f,closing.fuel[f],baseline.fuel[f],receipts[f],id]);
        for (const [name,qty] of Object.entries(closing.lubricants)) await c.query(`INSERT INTO lubricant_stocks
            (item_name,current_stock,shift_sales_deduct,user_id) VALUES ($1,$2,0,$3)
            ON CONFLICT (item_name,user_id) DO UPDATE SET current_stock=EXCLUDED.current_stock, shift_sales_deduct=0, updated_at=now()`, [name,qty,id]);
    }
    async function receiptEntry(c,id,d,key,amount,description,links) {
        // Update only this day's own linked rows. Never match/delete manual customer entries.
        let entryId = links[key];
        if (entryId) {
            const result = await c.query(`UPDATE daily_sheets SET debit_udhaar=$1, credit_vasooli=0,
                description=$2,total_balance=-($1::numeric) WHERE id=$3 AND user_id=$4 AND sheet_date=$5::date RETURNING id`, [amount,description,entryId,id,d]);
            if (result.rows.length) return;
            delete links[key];
        }
        if (!amount) return;
        const search = key === 'Diesel' ? 'dl' : key === 'Super' ? 'sp' : 'lub';
        const name = search === 'dl' ? 'Diesel Khata' : search === 'sp' ? 'Super Petrol Khata' : 'Moblile Khata';
        await c.query(`INSERT INTO daily_customers (customer_name,search_id,user_id) VALUES ($1,$2,$3)
            ON CONFLICT (search_id,user_id) DO NOTHING`, [name,search,id]);
        const r = await c.query(`INSERT INTO daily_sheets (search_id,debit_udhaar,credit_vasooli,description,total_balance,sheet_date,user_id,client_row_id)
            VALUES ($1,$2::numeric,0,$3,-($2::numeric),$4::date,$5,$6::uuid) RETURNING id`,[search,amount,description,d,id,crypto.randomUUID()]);
        links[key]=r.rows[0].id;
    }
    async function synchronize(c,id,d,inputs,snapshot,links) {
        links.receipts ||= {}; links.lubricant_sales ||= {};
        for (const n of NOZZLES) await c.query(`INSERT INTO meter_readings
            (nozzle_name,fuel_type,opening_reading,closing_reading,liters_sold,reading_date,user_id)
            VALUES ($1,$2,$3,$4,$5,$6::date,$7) ON CONFLICT (user_id,nozzle_name,reading_date)
            DO UPDATE SET opening_reading=EXCLUDED.opening_reading,closing_reading=EXCLUDED.closing_reading,liters_sold=EXCLUDED.liters_sold,fuel_type=EXCLUDED.fuel_type`,
            [n,n.startsWith('Diesel')?'Diesel':'Super',snapshot.opening.nozzles[n],inputs.nozzles[n],snapshot.nozzle_sales[n],d,id]);
        for (const f of FUELS) {
            const rec=inputs.fuel[f],rate=rec.qty ? rec.amount/rec.qty : 0;
            await receiptEntry(c,id,d,f,rec.amount,`${f} Stock Receipt (${rec.qty}L @ ${rate.toFixed(4)}) [Meter ${d}]`,links.receipts);
        }
        for (const [name,rec] of Object.entries(inputs.lubricants)) {
            await receiptEntry(c,id,d,'lub:'+name,rec.amount,`Mobil Oil Purchase | ${name} | Qty: ${rec.qty} | Rate: Rs. ${rec.rate.toFixed(2)} | Total: Rs. ${rec.amount.toFixed(2)} [Meter ${d}]`,links.receipts);
            let saleId=links.lubricant_sales[name];
            if (saleId) {
                const r=await c.query(`UPDATE lubricant_shift_sales SET liters_sold=$1 WHERE id=$2 AND user_id=$3 AND sale_date=$4::date RETURNING id`,[rec.sales,saleId,id,d]);
                if (!r.rows.length) { delete links.lubricant_sales[name]; saleId=null; }
            }
            if (!saleId && rec.sales>0) {
                const r=await c.query(`INSERT INTO lubricant_shift_sales (item_name,liters_sold,sale_date,user_id) VALUES ($1,$2,$3::date,$4) RETURNING id`,[name,rec.sales,d,id]);
                links.lubricant_sales[name]=r.rows[0].id;
            }
        }
    }
    async function saveDay(body) {
        const id=user(body.userId), d=date(body.date), requestId=uuid(body.request_id);
        if (!Number.isInteger(body.revision) || body.revision<1) fail('Reload the page to obtain its revision.',409);
        const hash=crypto.createHash('sha256').update(JSON.stringify({date:d,revision:body.revision,inputs:body.inputs})).digest('hex');
        return transaction(async c=>{
            await lock(c,id);
            const prior=(await c.query('SELECT payload_hash,response FROM meter_flow_requests WHERE user_id=$1 AND request_id=$2::uuid',[id,requestId])).rows[0];
            if (prior) { if(prior.payload_hash!==hash) fail('Request ID reused with different data.',409); return prior.response; }
            const config=await configuration(c,id);
            if(!config) fail('Enter actual opening stock first.',409);
            if(config.revision!==body.revision) fail('Another save changed this account. Refresh and review the saved day before editing.',409);
            const records=await days(c,id);
            const next=records.length?nextDate(records.at(-1).work_date):config.start_date;
            if(d<config.start_date || d>next) fail('Choose a saved day or the next working day: '+next);
            const inputs=M.normalizeInputs(body.inputs,Object.keys(config.baseline.lubricants));
            let record=records.find(r=>r.work_date===d);
            if(!record){ record={work_date:d,inputs,links:{},version:0};records.push(record);records.sort((a,b)=>a.work_date.localeCompare(b.work_date)); }
            else record.inputs=inputs;
            // Recalculate the chain before writing anything. An invalid later day rejects the entire edit.
            let opening=config.baseline;
            const receipts={Diesel:0,Super:0};
            for(const r of records){
                r.snapshot=M.calculate(opening,r.inputs,r.work_date);
                opening=r.snapshot.closing;
                for(const f of FUELS) receipts[f]=M.round(receipts[f]+r.inputs.fuel[f].qty);
            }
            for(const r of records){
                if(r.work_date<d) continue;
                if(r.work_date===d) await synchronize(c,id,r.work_date,r.inputs,r.snapshot,r.links);
                else {
                    // Only nozzle openings/sales change downstream; purchase ledger rows remain untouched.
                    for(const n of NOZZLES) await c.query(`UPDATE meter_readings SET opening_reading=$1,liters_sold=$2
                        WHERE user_id=$3 AND nozzle_name=$4 AND reading_date=$5::date`,[r.snapshot.opening.nozzles[n],r.snapshot.nozzle_sales[n],id,n,r.work_date]);
                }
                await c.query(`INSERT INTO meter_flow_days (user_id,work_date,inputs,snapshot,links,version)
                    VALUES ($1,$2::date,$3::jsonb,$4::jsonb,$5::jsonb,1) ON CONFLICT (user_id,work_date)
                    DO UPDATE SET inputs=EXCLUDED.inputs,snapshot=EXCLUDED.snapshot,links=EXCLUDED.links,
                    version=meter_flow_days.version+1,updated_at=now()`,[id,r.work_date,JSON.stringify(r.inputs),JSON.stringify(r.snapshot),JSON.stringify(r.links)]);
            }
            // A correction may affect later nozzle openings or later receipt-based costs.
            for (const closed of records) {
                if (closed.work_date >= d && nextDate(closed.work_date).endsWith('-01')) {
                    await postClosedMonth(c, id, closed.work_date);
                }
            }
            await publishStocks(c,id,opening,receipts,config.baseline);
            await c.query('UPDATE meter_flow_setup SET revision=revision+1 WHERE user_id=$1',[id]);
            const response={ saved_date:d, default_date:nextDate(records.at(-1).work_date), revision:config.revision+1 };
            await c.query(`INSERT INTO meter_flow_requests (user_id,request_id,payload_hash,response)
                VALUES ($1,$2::uuid,$3,$4::jsonb)`,[id,requestId,hash,JSON.stringify(response)]);
            return response;
        });
    }
    return { getDay, initialize, saveDay };
}
module.exports = { createService };
