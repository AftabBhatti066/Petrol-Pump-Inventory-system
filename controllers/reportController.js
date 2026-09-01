const db = require('../config/db');

// Target Static Search IDs for Expenses
const EXPENSE_SEARCH_IDS = ['mi', 'i', 'bb', 'pm', 'rg', 's', 'l'];

// 1. Get Customer Ledger Report
exports.getCustomerLedgerReport = async (req, res) => {
    try {
        const { customerName, customer_name, startDate, start_date, endDate, end_date, userId } = req.query;
        const targetCustomer = customerName || customer_name;
        const sDate = startDate || start_date;
        const eDate = endDate || end_date;

        if (!targetCustomer) {
            return res.status(400).json({
                success: false,
                status: "Error",
                message: "Customer name zaroori hai."
            });
        }

        let query = `
            SELECT 
                id,
                created_at AS date,
                description,
                debit_pkr AS debit,
                credit_pkr AS credit
            FROM credit_ledgers
            WHERE customer_name = $1
        `;

        const queryParams = [targetCustomer];

        if (userId) {
            queryParams.push(userId);
            query += ` AND user_id = $${queryParams.length}`;
        }

        if (sDate && eDate) {
            queryParams.push(sDate, eDate);
            query += ` AND created_at::date BETWEEN $${queryParams.length - 1} AND $${queryParams.length}`;
        }

        query += ` ORDER BY created_at ASC, id ASC;`;

        const { rows } = await db.query(query, queryParams);

        let runningBalance = 0;
        const ledgerData = rows.map(row => {
            const debit = Number(row.debit || 0);
            const credit = Number(row.credit || 0);
            runningBalance += (debit - credit);

            return {
                ...row,
                debit,
                credit,
                balance: runningBalance
            };
        });

        return res.status(200).json({
            success: true,
            status: "Success",
            customer_name: targetCustomer,
            total_records: ledgerData.length,
            statement: ledgerData,
            data: ledgerData
        });

    } catch (error) {
        console.error('Error fetching Customer Ledger:', error);
        return res.status(500).json({
            success: false,
            status: "Error",
            message: 'Customer Ledger fetch karne mein masla aaya hai.',
            error: error.message
        });
    }
};

// 2. Get Trial Balance Report
exports.getTrialBalance = async (req, res) => {
    try {
        const { userId, startDate, start_date, endDate, end_date } = req.query;
        const sDate = startDate || start_date;
        const eDate = endDate || end_date;

        const hasDates = Boolean(sDate && eDate);
        const queryParams = [];

        let clWhere = '1=1';
        if (userId) { queryParams.push(userId); clWhere += ` AND user_id = $${queryParams.length}`; }
        if (hasDates) { 
            queryParams.push(sDate, eDate); 
            clWhere += ` AND created_at::date BETWEEN $${queryParams.length - 1} AND $${queryParams.length}`; 
        }

        let dcWhere = '1=1';
        if (userId) { queryParams.push(userId); dcWhere += ` AND user_id = $${queryParams.length}`; }
        if (hasDates) { 
            queryParams.push(sDate, eDate); 
            dcWhere += ` AND created_at::date BETWEEN $${queryParams.length - 1} AND $${queryParams.length}`; 
        }

        let dsWhere = '1=1';
        if (userId) { queryParams.push(userId); dsWhere += ` AND user_id = $${queryParams.length}`; }
        if (hasDates) { 
            queryParams.push(sDate, eDate); 
            dsWhere += ` AND sheet_date::date BETWEEN $${queryParams.length - 1} AND $${queryParams.length}`; 
        }

        let coaWhere = '1=1';
        if (userId) { queryParams.push(userId); coaWhere += ` AND user_id = $${queryParams.length}`; }

        const query = `
            SELECT 
                party_name,
                SUM(debit) AS total_debit,
                SUM(credit) AS total_credit
            FROM (
                SELECT 
                    customer_name AS party_name,
                    SUM(debit_pkr) AS debit,
                    SUM(credit_pkr) AS credit
                FROM credit_ledgers
                WHERE ${clWhere}
                GROUP BY customer_name

                UNION ALL

                SELECT 
                    customer_name AS party_name,
                    SUM(debit_pkr) AS debit,
                    SUM(credit_pkr) AS credit
                FROM daily_customers
                WHERE ${dcWhere}
                GROUP BY customer_name

                UNION ALL

                SELECT 
                    'Daily Cash Sales' AS party_name,
                    SUM(total_cash_received) AS debit,
                    0 AS credit
                FROM daily_sheets
                WHERE ${dsWhere}

                UNION ALL

                SELECT 
                    account_name AS party_name,
                    CASE WHEN account_type IN ('Expense', 'Asset', 'Cash', 'Bank') THEN amount ELSE 0 END AS debit,
                    CASE WHEN account_type IN ('Liability', 'Equity', 'Revenue') THEN amount ELSE 0 END AS credit
                FROM chart_of_accounts
                WHERE ${coaWhere}
            ) AS combined_balances
            GROUP BY party_name
            HAVING (SUM(debit) - SUM(credit)) != 0 OR SUM(debit) > 0 OR SUM(credit) > 0
            ORDER BY party_name ASC;
        `;

        const { rows } = await db.query(query, queryParams);

        return res.status(200).json({
            success: true,
            status: "Success",
            data: rows
        });
    } catch (error) {
        console.error('Error fetching Trial Balance:', error);
        return res.status(500).json({
            success: false,
            status: "Error",
            message: 'Trial Balance report load karne mein masla aaya hai.',
            error: error.message
        });
    }
};

