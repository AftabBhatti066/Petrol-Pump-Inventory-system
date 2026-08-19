const db = require('../config/db');

// 1. VEHICLE REGISTRATION (Step 1)
exports.registerVehicle = async (req, res) => {
    try {
        const { gari_number, owner_name, contact_number, address, userId } = req.body;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID required hai!" });
        }

        if (!gari_number || !owner_name) {
            return res.status(400).json({ status: "Error", message: "Gari number aur Owner name zaroori hain!" });
        }

        const cleanGariNumber = gari_number.trim().toLowerCase();

        const existingQuery = 'SELECT id FROM vehicles WHERE LOWER(gari_number) = $1 AND user_id = $2';
        const { rows: existing } = await db.query(existingQuery, [cleanGariNumber, userId]);

        if (existing.length > 0) {
            return res.status(400).json({ status: "Error", message: "Yeh vehicle aap ke paas pehle se registered hai!" });
        }

        const query = `
            INSERT INTO vehicles (gari_number, owner_name, contact_number, address, user_id) 
            VALUES ($1, $2, $3, $4, $5)
        `;
        await db.query(query, [
            gari_number.trim(), 
            owner_name.trim(), 
            contact_number ? contact_number.trim() : '', 
            address ? address.trim() : '', 
            userId
        ]);

        res.json({
            status: "Success",
            message: `Ledger of vehicle number ${gari_number.trim()} is successfully opened!`
        });
    } catch (error) {
        console.error("Register Vehicle Error:", error);
        res.status(500).json({ status: "Error", message: "Database Error: " + error.message });
    }
};

// 2. DAILY CREDIT FUEL LOG (Step 2 - Udhaar Sale Entry)
exports.logCreditFuel = async (req, res) => {
    try {
        const { gari_number, driver_name, product, litres, entry_date, userId } = req.body;

        if (!gari_number || !product || !litres || !entry_date || !userId) {
            return res.status(400).json({ status: "Error", message: "Tamam fields samet User ID required hain!" });
        }

        const cleanGari = gari_number.trim().toLowerCase();

        const regQuery = 'SELECT id FROM vehicles WHERE LOWER(gari_number) = $1 AND user_id = $2';
        const { rows: isRegistered } = await db.query(regQuery, [cleanGari, userId]);

        if (isRegistered.length === 0) {
            return res.status(400).json({ 
                status: "Error", 
                message: "Yeh gari aap ke account mein register nahi hai! Pehle Step 1 se register karein." 
            });
        }

        const cleanProduct = product.trim().toLowerCase();
        const rateQuery = `
            SELECT rate_per_litre FROM fuel_rates 
            WHERE (LOWER(product_name) = $1 OR LOWER(product_type) = $2) 
              AND (user_id = $3 OR user_id IS NULL) 
            ORDER BY id DESC LIMIT 1
        `;
        const { rows: fuelRateResult } = await db.query(rateQuery, [cleanProduct, cleanProduct, userId]);
        
        if (!fuelRateResult || fuelRateResult.length === 0) {
            return res.status(400).json({
                status: "Error",
                message: `${product} ka rate Pricing section mein set nahi hai! Pehle rate update karein.`
            });
        }

        const current_rate = parseFloat(fuelRateResult[0].rate_per_litre) || 0;
        const parsedLitres = parseFloat(litres) || 0;
        const total_amount = parsedLitres * current_rate;

        const insertQuery = `
            INSERT INTO credit_ledgers (gari_number, driver_name, product, litres, rate_pkr, total_amount, payment_type, entry_date, user_id) 
            VALUES ($1, $2, $3, $4, $5, $6, 'CREDIT', $7, $8)
        `;

        await db.query(insertQuery, [
            gari_number.trim(), 
            driver_name ? driver_name.trim() : '', 
            product.trim(), 
            parsedLitres, 
            current_rate, 
            total_amount, 
            entry_date, 
            userId
        ]);

        res.json({
            status: "Success",
            message: "Udhaar entry kamyabi se save ho gayi!",
            calculated_data: {
                gari: gari_number,
                litres: parsedLitres,
                rate: current_rate,
                total_amount: total_amount
            }
        });

    } catch (error) {
        console.error("Log Credit Fuel Error:", error);
        res.status(500).json({ status: "Error", message: "Database Error: " + error.message });
    }
};

