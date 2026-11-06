const { reportSql } = require('../services/monthProfit');
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
    const { userId } = req.query;
    if (!/^[1-9]\d*$/.test(String(userId || '')) || Number(userId) > 2147483647) {
        return res.status(400).json({ success: false, message: 'Valid userId required.' });
    }
    const today = new Intl.DateTimeFormat('en-CA', {
        timeZone: 'Asia/Karachi', year: 'numeric', month: '2-digit', day: '2-digit'
    }).format(new Date());
    let start = req.query.start_date ?? req.query.startDate;
    let end = req.query.end_date ?? req.query.endDate;
    if (start == null && end == null) {
        start = today.slice(0, 7) + '-01';
        end = today;
    }
    function validDate(value) {
        if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
        const date = new Date(value + 'T00:00:00Z');
        return Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value;
    }
    if (!validDate(start) || !validDate(end) || start > end) {
        return res.status(400).json({ success: false, message: 'Select a valid start and end date in order.' });
    }

    // One database snapshot for sales, purchase costs, pricing and expenses.
    try {
        const { rows } = await db.query(reportSql, [Number(userId), start, end, EXPENSE_SEARCH_IDS]);
        return res.json({ success: true, status: 'Success', ...rows[0] });
    } catch (error) {
        console.error('Dispenser profit report:', error.message);
        return res.status(500).json({ success: false, message: 'Profit report load nahi hui. Check the Node terminal.' });
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
exports.postMonthEndProfit = (req, res) => {
    return res.status(409).json({success:false, status:'Error',
        message:'Month-end profit is posted automatically by Meter Reading > Save & Close Day.'});
};
