const db = require('../config/db');

// Safe Date Formatting Helper (YYYY-MM-DD)
const formatDate = (dateInput) => {
    if (!dateInput) return '';
    if (typeof dateInput === 'string') {
        const match = dateInput.match(/\d{4}-\d{2}-\d{2}/);
        if (match) return match[0];
    }
    const d = new Date(dateInput);
    if (isNaN(d.getTime())) return '';
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
};

// 1. Fetch Daily Sheet By Date (PostgreSQL Compatible)
exports.getDailySheetByDate = async (req, res) => {
    try {
        const { date } = req.params; 
        const { userId } = req.query; 

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID parameter missing hai!" });
        }

        const formattedDate = formatDate(date);

        // PostgreSQL me GROUP_CONCAT ki jagah STRING_AGG use hota hai
        // Postgres $1, $2 parameterized placeholders expect karta hai
        const query = `
            SELECT 
                dc.customer_name, 
                LOWER(TRIM(dc.search_id)) AS search_id, 
                COALESCE(ds.id, 0) AS id,
                COALESCE(ds.description, '') AS description,
                COALESCE(ds.debit_udhaar, 0) AS debit_udhaar, 
                COALESCE(ds.credit_vasooli, 0) AS credit_vasooli, 
                COALESCE(ds.total_balance, 0) AS total_balance
            FROM daily_customers dc
            LEFT JOIN (
                SELECT 
                    search_id,
                    user_id,
                    MAX(id) AS id,
                    STRING_AGG(description, ' | ') AS description,
                    SUM(debit_udhaar) AS debit_udhaar,
                    SUM(credit_vasooli) AS credit_vasooli,
                    SUM(total_balance) AS total_balance
                FROM daily_sheets
                WHERE sheet_date::date = $1::date AND user_id = $2
                GROUP BY LOWER(TRIM(search_id)), user_id
            ) ds 
                ON LOWER(TRIM(dc.search_id)) = LOWER(TRIM(ds.search_id)) 
                AND dc.user_id = ds.user_id
            WHERE dc.user_id = $3
            ORDER BY dc.id ASC
        `;
        
        // pg driver result ko { rows } me return karta hai
        const { rows } = await db.query(query, [formattedDate, userId, userId]);

        // Opening balance calculation
        const openingQuery = `
            SELECT 
                COALESCE(SUM(debit_udhaar), 0) AS opening_debit,
                COALESCE(SUM(credit_vasooli), 0) AS opening_credit
            FROM daily_sheets 
            WHERE user_id = $1 
              AND sheet_date::date < $2::date
        `;
        
        const openingResult = await db.query(openingQuery, [userId, formattedDate]);
        const opening_debit = parseFloat(openingResult.rows[0]?.opening_debit) || 0;
        const opening_credit = parseFloat(openingResult.rows[0]?.opening_credit) || 0;
        const opening_balance = opening_credit - opening_debit;

        let today_debit = 0;
        let today_credit = 0;

        rows.forEach(entry => {
            today_debit += parseFloat(entry.debit_udhaar) || 0;
            today_credit += parseFloat(entry.credit_vasooli) || 0;
        });

        const overall_debit = opening_debit + today_debit;
        const overall_credit = opening_credit + today_credit;
        const closing_balance = opening_balance + (today_credit - today_debit);

        return res.json({
            status: "Success",
            sheet_date: formattedDate,
            opening_debit,
            opening_credit,
            total_debit: overall_debit,
            total_credit: overall_credit,
            opening_balance,
            closing_balance,
            entries: rows
        });

    } catch (error) {
        console.error("Fetch PostgreSQL Sheet Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 2. Add or Upsert Customer (PostgreSQL ON CONFLICT)
exports.addCustomer = async (req, res) => {
    try {
        const { customer_name, search_id, userId } = req.body;

        if (!customer_name || !search_id || !userId) {
            return res.status(400).json({ status: "Error", message: "Customer Name, Search ID aur User ID required hain!" });
        }

        const cleanSearchId = search_id.trim().toLowerCase();
        const cleanName = customer_name.trim();

        // PostgreSQL me ON DUPLICATE KEY UPDATE ki jagah ON CONFLICT use hota hai
        const query = `
            INSERT INTO daily_customers (customer_name, search_id, user_id) 
            VALUES ($1, $2, $3)
            ON CONFLICT (search_id, user_id) 
            DO UPDATE SET customer_name = EXCLUDED.customer_name
        `;
        await db.query(query, [cleanName, cleanSearchId, userId]);

        return res.json({
            status: "Success",
            message: `Customer ${cleanName} saved successfully!`
        });
    } catch (error) {
        console.error("Add Customer Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    }
};