// 3. LOG VEHICLE VASOOLI
exports.logVehicleVasooli = async (req, res) => {
    try {
        const { gari_number, driver_name, amount_paid, entry_date, userId } = req.body;

        if (!gari_number || !amount_paid || !entry_date || !userId) {
            return res.status(400).json({ status: "Error", message: "Gari number, amount, date aur User ID zaroori hain!" });
        }

        const cleanGari = gari_number.trim().toLowerCase();

        const regQuery = 'SELECT id FROM vehicles WHERE LOWER(gari_number) = $1 AND user_id = $2';
        const { rows: isRegistered } = await db.query(regQuery, [cleanGari, userId]);

        if (isRegistered.length === 0) {
            return res.status(400).json({ 
                status: "Error", 
                message: "Yeh gari registered nahi hai! Pehle vehicle register karein." 
            });
        }

        const vasooliAmount = parseFloat(amount_paid) || 0;

        const insertQuery = `
            INSERT INTO credit_ledgers (gari_number, driver_name, product, litres, rate_pkr, total_amount, payment_type, entry_date, user_id) 
            VALUES ($1, $2, 'Cash Vasooli', 0, 0, $3, 'VASOOLI', $4, $5)
        `;

        await db.query(insertQuery, [
            gari_number.trim(), 
            driver_name ? driver_name.trim() : '', 
            vasooliAmount, 
            entry_date, 
            userId
        ]);

        res.json({
            status: "Success",
            message: "Gari ki vasooli entry kamyabi se record ho gayi!",
            vasooli_amount: vasooliAmount
        });

    } catch (error) {
        console.error("Log Vehicle Vasooli Error:", error);
        res.status(500).json({ status: "Error", message: "Database Error: " + error.message });
    }
};

// 4. GET CUSTOMER LEDGER WITH RUNNING BALANCE
exports.getVehicleLedger = async (req, res) => {
    try {
        const rawQuery = req.params.gari_number || '';
        const userId = req.query.userId;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID parameter missing!" });
        }

        const trimmedQuery = rawQuery.trim();
        const isAllQuery = !trimmedQuery || trimmedQuery.toUpperCase() === 'ALL';

        let dailySql = `
            WITH ranked_sheets AS (
                SELECT 
                    ds.*,
                    ROW_NUMBER() OVER (
                        PARTITION BY ds.user_id, ds.sheet_date 
                        ORDER BY ds.id ASC
                    ) AS calculated_sr_no
                FROM daily_sheets ds
                WHERE ds.user_id = $1
            )
            SELECT 
                rs.id,
                rs.calculated_sr_no AS sr_no,
                (
                    SELECT dc.customer_name 
                    FROM daily_customers dc 
                    WHERE LOWER(TRIM(dc.search_id)) = LOWER(TRIM(rs.search_id)) 
                      AND dc.user_id = rs.user_id 
                    LIMIT 1
                ) AS driver_name,
                rs.search_id,
                'Daily Sheet' AS product,
                0 AS litres,
                0 AS rate_pkr,
                CAST(COALESCE(rs.debit_udhaar, 0) AS DECIMAL(10,2)) AS debit_udhaar,
                CAST(COALESCE(rs.credit_vasooli, 0) AS DECIMAL(10,2)) AS credit_vasooli,
                CAST((COALESCE(rs.debit_udhaar, 0) - COALESCE(rs.credit_vasooli, 0)) AS DECIMAL(10,2)) AS net_total,
                rs.sheet_date AS entry_date,
                'CASH' AS payment_type,
                rs.description AS description,
                rs.user_id
            FROM ranked_sheets rs
            WHERE 1=1
        `;

        let dailyParams = [userId];

        if (!isAllQuery) {
            dailySql += ` AND LOWER(TRIM(rs.search_id)) = LOWER($2)`;
            dailyParams.push(trimmedQuery);
        }

        const { rows: cashRows } = await db.query(dailySql, dailyParams);

        cashRows.forEach(row => {
            if (!row.driver_name) {
                row.driver_name = `Customer (${row.search_id ? row.search_id.trim() : ''})`;
            }
        });

        // Chronological order for accurate running balance
        cashRows.sort((a, b) => {
            const dateDiff = new Date(a.entry_date) - new Date(b.entry_date);
            if (dateDiff !== 0) return dateDiff;
            return a.id - b.id;
        });

        let total_debit = 0;
        let total_credit_vasooli = 0;
        let cumulative_balance = 0;

        // Cumulative running balance computation
        cashRows.forEach(entry => {
            const debit = parseFloat(entry.debit_udhaar || 0);
            const credit = parseFloat(entry.credit_vasooli || 0);

            total_debit += debit;
            total_credit_vasooli += credit;

            cumulative_balance += (debit - credit);
            entry.running_balance = cumulative_balance;
        });

        return res.json({
            status: "Success",
            total_logged_fuel: 0,
            total_debit: total_debit,
            total_credit_vasooli: total_credit_vasooli,
            net_balance: cumulative_balance,
            history: cashRows
        });

    } catch (error) {
        console.error("❌ Daily Sheets Ledger Fetch Error:", error);
        return res.status(500).json({ 
            status: "Error", 
            message: "Database Error: " + error.message 
        });
    }
};

