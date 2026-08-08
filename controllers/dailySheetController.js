const db = require('../config/db');

// Safe Date Formatting Helper
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
            WHERE user_id = ?
            ORDER BY id ASC
        `;
        const [rows] = await db.query(query, [userId]);

        res.json({ status: "Success", data: rows });
    } catch (error) {
        console.error("Fetch Master Customers Error:", error);
        res.status(500).json({ status: "Error", db_error: error.message });
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
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE customer_name = VALUES(customer_name)
        `;
        await db.query(query, [cleanName, cleanSearchId, userId]);

        res.json({
            status: "Success",
            message: `Customer ${cleanName} saved successfully!`
        });
    } catch (error) {
        console.error("Add Customer Error:", error);
        res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 3. Bulk Batch Save Daily Sheet Entries (FIXED FOR PREVIOUS & CURRENT DATES)
exports.saveDailySheetEntry = async (req, res) => {
    const connection = await db.getConnection(); // Use Database Transaction
    try {
        await connection.beginTransaction();

        const rawEntries = req.body.entries ? req.body.entries : [req.body];
        const mainUserId = req.body.userId; 
        const sheetDateParam = req.body.sheet_date;

        if (!rawEntries || rawEntries.length === 0 || !mainUserId || !sheetDateParam) {
            await connection.rollback();
            connection.release();
            return res.status(400).json({ status: "Error", message: "Entries, User ID ya Sheet Date missing hai." });
        }

        const formattedSheetDate = formatDate(sheetDateParam);

        // Step 1: Us selected date ki pehle se mojood entries delete karo
        const deleteQuery = `
            DELETE FROM daily_sheets 
            WHERE user_id = ? AND DATE_FORMAT(sheet_date, '%Y-%m-%d') = ?
        `;
        await connection.query(deleteQuery, [mainUserId, formattedSheetDate]);

        // Step 2: Customer Master Upsert & Valid Entries Collect Karo
        const valuesToInsert = [];

        for (const item of rawEntries) {
            const { search_id, debit_udhaar, credit_vasooli, debit, credit, description, customer_name, userId } = item;
            const currentUserId = userId || mainUserId;

            if (!search_id) continue;

            const cleanSearchId = String(search_id).trim().toLowerCase();
            const cleanDesc = description ? String(description).trim() : '';
            const debitVal = parseFloat(debit_udhaar !== undefined ? debit_udhaar : debit) || 0;
            const creditVal = parseFloat(credit_vasooli !== undefined ? credit_vasooli : credit) || 0;
            const total_balance = creditVal - debitVal;

            // Master Customer Auto-add / Update
            if (customer_name && String(customer_name).trim() !== '') {
                const customerUpsert = `
                    INSERT INTO daily_customers (customer_name, search_id, user_id) 
                    VALUES (?, ?, ?)
                    ON DUPLICATE KEY UPDATE customer_name = VALUES(customer_name)
                `;
                await connection.query(customerUpsert, [String(customer_name).trim(), cleanSearchId, currentUserId]);
            }

            // Sirf wahi entry collect karo jo empty na ho
            if (cleanSearchId !== '' && (debitVal > 0 || creditVal > 0 || cleanDesc !== '')) {
                valuesToInsert.push([
                    cleanSearchId,
                    debitVal,
                    creditVal,
                    cleanDesc,
                    total_balance,
                    formattedSheetDate,
                    currentUserId
                ]);
            }
        }

        // Step 3: Nayi entries selected date par Bulk Insert karo
        if (valuesToInsert.length > 0) {
            const insertQuery = `
                INSERT INTO daily_sheets 
                (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id)
                VALUES ?
            `;
            await connection.query(insertQuery, [valuesToInsert]);
        }

        await connection.commit();
        connection.release();

        res.json({
            status: "Success",
            message: `${formattedSheetDate} ka data kamyabi se save ho gaya!`
        });
    } catch (error) {
        await connection.rollback();
        connection.release();
        console.error("Save Sheet Entry Error:", error);
        res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 4. Fetch Daily Sheet By Date (WITH PREVIOUS CUMULATIVE DEBIT & CREDIT CARRY FORWARD)
exports.getDailySheetByDate = async (req, res) => {
    try {
        const { date } = req.params; 
        const { userId } = req.query; 

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID parameter missing!" });
        }

        const formattedDate = formatDate(date);

        // Step 1: Current selected date ki entries fetch karo
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
            LEFT JOIN daily_sheets ds 
                ON LOWER(TRIM(dc.search_id)) = LOWER(TRIM(ds.search_id)) 
                AND DATE_FORMAT(ds.sheet_date, '%Y-%m-%d') = ?
                AND ds.user_id = ?
            WHERE dc.user_id = ?
            ORDER BY dc.id ASC
        `;
        
        const [rows] = await db.query(query, [formattedDate, userId, userId]);

        // Step 2: Strictly Selected Date se PEHLE tak ka Cumulative Debit & Credit
        const openingCumulativeQuery = `
            SELECT 
                COALESCE(SUM(debit_udhaar), 0) AS opening_debit,
                COALESCE(SUM(credit_vasooli), 0) AS opening_credit
            FROM daily_sheets 
            WHERE user_id = ? 
              AND DATE_FORMAT(sheet_date, '%Y-%m-%d') < ?
        `;
        
        const [openingCumResult] = await db.query(openingCumulativeQuery, [userId, formattedDate]);
        
        const opening_debit = parseFloat(openingCumResult[0]?.opening_debit) || 0;
        const opening_credit = parseFloat(openingCumResult[0]?.opening_credit) || 0;

        // Step 3: Pichlay dinon ka Opening Net Cash Balance
        const opening_balance = opening_credit - opening_debit;

        // Step 4: Aaj ke din ki total entries sum karo
        let today_debit = 0;
        let today_credit = 0;
        rows.forEach(entry => {
            today_debit += parseFloat(entry.debit_udhaar) || 0;
            today_credit += parseFloat(entry.credit_vasooli) || 0;
        });

        const overall_debit = opening_debit + today_debit;
        const overall_credit = opening_credit + today_credit;
        const closing_balance = opening_balance + (today_credit - today_debit);

        res.json({
            status: "Success",
            sheet_date: formattedDate,
            opening_debit: opening_debit,        // Pichle dino ka total debit carry forward
            opening_credit: opening_credit,      // Pichle dino ka total credit carry forward
            total_debit: overall_debit,          // Aaj tak ka overall grand total debit
            total_credit: overall_credit,        // Aaj tak ka overall grand total credit
            opening_balance: opening_balance,    // Opening cash balance
            closing_balance: closing_balance,    // Closing cash balance
            entries: rows
        });
    } catch (error) {
        console.error("Fetch Sheet Error:", error);
        res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 5. Delete Entry (With user verification)
exports.deleteSheetEntry = async (req, res) => {
    try {
        const { id } = req.params;
        const { userId } = req.query;

        if (id == 0) {
            return res.json({ status: "Success", message: "Empty row ignored." });
        }

        await db.query('DELETE FROM daily_sheets WHERE id = ? AND user_id = ?', [id, userId]);

        res.json({ status: "Success", message: `Entry deleted successfully.` });
    } catch (error) {
        console.error("Delete Entry Error:", error);
        res.status(500).json({ status: "Error", db_error: error.message });
    }
};

// 6. Delete Customer Permanently (User Isolated)
exports.deleteCustomerPermanently = async (req, res) => {
    try {
        const { search_id } = req.params;
        const { userId } = req.query; 

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        const cleanSearchId = search_id.trim().toLowerCase();

        await db.query('DELETE FROM daily_sheets WHERE LOWER(search_id) = ? AND user_id = ?', [cleanSearchId, userId]);
        await db.query('DELETE FROM daily_customers WHERE LOWER(search_id) = ? AND user_id = ?', [cleanSearchId, userId]);

        res.json({ status: "Success", message: `Customer permanently deleted.` });
    } catch (error) {
        console.error("Delete Customer Error:", error);
        res.status(500).json({ status: "Error", db_error: error.message });
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

        const EXPENSE_SEARCH_IDS = ['mi', 'i', 'bb', 'pm', 'rg', 's', 'l'];

        // 🚀 Agar Frontend se dates na aayi hon, to default Aaj (Today) ki date set karein
        let dateCondition = `AND DATE(ds.sheet_date) = CURDATE()`;
        let queryParams = [cleanUserId, EXPENSE_SEARCH_IDS];

        if (sDate && eDate) {
            dateCondition = `AND DATE(ds.sheet_date) BETWEEN ? AND ?`;
            queryParams = [cleanUserId, EXPENSE_SEARCH_IDS, sDate, eDate];
        }

        // 🚀 INNER JOIN ensures ke sirf wohi entries aayein jo us date ko enter hui hain
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
            WHERE ds.user_id = ? 
              AND LOWER(TRIM(dc.search_id)) IN (?)
              ${dateCondition}
            GROUP BY LOWER(TRIM(dc.search_id)), dc.customer_name, dc.id
            ORDER BY dc.id ASC
        `;

        const [rows] = await db.query(query, queryParams);

        let overallExpense = 0;
        const reportData = rows.map((row, index) => {
            const total = parseFloat(row.total_debit) || 0;
            overallExpense += total;

            return {
                sr_no: index + 1,
                search_id: row.search_id,
                account_name: row.account_name,
                total_transactions: row.transaction_count || 0,
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