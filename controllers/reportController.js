const db = require('../config/db');

// Target Static Search IDs for Expenses
const EXPENSE_SEARCH_IDS = ['mi', 'i', 'bb', 'pm', 'rg', 's', 'l'];

// 1. Get Customer Ledger Report
exports.getCustomerLedgerReport = async (req, res) => {
    try {
        const { search_id, startDate, endDate, userId } = req.query;
        let query = `SELECT * FROM daily_sheets WHERE 1=1`;
        const params = [];

        if (search_id) {
            params.push(search_id);
            query += ` AND LOWER(TRIM(search_id)) = LOWER(TRIM($${params.length}))`;
        }
        if (startDate && endDate) {
            params.push(startDate, endDate);
            query += ` AND sheet_date::date BETWEEN $${params.length - 1} AND $${params.length}`;
        }
        if (userId) {
            params.push(userId);
            query += ` AND user_id = $${params.length}`;
        }

        query += ` ORDER BY sheet_date ASC, id ASC`;
        const { rows } = await db.query(query, params);

        return res.status(200).json({ success: true, data: rows });
    } catch (error) {
        return res.status(500).json({ success: false, error: error.message });
    }
};

// 2. Get Trial Balance Report
exports.getTrialBalance = async (req, res) => {
    try {
        const { userId, startDate, endDate } = req.query;
        let query = `
            SELECT 
                search_id,
                SUM(debit_udhaar) AS total_debit,
                SUM(credit_vasooli) AS total_credit,
                (SUM(debit_udhaar) - SUM(credit_vasooli)) AS net_balance
            FROM daily_sheets
            WHERE 1=1
        `;
        const params = [];

        if (startDate && endDate) {
            params.push(startDate, endDate);
            query += ` AND sheet_date::date BETWEEN $${params.length - 1} AND $${params.length}`;
        }
        if (userId) {
            params.push(userId);
            query += ` AND user_id = $${params.length}`;
        }

        query += ` GROUP BY search_id ORDER BY search_id ASC`;
        const { rows } = await db.query(query, params);

        return res.status(200).json({ success: true, data: rows });
    } catch (error) {
        return res.status(500).json({ success: false, error: error.message });
    }
};

