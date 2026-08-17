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

        // Dynamic Clauses with Positional Parameters ($1, $2, etc.)
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

// 3. Get Dispenser Profit Report
exports.getDispenserProfitReport = async (req, res) => {
    try {
        const { start_date, end_date, startDate, endDate, userId } = req.query;
        const sDate = start_date || startDate;
        const eDate = end_date || endDate;

        let detailsQuery = `
            SELECT 
                mr.id,
                mr.reading_date,
                COALESCE(mr.nozzle_name, '-') AS nozzle_name,
                COALESCE(mr.fuel_type, '-') AS fuel_type,
                COALESCE(mr.liters_sold, 0) AS liters_sold,
                COALESCE(fr.purchase_price, 0) AS cost_rate,
                COALESCE(fr.rate_per_litre, 0) AS selling_rate,
                (COALESCE(mr.liters_sold, 0) * COALESCE(fr.purchase_price, 0)) AS total_cost_pkr,
                (COALESCE(mr.liters_sold, 0) * COALESCE(fr.rate_per_litre, 0)) AS total_revenue_pkr,
                ((COALESCE(mr.liters_sold, 0) * COALESCE(fr.rate_per_litre, 0)) - (COALESCE(mr.liters_sold, 0) * COALESCE(fr.purchase_price, 0))) AS gross_profit_pkr
            FROM meter_readings mr
            LEFT JOIN (
                SELECT product_type, rate_per_litre, purchase_price
                FROM fuel_rates
                WHERE id IN (SELECT MAX(id) FROM fuel_rates GROUP BY product_type)
            ) fr ON LOWER(TRIM(mr.fuel_type)) LIKE '%' || LOWER(TRIM(fr.product_type)) || '%'
                 OR LOWER(TRIM(fr.product_type)) LIKE '%' || LOWER(TRIM(mr.fuel_type)) || '%'
            WHERE 1=1
        `;
        const detailsParams = [];

        if (sDate && eDate) {
            detailsParams.push(sDate, eDate);
            detailsQuery += ` AND mr.reading_date::date BETWEEN $${detailsParams.length - 1} AND $${detailsParams.length}`;
        }
        if (userId) {
            detailsParams.push(userId);
            detailsQuery += ` AND (mr.user_id = $${detailsParams.length} OR mr.user_id IS NULL)`;
        }

        detailsQuery += ` ORDER BY mr.reading_date DESC, mr.id DESC`;

        const { rows: details } = await db.query(detailsQuery, detailsParams);

        let expenseQuery = `
            SELECT COALESCE(SUM(debit_udhaar), 0) AS "totalExpenses"
            FROM daily_sheets
            WHERE LOWER(TRIM(search_id)) = ANY($1::text[])
        `;
        const expenseParams = [EXPENSE_SEARCH_IDS];

        if (sDate && eDate) {
            expenseParams.push(sDate, eDate);
            expenseQuery += ` AND sheet_date::date BETWEEN $${expenseParams.length - 1} AND $${expenseParams.length}`;
        }
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

// 5. Post Month-End Profit to Diesel & Super Accounts
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

        let fuelProfitQuery = `
            SELECT 
                TRIM(mr.fuel_type) AS fuel_type,
                SUM(
                    (COALESCE(mr.liters_sold, 0) * COALESCE(fr.rate_per_litre, 0)) - 
                    (COALESCE(mr.liters_sold, 0) * COALESCE(fr.purchase_price, 0))
                ) AS fuel_profit
            FROM meter_readings mr
            LEFT JOIN (
                SELECT product_type, rate_per_litre, purchase_price
                FROM fuel_rates
                WHERE id IN (SELECT MAX(id) FROM fuel_rates GROUP BY product_type)
            ) fr ON LOWER(TRIM(mr.fuel_type)) LIKE '%' || LOWER(TRIM(fr.product_type)) || '%'
                 OR LOWER(TRIM(fr.product_type)) LIKE '%' || LOWER(TRIM(mr.fuel_type)) || '%'
            WHERE mr.reading_date::date BETWEEN $1 AND $2
              AND (mr.user_id = $3 OR mr.user_id IS NULL)
            GROUP BY mr.fuel_type
        `;

        const { rows: profits } = await db.query(fuelProfitQuery, [sDate, eDate, userId]);

        if (profits.length === 0) {
            return res.status(400).json({
                success: false,
                status: "Error",
                message: "Is date range ke darmiyan koi fuel sales ya profit nahi mili."
            });
        }

        const addedRecords = [];

        for (const row of profits) {
            const rawFuelName = (row.fuel_type || '').toLowerCase();
            const profitAmount = parseFloat(row.fuel_profit) || 0;

            if (profitAmount <= 0) continue;

            let searchId = '';
            let targetCustomerName = '';

            if (rawFuelName.includes('diesel')) {
                searchId = 'diesel';
                targetCustomerName = 'Diesel Khata';
            } else if (rawFuelName.includes('super') || rawFuelName.includes('petrol')) {
                searchId = 'super';
                targetCustomerName = 'Super Khata';
            }

            if (searchId) {
                const { rows: custRes } = await db.query(
                    'SELECT customer_name FROM daily_customers WHERE user_id = $1 AND search_id = $2 LIMIT 1',
                    [userId, searchId]
                );

                if (custRes.length > 0) {
                    targetCustomerName = custRes[0].customer_name;
                }

                const description = `Profit Return - ${targetCustomerName}`;

                await db.query(
                    `INSERT INTO credit_ledgers (user_id, customer_name, description, debit_pkr, credit_pkr, created_at) 
                     VALUES ($1, $2, $3, 0, $4, CURRENT_TIMESTAMP)`,
                    [userId, targetCustomerName, description, profitAmount]
                );

                addedRecords.push({
                    customer: targetCustomerName,
                    amount: profitAmount,
                    description: description
                });
            }
        }

        return res.status(200).json({
            success: true,
            status: "Success",
            message: "Month-End fuel profit successfully return/post kar di gayi hai.",
            details: addedRecords
        });

    } catch (error) {
        console.error('Error posting month-end profit:', error);
        return res.status(500).json({
            success: false,
            status: "Error",
            message: "Month-End profit post karne mein masla aaya hai.",
            error: error.message
        });
    }
};