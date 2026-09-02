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

// Expenses Search IDs List
const EXPENSE_SEARCH_IDS = ['sp', 'dl', 'mi', 'i', 'bb', 'pm', 'rg', 's', 'l'];

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

        const cleanSearchId = String(search_id).trim().toLowerCase();
        const cleanName = String(customer_name).trim();

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

// 3. Single Line Insert / Upsert (Atomic Transaction)
exports.saveSingleEntry = async (req, res) => {
    let client;
    try {
        const { id, search_id, customer_name, description, debit_udhaar, credit_vasooli, sheet_date, userId } = req.body;

        if (!sheet_date || !userId || !search_id) {
            return res.status(400).json({ status: "Error", message: "Date, User ID, and Search ID required." });
        }

        const cleanSearchId = String(search_id).trim().toLowerCase();
        const cleanDesc = description ? String(description).trim() : '';
        const debitVal = Math.max(0, parseFloat(debit_udhaar) || 0);
        const creditVal = Math.max(0, parseFloat(credit_vasooli) || 0);
        const total_balance = creditVal - debitVal;
        const formattedDate = formatDate(sheet_date);

        client = await db.pool ? await db.pool.connect() : await db.connect();
        await client.query('BEGIN');

        // Customer Sync in Master List
        if (customer_name && String(customer_name).trim() !== '') {
            const custQuery = `
                INSERT INTO daily_customers (customer_name, search_id, user_id) 
                VALUES ($1, $2, $3)
                ON CONFLICT (search_id, user_id) 
                DO UPDATE SET customer_name = EXCLUDED.customer_name
            `;
            await client.query(custQuery, [String(customer_name).trim(), cleanSearchId, userId]);
        }

        let resultId;
        // UPDATE Existing Entry
        if (id && parseInt(id, 10) > 0) {
            const updateQuery = `
                UPDATE daily_sheets 
                SET search_id = $1, debit_udhaar = $2, credit_vasooli = $3, description = $4, total_balance = $5 
                WHERE id = $6 AND user_id = $7
            `;
            await client.query(updateQuery, [cleanSearchId, debitVal, creditVal, cleanDesc, total_balance, parseInt(id, 10), userId]);
            resultId = parseInt(id, 10);
        } else {
            // INSERT New Entry
            const insertQuery = `
                INSERT INTO daily_sheets 
                (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                RETURNING id
            `;
            const insertRes = await client.query(insertQuery, [
                cleanSearchId, debitVal, creditVal, cleanDesc, total_balance, formattedDate, userId
            ]);
            resultId = insertRes.rows[0].id;
        }

        await client.query('COMMIT');
        return res.json({ status: "Success", message: "Entry saved successfully", id: resultId });

    } catch (error) {
        if (client) await client.query('ROLLBACK');
        console.error("Save Single Entry Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    } finally {
        if (client) client.release();
    }
};

// 4. Single Line Direct Update Route
exports.updateSingleEntry = async (req, res) => {
    let client;
    try {
        const entryId = req.params.id;
        const { search_id, customer_name, description, debit_udhaar, credit_vasooli, userId } = req.body;

        if (!entryId || !userId) {
            return res.status(400).json({ status: "Error", message: "Entry ID and User ID required." });
        }

        const cleanSearchId = String(search_id).trim().toLowerCase();
        const cleanDesc = description ? String(description).trim() : '';
        const debitVal = Math.max(0, parseFloat(debit_udhaar) || 0);
        const creditVal = Math.max(0, parseFloat(credit_vasooli) || 0);
        const total_balance = creditVal - debitVal;

        client = await db.pool ? await db.pool.connect() : await db.connect();
        await client.query('BEGIN');

        if (customer_name && String(customer_name).trim() !== '') {
            const custQuery = `
                INSERT INTO daily_customers (customer_name, search_id, user_id) 
                VALUES ($1, $2, $3)
                ON CONFLICT (search_id, user_id) 
                DO UPDATE SET customer_name = EXCLUDED.customer_name
            `;
            await client.query(custQuery, [String(customer_name).trim(), cleanSearchId, userId]);
        }

        const updateQuery = `
            UPDATE daily_sheets 
            SET search_id = $1, debit_udhaar = $2, credit_vasooli = $3, description = $4, total_balance = $5 
            WHERE id = $6 AND user_id = $7
        `;
        await client.query(updateQuery, [cleanSearchId, debitVal, creditVal, cleanDesc, total_balance, parseInt(entryId, 10), userId]);

        await client.query('COMMIT');
        return res.json({ status: "Success", message: "Entry updated successfully", id: parseInt(entryId, 10) });

    } catch (error) {
        if (client) await client.query('ROLLBACK');
        console.error("Update Single Entry Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    } finally {
        if (client) client.release();
    }
};

// 5. Bulk Batch Save Daily Sheet Entries
exports.saveDailySheetEntry = async (req, res) => {
    let client;
    try {
        client = await db.pool ? await db.pool.connect() : await db.connect();

        const rawEntries = Array.isArray(req.body.entries) ? req.body.entries : [req.body];
        const mainUserId = req.body.userId;
        const sheetDateParam = req.body.sheet_date;

        if (!rawEntries.length || !mainUserId || !sheetDateParam) {
            return res.status(400).json({ status: "Error", message: "Entries, User ID ya Sheet Date missing hai." });
        }

        await client.query('BEGIN');

        const formattedSheetDate = formatDate(sheetDateParam);
        const customerMap = new Map();
        const savedEntries = [];

        for (const item of rawEntries) {
            const { id, search_id, debit_udhaar, credit_vasooli, debit, credit, description, customer_name, userId } = item;
            const currentUserId = userId || mainUserId;

            if (!search_id) continue;

            const cleanSearchId = String(search_id).trim().toLowerCase();
            const cleanDesc = description ? String(description).trim() : '';
            const debitVal = Math.max(0, parseFloat(debit_udhaar !== undefined ? debit_udhaar : debit) || 0);
            const creditVal = Math.max(0, parseFloat(credit_vasooli !== undefined ? credit_vasooli : credit) || 0);
            const total_balance = creditVal - debitVal;

            if (customer_name && String(customer_name).trim() !== '') {
                customerMap.set(`${cleanSearchId}_${currentUserId}`, [String(customer_name).trim(), cleanSearchId, currentUserId]);
            }

            let entryDbId = id && parseInt(id, 10) > 0 ? parseInt(id, 10) : null;

            if (entryDbId) {
                const updateQuery = `
                    UPDATE daily_sheets 
                    SET search_id = $1, debit_udhaar = $2, credit_vasooli = $3, description = $4, total_balance = $5 
                    WHERE id = $6 AND user_id = $7
                `;
                await client.query(updateQuery, [cleanSearchId, debitVal, creditVal, cleanDesc, total_balance, entryDbId, currentUserId]);
            } else if (cleanSearchId !== '' && (debitVal > 0 || creditVal > 0 || cleanDesc !== '')) {
                const insertQuery = `
                    INSERT INTO daily_sheets 
                    (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id)
                    VALUES ($1, $2, $3, $4, $5, $6, $7)
                    RETURNING id
                `;
                const insertRes = await client.query(insertQuery, [
                    cleanSearchId, debitVal, creditVal, cleanDesc, total_balance, formattedSheetDate, currentUserId
                ]);
                
                if (insertRes.rows.length > 0) {
                    entryDbId = insertRes.rows[0].id;
                }
            }

            if (entryDbId) {
                savedEntries.push({
                    id: entryDbId,
                    search_id: cleanSearchId,
                    debit_udhaar: debitVal,
                    credit_vasooli: creditVal,
                    description: cleanDesc,
                    customer_name: customer_name || ''
                });
            }
        }

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
            message: `${formattedSheetDate} ka data kamyabi se save ho gaya!`,
            data: savedEntries
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

// 6. Fetch Daily Sheet By Date (Uses LEFT JOIN to prevent missing entries)
exports.getDailySheetByDate = async (req, res) => {
    try {
        const { date } = req.params; 
        const { userId } = req.query; 

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID parameter missing!" });
        }

        const formattedDate = formatDate(date);

        const query = `
            SELECT 
                ds.id AS db_id,
                COALESCE(dc.customer_name, ds.search_id) AS customer_name, 
                LOWER(TRIM(ds.search_id)) AS search_id, 
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

        const formattedEntries = rows.map((entry, index) => ({
            id: entry.db_id,            
            sr_no: index + 1,           
            sheet_sr_no: index + 1,     
            search_id: entry.search_id,
            customer_name: entry.customer_name,
            description: entry.description,
            debit_udhaar: parseFloat(entry.debit_udhaar) || 0,
            credit_vasooli: parseFloat(entry.credit_vasooli) || 0,
            total_balance: parseFloat(entry.total_balance) || 0,
            created_at: entry.created_at
        }));

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

        let today_debit = 0;
        let today_credit = 0;
        formattedEntries.forEach(entry => {
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
            entries: formattedEntries
        });
    } catch (error) {
        console.error("Fetch Sheet Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 7. Delete Single Entry
exports.deleteSheetEntry = async (req, res) => {
    try {
        const { id } = req.params;
        const { userId } = req.query;

        if (!userId || !id || parseInt(id, 10) === 0) {
            return res.json({ status: "Success", message: "Empty row ignored or parameters missing." });
        }

        await db.query('DELETE FROM daily_sheets WHERE id = $1 AND user_id = $2', [parseInt(id, 10), userId]);

        return res.json({ status: "Success", message: `Entry deleted successfully.` });
    } catch (error) {
        console.error("Delete Entry Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 8. Delete Customer Permanently (Atomic Transaction)
exports.deleteCustomerPermanently = async (req, res) => {
    let client;
    try {
        const { search_id } = req.params;
        const { userId } = req.query; 

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        const cleanSearchId = String(search_id).trim().toLowerCase();

        client = await db.pool ? await db.pool.connect() : await db.connect();
        await client.query('BEGIN');

        await client.query('DELETE FROM daily_sheets WHERE LOWER(search_id) = $1 AND user_id = $2', [cleanSearchId, userId]);
        await client.query('DELETE FROM daily_customers WHERE LOWER(search_id) = $1 AND user_id = $2', [cleanSearchId, userId]);

        await client.query('COMMIT');

        return res.json({ status: "Success", message: `Customer permanently deleted.` });
    } catch (error) {
        if (client) await client.query('ROLLBACK');
        console.error("Delete Customer Error:", error);
        return res.status(500).json({ status: "Error", db_error: error.message });
    } finally {
        if (client) client.release();
    }
};

// 9. Static Expenses Report
exports.getExpensesReport = async (req, res) => {
    try {
        let { userId, startDate, start_date, endDate, end_date } = req.query;
        let sDate = startDate || start_date;
        let eDate = endDate || end_date;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing hai!" });
        }

        const cleanUserId = String(userId).split(':')[0].trim();

        let dateCondition = `AND ds.sheet_date::date = CURRENT_DATE`;
        let queryParams = [cleanUserId, EXPENSE_SEARCH_IDS];

        if (sDate && eDate) {
            dateCondition = `AND ds.sheet_date::date BETWEEN $3::date AND $4::date`;
            queryParams = [cleanUserId, EXPENSE_SEARCH_IDS, formatDate(sDate), formatDate(eDate)];
        }

        const query = `
            SELECT 
                LOWER(TRIM(dc.search_id)) AS search_id,
                COALESCE(dc.customer_name, ds.search_id) AS account_name,
                COALESCE(SUM(ds.debit_udhaar), 0) AS total_debit,
                COUNT(ds.id) AS transaction_count
            FROM daily_sheets ds
            LEFT JOIN daily_customers dc 
                ON LOWER(TRIM(dc.search_id)) = LOWER(TRIM(ds.search_id))
                AND ds.user_id = dc.user_id
            WHERE ds.user_id = $1 
              AND LOWER(TRIM(ds.search_id)) = ANY($2::text[])
              ${dateCondition}
            GROUP BY LOWER(TRIM(ds.search_id)), dc.customer_name
            ORDER BY MIN(ds.id) ASC
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