// 5. SAVE DAILY SHEET AND SYNC LEDGER (Auto Sync Trigger)
exports.saveDailySheetAndSyncLedger = async (req, res) => {
    const client = await db.connect();
    try {
        await client.query('BEGIN');
        const { search_id, debit_udhaar, credit_vasooli, sheet_date, description, userId } = req.body;

        if (!search_id || !sheet_date || !userId) {
            await client.query('ROLLBACK');
            return res.status(400).json({ status: "Error", message: "Search ID, Date aur User ID required hain!" });
        }

        // Insert into Daily Sheets
        const insertSheetQuery = `
            INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, sheet_date, description, user_id)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id
        `;
        const sheetRes = await client.query(insertSheetQuery, [
            search_id.trim(),
            parseFloat(debit_udhaar) || 0,
            parseFloat(credit_vasooli) || 0,
            sheet_date,
            description ? description.trim() : '',
            userId
        ]);

        await client.query('COMMIT');

        res.json({
            status: "Success",
            message: "Daily sheet saved and ledger updated automatically!",
            sheet_id: sheetRes.rows[0].id
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Daily Sheet Save Error:", error);
        res.status(500).json({ status: "Error", message: "Database Error: " + error.message });
    } finally {
        client.release();
    }
};

// 6. DELETE CREDIT ENTRY
exports.deleteCreditEntry = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.query.userId;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID validation fail!" });
        }

        const checkQuery = 'SELECT * FROM credit_ledgers WHERE id = $1 AND user_id = $2';
        const { rows: entryCheck } = await db.query(checkQuery, [id, userId]);
        
        if (entryCheck.length === 0) {
            return res.status(404).json({
                status: "Error",
                message: "Yeh entry pehle hi delete ho chuki hai ya aap authorized nahi hain."
            });
        }

        await db.query('DELETE FROM credit_ledgers WHERE id = $1 AND user_id = $2', [id, userId]);

        res.json({
            status: "Success",
            message: `Entry ID ${id} khate se kamyabi se khatam kar di gayi hai!`
        });

    } catch (error) {
        console.error("Delete Credit Entry Error:", error);
        res.status(500).json({ status: "Error", message: "Database Error: " + error.message });
    }
};

