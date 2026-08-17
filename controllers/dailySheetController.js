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

const EXPENSE_SEARCH_IDS = ['mi', 'i', 'bb', 'pm', 'rg', 's', 'l'];

// 1. Get All Master Customers for Logged-In User
exports.getMasterCustomers = async (req, res) => {
    try {
        const { userId } = req.query;
        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID parameter missing!" });
        }

        const query = `
            SELECT LOWER(TRIM(search_id)) AS search_id, customer_name 
            FROM daily_customers 
            WHERE user_id = $1
            ORDER BY id ASC
        `;
        const { rows } = await db.query(query, [userId]);

        return res.json({ status: "Success", data: rows });
    } catch (error) {
        console.error("Fetch Master Customers Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 2. Add or Update Customer (User Isolated)
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
// 3. Bulk Batch Save Daily Sheet Entries (Preventing Duplicates via ID check)
exports.saveDailySheetEntry = async (req, res) => {
    let client;
    try {
        if (typeof db.getClient === 'function') {
            client = await db.getClient();
        } else if (typeof db.connect === 'function') {
            client = await db.connect();
        } else if (db.pool && typeof db.pool.connect === 'function') {
            client = await db.pool.connect();
        } else {
            throw new Error("Database client connection method not found on 'db' module.");
        }

        await client.query('BEGIN');

        const rawEntries = Array.isArray(req.body.entries) ? req.body.entries : [req.body];
        const mainUserId = req.body.userId;
        const sheetDateParam = req.body.sheet_date;

        if (!rawEntries.length || !mainUserId || !sheetDateParam) {
            await client.query('ROLLBACK');
            return res.status(400).json({ status: "Error", message: "Entries, User ID ya Sheet Date missing hai." });
        }

        const formattedSheetDate = formatDate(sheetDateParam);
        const customerMap = new Map();

        for (const item of rawEntries) {
            const { id, search_id, debit_udhaar, credit_vasooli, debit, credit, description, customer_name, userId } = item;
            const currentUserId = userId || mainUserId;

            if (!search_id) continue;

            const cleanSearchId = String(search_id).trim().toLowerCase();
            const cleanDesc = description ? String(description).trim() : '';
            const debitVal = parseFloat(debit_udhaar !== undefined ? debit_udhaar : debit) || 0;
            const creditVal = parseFloat(credit_vasooli !== undefined ? credit_vasooli : credit) || 0;
            const total_balance = creditVal - debitVal;

            if (customer_name && String(customer_name).trim() !== '') {
                customerMap.set(`${cleanSearchId}_${currentUserId}`, [String(customer_name).trim(), cleanSearchId, currentUserId]);
            }

            // Agar entry ki ID mojood hai aur > 0 hai, toh UPDATE karein (Dubara Duplicate Insert na karein)
            if (id && parseInt(id, 10) > 0) {
                const updateQuery = `
                    UPDATE daily_sheets 
                    SET debit_udhaar = $1, credit_vasooli = $2, description = $3, total_balance = $4 
                    WHERE id = $5 AND user_id = $6
                `;
                await client.query(updateQuery, [debitVal, creditVal, cleanDesc, total_balance, id, currentUserId]);
            } 
            // Agar bilkul NAYI entry hai (no ID) aur amounts/description hain, tab hi INSERT karein
            else if (cleanSearchId !== '' && (debitVal > 0 || creditVal > 0 || cleanDesc !== '')) {
                const insertQuery = `
                    INSERT INTO daily_sheets 
                    (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id)
                    VALUES ($1, $2, $3, $4, $5, $6, $7)
                `;
                await client.query(insertQuery, [
                    cleanSearchId, debitVal, creditVal, cleanDesc, total_balance, formattedSheetDate, currentUserId
                ]);
            }
        }

        // Batch customer upsert
        if (customerMap.size > 0) {
            const customerValues = Array.from(customerMap.values());
            const custTuples = [];
            const custParams = [];
            let cIndex = 1;

            customerValues.forEach(([cName, sId, uId]) => {
                custTuples.push(`($${cIndex}, $${cIndex + 1}, $${cIndex + 2})`);
                custParams.push(cName, sId, uId);
                cIndex += 3;
            });

            const customerBatchQuery = `
                INSERT INTO daily_customers (customer_name, search_id, user_id) 
                VALUES ${custTuples.join(', ')}
                ON CONFLICT (search_id, user_id) 
                DO UPDATE SET customer_name = EXCLUDED.customer_name
            `;
            await client.query(customerBatchQuery, custParams);
        }

        await client.query('COMMIT');

        return res.json({
            status: "Success",
            message: `${formattedSheetDate} ka data kamyabi se save ho gaya!`
        });

    } catch (error) {
        if (client) await client.query('ROLLBACK');
        console.error("Save Sheet Entry Error Details:", error);
        return res.status(500).json({ 
            status: "Error", 
            message: error.message || "Data save karne mein error aaya hai",
            db_error: error.message 
        });
    } finally {
        if (client) client.release();
    }
};

// 4. Fetch Daily Sheet By Date (Option 2: Individual Rows)
exports.getDailySheetByDate = async (req, res) => {
    try {
        const { date } = req.params; 
        const { userId } = req.query; 

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID parameter missing!" });
        }

        const formattedDate = formatDate(date);

        // INNER JOIN se ab sirf wahi entries aayengi jo us din actually database me insert hui hain (Individual Transactions)
        const query = `
            SELECT 
                ds.id,
                dc.customer_name, 
                LOWER(TRIM(dc.search_id)) AS search_id, 
                COALESCE(ds.description, '') AS description,
                COALESCE(ds.debit_udhaar, 0) AS debit_udhaar, 
                COALESCE(ds.credit_vasooli, 0) AS credit_vasooli, 
                COALESCE(ds.total_balance, 0) AS total_balance,
                ds.created_at
            FROM daily_sheets ds
            INNER JOIN daily_customers dc 
                ON LOWER(TRIM(dc.search_id)) = LOWER(TRIM(ds.search_id)) 
                AND dc.user_id = ds.user_id
            WHERE ds.user_id = $1
              AND ds.sheet_date::date = $2::date
            ORDER BY ds.id ASC
        `;
        
        const { rows } = await db.query(query, [userId, formattedDate]);

        // Opening balance calculation
        const openingCumulativeQuery = `
            SELECT 
                COALESCE(SUM(debit_udhaar), 0) AS opening_debit,
                COALESCE(SUM(credit_vasooli), 0) AS opening_credit
            FROM daily_sheets 
            WHERE user_id = $1 
              AND sheet_date::date < $2::date
        `;
        
        const openingCumResult = await db.query(openingCumulativeQuery, [userId, formattedDate]);
        const openingRow = openingCumResult.rows[0] || {};
        
        const opening_debit = parseFloat(openingRow.opening_debit) || 0;
        const opening_credit = parseFloat(openingRow.opening_credit) || 0;
        const opening_balance = opening_credit - opening_debit;

        // Today's total calculation
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
        console.error("Fetch Sheet Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 5. Delete Single Entry
exports.deleteSheetEntry = async (req, res) => {
    try {
        const { id } = req.params;
        const { userId } = req.query;

        if (parseInt(id, 10) === 0) {
            return res.json({ status: "Success", message: "Empty row ignored." });
        }

        await db.query('DELETE FROM daily_sheets WHERE id = $1 AND user_id = $2', [id, userId]);

        return res.json({ status: "Success", message: `Entry deleted successfully.` });
    } catch (error) {
        console.error("Delete Entry Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 6. Delete Customer Permanently
exports.deleteCustomerPermanently = async (req, res) => {
    try {
        const { search_id } = req.params;
        const { userId } = req.query; 

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        const cleanSearchId = search_id.trim().toLowerCase();

        await db.query('DELETE FROM daily_sheets WHERE LOWER(search_id) = $1 AND user_id = $2', [cleanSearchId, userId]);
        await db.query('DELETE FROM daily_customers WHERE LOWER(search_id) = $1 AND user_id = $2', [cleanSearchId, userId]);

        return res.json({ status: "Success", message: `Customer permanently deleted.` });
    } catch (error) {
        console.error("Delete Customer Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 7. Static Expenses Report
exports.getExpensesReport = async (req, res) => {
    try {
        let { userId, startDate, start_date, endDate, end_date } = req.query;
        let sDate = startDate || start_date;
        let eDate = endDate || end_date;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing hai!" });
        }

        if (typeof userId === 'string') {
            userId = userId.split(':')[0].trim();
        }
        const cleanUserId = parseInt(userId, 10);

        let dateCondition = `AND ds.sheet_date::date = CURRENT_DATE`;
        let queryParams = [cleanUserId, EXPENSE_SEARCH_IDS];

        if (sDate && eDate) {
            dateCondition = `AND ds.sheet_date::date BETWEEN $3::date AND $4::date`;
            queryParams = [cleanUserId, EXPENSE_SEARCH_IDS, sDate, eDate];
        }

        const query = `
            SELECT 
                LOWER(TRIM(dc.search_id)) AS search_id,
                dc.customer_name AS account_name,
                COALESCE(SUM(ds.debit_udhaar), 0) AS total_debit,
                COUNT(ds.id) AS transaction_count
            FROM daily_sheets ds
            INNER JOIN daily_customers dc 
                ON LOWER(TRIM(dc.search_id)) = LOWER(TRIM(ds.search_id))
                AND ds.user_id = dc.user_id
            WHERE ds.user_id = $1 
              AND LOWER(TRIM(dc.search_id)) = ANY($2::text[])
              ${dateCondition}
            GROUP BY LOWER(TRIM(dc.search_id)), dc.customer_name, dc.id
            ORDER BY dc.id ASC
        `;

        const { rows } = await db.query(query, queryParams);

        let overallExpense = 0;
        const reportData = rows.map((row, index) => {
            const total = parseFloat(row.total_debit) || 0;
            overallExpense += total;

            return {
                sr_no: index + 1,
                search_id: row.search_id,
                account_name: row.account_name,
                total_transactions: parseInt(row.transaction_count, 10) || 0,
                total_amount: total
            };
        });

        return res.json({
            status: "Success",
            overall_expense: overallExpense,
            data: reportData
        });

    } catch (error) {
        console.error("Fetch Static Expenses Error:", error);
        return res.status(500).json({ 
            status: "Error", 
            message: "Expense report fetch karne mein masla aaya hai.",
            db_error: error.message 
        });
    }
};