// 3. Get Dispenser Profit Report (FIXED: Uses req.query properly for dates)
exports.getDispenserProfitReport = async (req, res) => {
    try {
        const { start_date, end_date, startDate, endDate, userId } = req.query;

        const now = new Date();
        const firstDayOfCurrentMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
        const todayStr = now.toISOString().split('T')[0];

        const sDate = start_date || startDate || firstDayOfCurrentMonth;
        const eDate = end_date || endDate || todayStr;

        let detailsQuery = `
            SELECT 
                combined.id,
                combined.reading_date,
                combined.nozzle_name,
                combined.fuel_type,
                combined.liters_sold,
                COALESCE(fr.purchase_price, 0) AS cost_rate,
                COALESCE(fr.rate_per_litre, 0) AS selling_rate,
                (combined.liters_sold * COALESCE(fr.purchase_price, 0)) AS total_cost_pkr,
                (combined.liters_sold * COALESCE(fr.rate_per_litre, 0)) AS total_revenue_pkr,
                ((combined.liters_sold * COALESCE(fr.rate_per_litre, 0)) - (combined.liters_sold * COALESCE(fr.purchase_price, 0))) AS gross_profit_pkr
            FROM (
                -- Meter Readings (Super & Diesel) - Uses reading_date entered by user
                SELECT 
                    mr.id,
                    mr.reading_date::date AS reading_date,
                    COALESCE(mr.nozzle_name, 'Dispenser') AS nozzle_name,
                    COALESCE(mr.fuel_type, 'Fuel') AS fuel_type,
                    COALESCE(mr.liters_sold, 0) AS liters_sold,
                    mr.user_id
                FROM meter_readings mr
                WHERE COALESCE(mr.liters_sold, 0) > 0

                UNION ALL

                -- Lubricant Shift Sales
                SELECT 
                    lss.id,
                    lss.sale_date AS reading_date,
                    'Mobiloil Counter' AS nozzle_name,
                    COALESCE(lss.item_name, 'Mobiloil') AS fuel_type,
                    COALESCE(lss.liters_sold, 0) AS liters_sold,
                    lss.user_id
                FROM lubricant_shift_sales lss
                WHERE COALESCE(lss.liters_sold, 0) > 0
            ) combined
            LEFT JOIN LATERAL (
                SELECT rate_per_litre, purchase_price 
                FROM fuel_rates fr_sub
                WHERE LOWER(TRIM(fr_sub.product_name)) = LOWER(TRIM(combined.fuel_type))
                   OR LOWER(TRIM(fr_sub.product_type)) = LOWER(TRIM(combined.fuel_type))
                   OR LOWER(TRIM(fr_sub.specific_category)) = LOWER(TRIM(combined.fuel_type))
                   OR LOWER(TRIM(combined.fuel_type)) LIKE '%' || LOWER(TRIM(fr_sub.product_name)) || '%'
                   OR LOWER(TRIM(fr_sub.product_name)) LIKE '%' || LOWER(TRIM(combined.fuel_type)) || '%'
                ORDER BY fr_sub.id DESC 
                LIMIT 1
            ) fr ON true
            WHERE combined.reading_date BETWEEN $1 AND $2
        `;
        
        const detailsParams = [sDate, eDate];

        if (userId) {
            detailsParams.push(userId);
            detailsQuery += ` AND (combined.user_id = $${detailsParams.length} OR combined.user_id IS NULL)`;
        }

        detailsQuery += ` ORDER BY combined.reading_date ASC, combined.id ASC`;

        const { rows: details } = await db.query(detailsQuery, detailsParams);

        let expenseQuery = `
            SELECT COALESCE(SUM(debit_udhaar), 0) AS "totalExpenses"
            FROM daily_sheets
            WHERE LOWER(TRIM(search_id)) = ANY($1::text[])
              AND sheet_date::date BETWEEN $2 AND $3
        `;
        const expenseParams = [EXPENSE_SEARCH_IDS, sDate, eDate];

        if (userId) {
            expenseParams.push(userId);
            expenseQuery += ` AND user_id = $${expenseParams.length}`;
        }

        const { rows: expenseRes } = await db.query(expenseQuery, expenseParams);
        const totalExpenses = parseFloat(expenseRes[0]?.totalExpenses) || 0;

        let totalLiters = 0;
        let totalRevenue = 0;
        let totalCost = 0;

        details.forEach(row => {
            totalLiters += parseFloat(row.liters_sold) || 0;
            totalRevenue += parseFloat(row.total_revenue_pkr) || 0;
            totalCost += parseFloat(row.total_cost_pkr) || 0;
        });

        const grossProfit = totalRevenue - totalCost;
        const netProfit = grossProfit - totalExpenses;

        return res.status(200).json({
            success: true,
            status: "Success",
            summary: {
                total_liters_sold: totalLiters,
                total_revenue_pkr: totalRevenue,
                total_cost_pkr: totalCost,
                gross_profit_pkr: grossProfit,
                total_expenses_pkr: totalExpenses,
                total_profit_pkr: netProfit
            },
            data: details
        });
    } catch (error) {
        console.error('Error fetching Dispenser Profit:', error);
        return res.status(500).json({
            success: false,
            status: "Error",
            message: 'Dispenser Profit Report calculate nahi ho saki.',
            error: error.message
        });
    }
};

// 4. Get Daily Summary Report (FIXED: Uses req.query properly)
exports.getDailySummary = async (req, res) => {
    try {
        const { date, userId } = req.query;
        const targetDate = date || new Date().toISOString().split('T')[0];
        
        let query = `SELECT * FROM daily_sheets WHERE sheet_date::date = $1`;
        const params = [targetDate];

        if (userId) {
            params.push(userId);
            query += ` AND user_id = $2`;
        }

        const { rows } = await db.query(query, params);
        return res.status(200).json({ success: true, date: targetDate, data: rows });
    } catch (error) {
        return res.status(500).json({ success: false, error: error.message });
    }
};