// 7. GET TRIAL BALANCE SUMMARY
exports.getTrialBalance = async (req, res) => {
    try {
        const { userId, startDate, endDate } = req.query;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID is required" });
        }

        let params = [];

        if (startDate && endDate) {
            params = [userId, userId, startDate, endDate, userId, startDate, endDate, userId, userId];
        } else {
            params = [userId, userId, userId, userId, userId];
        }

        const query = `
            SELECT 
                party_name,
                COALESCE(SUM(debit_udhaar), 0) AS total_debit,
                COALESCE(SUM(credit_vasooli), 0) AS total_credit
            FROM (
                -- Stream 1: Unique Customer Names with direct Daily Sheets aggregation
                SELECT 
                    TRIM(dc.customer_name) AS party_name,
                    CAST(COALESCE(ds.debit_udhaar, 0) AS DECIMAL(10,2)) AS debit_udhaar,
                    CAST(COALESCE(ds.credit_vasooli, 0) AS DECIMAL(10,2)) AS credit_vasooli
                FROM daily_sheets ds
                INNER JOIN (
                    SELECT DISTINCT LOWER(TRIM(search_id)) AS search_id, customer_name, user_id 
                    FROM daily_customers 
                    WHERE user_id = $1
                ) dc ON LOWER(TRIM(ds.search_id)) = dc.search_id
                WHERE ds.user_id = $2
                  ${startDate && endDate ? "AND ds.sheet_date::date BETWEEN $3::date AND $4::date" : ""}

                UNION ALL

                -- Stream 2: Daily Sheets Entries whose search_id is NOT in daily_customers
                SELECT 
                    CONCAT('Customer (', TRIM(ds.search_id), ')') AS party_name,
                    CAST(COALESCE(ds.debit_udhaar, 0) AS DECIMAL(10,2)) AS debit_udhaar,
                    CAST(COALESCE(ds.credit_vasooli, 0) AS DECIMAL(10,2)) AS credit_vasooli
                FROM daily_sheets ds
                WHERE ds.user_id = ${startDate && endDate ? "$5" : "$3"}
                  ${startDate && endDate ? "AND ds.sheet_date::date BETWEEN $6::date AND $7::date" : ""}
                  AND LOWER(TRIM(ds.search_id)) NOT IN (
                      SELECT LOWER(TRIM(search_id)) FROM daily_customers 
                      WHERE user_id = ${startDate && endDate ? "$8" : "$4"} AND search_id IS NOT NULL AND search_id != ''
                  )

                UNION ALL

                -- Stream 3: Master Chart of Accounts
                SELECT 
                    account_name AS party_name,
                    CASE WHEN balance_type = 'DEBIT' THEN CAST(opening_balance AS DECIMAL(10,2)) ELSE 0.00 END AS debit_udhaar,
                    CASE WHEN balance_type = 'CREDIT' THEN CAST(opening_balance AS DECIMAL(10,2)) ELSE 0.00 END AS credit_vasooli
                FROM chart_of_accounts
                WHERE user_id = ${startDate && endDate ? "$9" : "$5"}

            ) AS combined_ledger
            GROUP BY party_name
            ORDER BY party_name ASC
        `;

        const { rows } = await db.query(query, params);

        return res.json({
            status: "Success",
            data: rows
        });
    } catch (error) {
        console.error("Trial Balance Controller Error:", error);
        return res.status(500).json({ status: "Error", message: error.message });
    }
};

// 8. GET ACCOUNT TYPES
exports.getAccountTypes = async (req, res) => {
    try {
        const { rows: types } = await db.query('SELECT * FROM account_types ORDER BY id ASC');
        res.json({ status: "Success", data: types });
    } catch (error) {
        console.error("Get Account Types Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 9. CREATE NEW CHART OF ACCOUNT
exports.createAccount = async (req, res) => {
    try {
        const { account_name, account_type_id, opening_balance, balance_type, userId } = req.body;

        if (!account_name || !account_type_id || !userId) {
            return res.status(400).json({ status: "Error", message: "Account Name, Type, aur User ID zaroori hain!" });
        }

        const balance = parseFloat(opening_balance) || 0.00;
        const bType = balance_type || 'DEBIT';

        const query = `
            INSERT INTO chart_of_accounts (account_name, account_type_id, opening_balance, balance_type, user_id)
            VALUES ($1, $2, $3, $4, $5)
        `;

        await db.query(query, [account_name.trim(), account_type_id, balance, bType, userId]);

        res.json({
            status: "Success",
            message: `Account '${account_name.trim()}' kamyabi se create ho gaya hai!`
        });

    } catch (error) {
        console.error("Create Account Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};