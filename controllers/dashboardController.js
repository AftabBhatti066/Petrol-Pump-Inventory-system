const db = require('../config/db');

exports.getDashboardData = async (req, res) => {
    try {
        const selectedDate = req.query.date || new Date().toISOString().split('T')[0];
        const userId = req.query.userId; 

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID parameters mein zaroori hai!" });
        }

        // 1. Tank Fuel Stocks (Filtered by user_id)
        const tankRes = await db.query(
            `SELECT fuel_type, current_stock FROM fuel_stocks WHERE user_id = $1`, 
            [userId]
        );
        const tankStocks = tankRes.rows || [];

        // 2. Today's Nozzle Meter Readings (Filtered by user_id)
        const meterRes = await db.query(
            `SELECT 
                fuel_type, 
                COALESCE(SUM(liters_sold), 0) AS total_liters_sold 
             FROM meter_readings 
             WHERE reading_date::date = $1::date AND user_id = $2
             GROUP BY fuel_type`, 
            [selectedDate, userId]
        );
        const meterStats = meterRes.rows || [];

        // 3. Daily Sheet Financial Summary (Filtered by user_id)
        const dailySheetRes = await db.query(
            `SELECT 
                COALESCE(SUM(debit_udhaar), 0) AS total_today_udhaar,
                COALESCE(SUM(credit_vasooli), 0) AS total_today_vasooli
             FROM daily_sheets
             WHERE sheet_date::date = $1::date AND user_id = $2`, 
            [selectedDate, userId]
        );
        const dailySheetStats = dailySheetRes.rows || [{ total_today_udhaar: 0, total_today_vasooli: 0 }];

        // 4. Vehicle Credit Ledger Summary (Filtered by user_id)
        const creditLedgerRes = await db.query(
            `SELECT 
                COALESCE(SUM(total_amount), 0) AS total_credit_sales_pkr,
                COALESCE(SUM(litres), 0) AS total_credit_litres
             FROM credit_ledgers
             WHERE entry_date::date = $1::date AND user_id = $2`, 
            [selectedDate, userId]
        );
        const creditLedgerStats = creditLedgerRes.rows || [{ total_credit_sales_pkr: 0, total_credit_litres: 0 }];

        // 5. Low Lubricant Stock Warning (Filtered by user_id)
        const lowLubeRes = await db.query(
            `SELECT item_name, current_stock 
             FROM lubricant_stocks 
             WHERE current_stock <= 5 AND user_id = $1 
             ORDER BY current_stock ASC`, 
            [userId]
        );
        const lowLubricants = lowLubeRes.rows || [];

        // 6. Registered Customers Count (Filtered by user_id)
        const customerRes = await db.query(
            `SELECT COUNT(*) AS total FROM daily_customers WHERE user_id = $1`, 
            [userId]
        );
        const customerCount = customerRes.rows || [{ total: 0 }];

        // Format Matrix Table Data
        const meterMap = {};
        meterStats.forEach(row => {
            meterMap[row.fuel_type] = parseFloat(row.total_liters_sold) || 0;
        });

        res.json({
            status: "Success",
            date: selectedDate,
            stocks: tankStocks,
            financials: {
                today_udhaar: parseFloat(dailySheetStats[0].total_today_udhaar || 0),
                today_vasooli: parseFloat(dailySheetStats[0].total_today_vasooli || 0),
                today_credit_ledger_pkr: parseFloat(creditLedgerStats[0].total_credit_sales_pkr || 0),
                total_customers: parseInt(customerCount[0].total || 0, 10)
            },
            dispensed_fuel: {
                diesel: meterMap['Diesel'] || meterMap['HSD'] || 0,
                petrol: meterMap['Petrol'] || meterMap['Super'] || meterMap['PMG'] || 0
            },
            low_lubricants: lowLubricants
        });

    } catch (error) {
        console.error("Dashboard Analytics Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};