// 5. Post Month-End Profit
exports.postMonthEndProfit = async (req, res) => {
    try {
        const { startDate, start_date, endDate, end_date, userId } = req.body;
        const sDate = startDate || start_date;
        const eDate = endDate || end_date;

        if (!sDate || !eDate || !userId) {
            return res.status(400).json({
                success: false,
                status: "Error",
                message: "startDate, endDate aur userId zaroori hain."
            });
        }

        let combinedProfitQuery = `
            SELECT 
                combined.fuel_type,
                SUM(
                    (combined.liters_sold * COALESCE(fr.rate_per_litre, 0)) - 
                    (combined.liters_sold * COALESCE(fr.purchase_price, 0))
                ) AS item_profit
            FROM (
                -- Fuel Readings
                SELECT 
                    TRIM(mr.fuel_type) AS fuel_type,
                    COALESCE(mr.liters_sold, 0) AS liters_sold,
                    mr.user_id,
                    mr.reading_date::date AS transaction_date
                FROM meter_readings mr
                WHERE COALESCE(mr.liters_sold, 0) > 0

                UNION ALL

                -- Lubricant Shift Sales
                SELECT 
                    TRIM(lss.item_name) AS fuel_type,
                    COALESCE(lss.liters_sold, 0) AS liters_sold,
                    lss.user_id,
                    lss.sale_date AS transaction_date
                FROM lubricant_shift_sales lss
                WHERE COALESCE(lss.liters_sold, 0) > 0
            ) combined
            LEFT JOIN LATERAL (
                SELECT rate_per_litre, purchase_price 
                FROM fuel_rates fr_sub
                WHERE LOWER(TRIM(fr_sub.product_name)) = LOWER(TRIM(combined.fuel_type))
                   OR LOWER(TRIM(fr_sub.product_type)) = LOWER(TRIM(combined.fuel_type))
                   OR LOWER(TRIM(fr_sub.specific_category)) = LOWER(TRIM(combined.fuel_type))
                   OR LOWER(TRIM(combined.fuel_type)) LIKE '%' || LOWER(TRIM(fr_sub.product_name)) || '%'
                   OR LOWER(TRIM(fr_sub.product_name)) LIKE '%' || LOWER(TRIM(combined.fuel_type)) || '%'
                ORDER BY fr_sub.id DESC 
                LIMIT 1
            ) fr ON true
            WHERE combined.transaction_date BETWEEN $1 AND $2
              AND (combined.user_id = $3 OR combined.user_id IS NULL)
            GROUP BY combined.fuel_type
        `;

        const { rows: profits } = await db.query(combinedProfitQuery, [sDate, eDate, userId]);

        if (profits.length === 0) {
            return res.status(400).json({
                success: false,
                status: "Error",
                message: "Is date range ke darmiyan koi sales ya profit nahi mili."
            });
        }

        const addedRecords = [];

        for (const row of profits) {
            const rawItemName = (row.fuel_type || '').toLowerCase();
            const profitAmount = parseFloat(row.item_profit) || 0;

            if (profitAmount <= 0) continue;

            let searchId = '';

            if (rawItemName.includes('diesel') || rawItemName.includes('hsd') || rawItemName.includes('dl')) {
                searchId = 'dl';
            } else if (rawItemName.includes('super') || rawItemName.includes('petrol') || rawItemName.includes('sp') || rawItemName.includes('pm')) {
                searchId = 'sp';
            } else {
                searchId = 'lub';
            }

            if (searchId) {
                const description = `Month-End Profit Return (${sDate} to ${eDate}) - ${row.fuel_type}`;

                await db.query(
                    `INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, sheet_date, user_id, total_balance) 
                     VALUES ($1, $2, 0.00, $3, $4, $5, $6)`,
                    [searchId, profitAmount, description, eDate, userId, -profitAmount]
                );

                addedRecords.push({
                    search_id: searchId,
                    debit_udhaar: profitAmount,
                    item: row.fuel_type,
                    sheet_date: eDate
                });
            }
        }

        return res.status(200).json({
            success: true,
            status: "Success",
            message: "Month-End profit (Fuel & Lubricants) successfully added to daily_sheets table.",
            details: addedRecords
        });

    } catch (error) {
        console.error('Error posting month-end profit to daily_sheets:', error);
        return res.status(500).json({
            success: false,
            status: "Error",
            message: "Month-End profit post karne mein masla aaya hai.",
            error: error.message
        });
    }
};