// 3. Get Dispenser Profit Report (Corrected Lubricant Sales Query)
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
                -- Meter Readings (Super & Diesel)
                SELECT 
                    mr.id,
                    mr.reading_date,
                    COALESCE(mr.nozzle_name, 'Dispenser') AS nozzle_name,
                    COALESCE(mr.fuel_type, 'Fuel') AS fuel_type,
                    COALESCE(mr.liters_sold, 0) AS liters_sold,
                    mr.user_id
                FROM meter_readings mr
                WHERE COALESCE(mr.liters_sold, 0) > 0

                UNION ALL

                -- Lubricant Stocks (Using shift_sales_deduct as sold units)
                SELECT 
                    ls.id,
                    CURRENT_DATE AS reading_date,
                    'Mobiloil Counter' AS nozzle_name,
                    COALESCE(ls.item_name, 'Mobiloil') AS fuel_type,
                    COALESCE(ls.shift_sales_deduct, 0) AS liters_sold,
                    ls.user_id
                FROM lubricant_stocks ls
                WHERE COALESCE(ls.shift_sales_deduct, 0) > 0
            ) combined
            LEFT JOIN (
                SELECT product_name, product_type, rate_per_litre, purchase_price
                FROM fuel_rates
                WHERE id IN (SELECT MAX(id) FROM fuel_rates GROUP BY product_name, product_type)
            ) fr ON LOWER(TRIM(combined.fuel_type)) = LOWER(TRIM(fr.product_name))
                 OR LOWER(TRIM(combined.fuel_type)) = LOWER(TRIM(fr.product_type))
                 OR LOWER(TRIM(combined.fuel_type)) LIKE '%' || LOWER(TRIM(fr.product_type)) || '%'
                 OR LOWER(TRIM(fr.product_name)) LIKE '%' || LOWER(TRIM(combined.fuel_type)) || '%'
            WHERE combined.reading_date::date BETWEEN $1 AND $2
        `;
        
        const detailsParams = [sDate, eDate];

        if (userId) {
            detailsParams.push(userId);
            detailsQuery += ` AND (combined.user_id = $${detailsParams.length} OR combined.user_id IS NULL)`;
        }

        detailsQuery += ` ORDER BY combined.reading_date DESC, combined.id DESC`;

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

// 5. Post Month-End Profit (Corrected Lubricant Sales Query)
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

                -- Lubricant / Mobiloil Stocks (Using shift_sales_deduct)
                SELECT 
                    TRIM(ls.item_name) AS fuel_type,
                    COALESCE(ls.shift_sales_deduct, 0) AS liters_sold,
                    ls.user_id,
                    CURRENT_DATE AS transaction_date
                FROM lubricant_stocks ls
                WHERE COALESCE(ls.shift_sales_deduct, 0) > 0
            ) combined
            LEFT JOIN (
                SELECT product_name, product_type, rate_per_litre, purchase_price
                FROM fuel_rates
                WHERE id IN (SELECT MAX(id) FROM fuel_rates GROUP BY product_name, product_type)
            ) fr ON LOWER(TRIM(combined.fuel_type)) = LOWER(TRIM(fr.product_name))
                 OR LOWER(TRIM(combined.fuel_type)) = LOWER(TRIM(fr.product_type))
                 OR LOWER(TRIM(combined.fuel_type)) LIKE '%' || LOWER(TRIM(fr.product_type)) || '%'
                 OR LOWER(TRIM(fr.product_name)) LIKE '%' || LOWER(TRIM(combined.fuel_type)) || '%'
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
                searchId = 'mb';
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

// 4. Get Daily Summary Report
exports.getDailySummary = async (req, res) => {
    try {
        const { date, userId } = req.query;
        const targetDate = date || new Date().toISOString().split('T')[0];

        let salesQuery = `SELECT SUM(credit_vasooli) as total_sales FROM daily_sheets WHERE sheet_date::date = $1`;
        const salesParams = [targetDate];

        if (userId) {
            salesParams.push(userId);
            salesQuery += ` AND user_id = $${salesParams.length}`;
        }

        let expensesQuery = `SELECT SUM(debit_udhaar) as total_expenses FROM daily_sheets WHERE LOWER(TRIM(search_id)) = ANY($1::text[]) AND sheet_date::date = $2`;
        const expensesParams = [EXPENSE_SEARCH_IDS, targetDate];

        if (userId) {
            expensesParams.push(userId);
            expensesQuery += ` AND user_id = $${expensesParams.length}`;
        }

        const { rows: sales } = await db.query(salesQuery, salesParams);
        const { rows: expenses } = await db.query(expensesQuery, expensesParams);

        const totalSales = parseFloat(sales[0]?.total_sales) || 0;
        const totalExpenses = parseFloat(expenses[0]?.total_expenses) || 0;

        return res.status(200).json({
            success: true,
            status: "Success",
            data: {
                date: targetDate,
                total_sales: totalSales,
                total_expenses: totalExpenses,
                net_cash: totalSales - totalExpenses
            }
        });
    } catch (error) {
        console.error('Error fetching Daily Summary:', error);
        return res.status(500).json({
            success: false,
            status: "Error",
            message: 'Daily Summary report fetch nahi ho saki.',
            error: error.message
        });
    }
};

// 5. Post Month-End Profit directly into daily_sheets (Fuel + Lubricants)
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

                -- Lubricant / Mobiloil Stocks
                SELECT 
                    TRIM(ls.item_name) AS fuel_type,
                    COALESCE(ls.current_stock, 0) AS liters_sold,
                    ls.user_id,
                    CURRENT_DATE AS transaction_date
                FROM lubricant_stocks ls
                WHERE COALESCE(ls.current_stock, 0) > 0
            ) combined
            LEFT JOIN (
                SELECT product_name, product_type, rate_per_litre, purchase_price
                FROM fuel_rates
                WHERE id IN (SELECT MAX(id) FROM fuel_rates GROUP BY product_name, product_type)
            ) fr ON LOWER(TRIM(combined.fuel_type)) = LOWER(TRIM(fr.product_name))
                 OR LOWER(TRIM(combined.fuel_type)) = LOWER(TRIM(fr.product_type))
                 OR LOWER(TRIM(combined.fuel_type)) LIKE '%' || LOWER(TRIM(fr.product_type)) || '%'
                 OR LOWER(TRIM(fr.product_name)) LIKE '%' || LOWER(TRIM(combined.fuel_type)) || '%'
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

            // Mapping Search IDs (dl = Diesel, sp = Super, mb = Mobiloil/Lubricants)
            if (rawItemName.includes('diesel') || rawItemName.includes('hsd') || rawItemName.includes('dl')) {
                searchId = 'dl';
            } else if (rawItemName.includes('super') || rawItemName.includes('petrol') || rawItemName.includes('sp') || rawItemName.includes('pm')) {
                searchId = 'sp';
            } else {
                searchId = 'mb'; // Lubricants / Mobiloil
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