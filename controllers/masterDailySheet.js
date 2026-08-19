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

// 1. Fetch Daily Sheet By Date (Fixed: Fetch Individual Rows, No Loss/Grouping)
exports.getDailySheetByDate = async (req, res) => {
    try {
        const { date } = req.params; 
        const { userId } = req.query; 

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID parameter missing hai!" });
        }

        const formattedDate = formatDate(date);

        // Direct fetch from daily_sheets with LEFT JOIN on daily_customers to fetch latest customer name
        const query = `
            SELECT 
                ds.id,
                LOWER(TRIM(ds.search_id)) AS search_id, 
                COALESCE(dc.customer_name, ds.search_id) AS customer_name,
                COALESCE(ds.description, '') AS description,
                COALESCE(ds.debit_udhaar, 0) AS debit_udhaar, 
                COALESCE(ds.credit_vasooli, 0) AS credit_vasooli, 
                COALESCE(ds.total_balance, 0) AS total_balance,
                ds.created_at
            FROM daily_sheets ds
            LEFT JOIN daily_customers dc 
                ON LOWER(TRIM(dc.search_id)) = LOWER(TRIM(ds.search_id)) 
                AND dc.user_id = ds.user_id
            WHERE ds.user_id = $1
              AND ds.sheet_date::date = $2::date
            ORDER BY ds.id ASC
        `;
        
        const { rows } = await db.query(query, [userId, formattedDate]);

        // Opening balance calculation (Before requested date)
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

        const formattedEntries = rows.map((entry, index) => {
            const deb = parseFloat(entry.debit_udhaar) || 0;
            const cred = parseFloat(entry.credit_vasooli) || 0;
            today_debit += deb;
            today_credit += cred;

            return {
                sr_no: index + 1,
                id: entry.id,
                search_id: entry.search_id,
                customer_name: entry.customer_name,
                description: entry.description,
                debit_udhaar: deb,
                credit_vasooli: cred,
                total_balance: parseFloat(entry.total_balance) || (cred - deb)
            };
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
            entries: formattedFormattedEntries || formattedEntries
        });

    } catch (error) {
        console.error("Fetch PostgreSQL Sheet Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 2. Add or Upsert Customer
exports.addCustomer = async (req, res) => {
    try {
        const { customer_name, search_id, userId } = req.body;

        if (!customer_name || !search_id || !userId) {
            return res.status(400).json({ status: "Error", message: "Customer Name, Search ID aur User ID required hain!" });
        }

        const cleanSearchId = search_id.trim().toLowerCase();
        const cleanName = customer_name.trim();

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