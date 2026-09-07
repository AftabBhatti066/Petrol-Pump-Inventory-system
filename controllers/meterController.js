const db = require('../config/db');

// Default Lubricants list
const DEFAULT_LUBRICANTS = [
    'T 2 20Ltrs', 'Balize .75', 'Balize 1Ltrs', 'Cariant 3Ltrs',
    'Cariant 4ltrs', 'Deo 6000 4Ltrs', 'Deo 6000 10Ltrs',
    'Deo 8000 4Ltrs', 'Deo 8000 10Ltrs'
];

// Helper Function: Date YYYY-MM-DD Format (With Detailed Fallback & Logs)
const formatDate = (dateInput) => {
    console.log("formatDate input received:", dateInput, "Type:", typeof dateInput);

    if (!dateInput || dateInput === "" || dateInput === "null" || dateInput === "undefined") {
        console.log("⚠️ No date provided or empty! Falling back to current system date.");
        const today = new Date();
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = String(today.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    if (typeof dateInput === 'string') {
        const cleanDate = dateInput.split('T')[0];
        if (/^\d{4}-\d{2}-\d{2}$/.test(cleanDate)) {
            console.log("✅ Valid string date parsed:", cleanDate);
            return cleanDate;
        }
    }

    const d = new Date(dateInput);
    if (!isNaN(d.getTime())) {
        const year = d.getUTCFullYear();
        const month = String(d.getUTCMonth() + 1).padStart(2, '0');
        const day = String(d.getUTCDate()).padStart(2, '0');
        const parsedResult = `${year}-${month}-${day}`;
        console.log("✅ Parsed date via Date object:", parsedResult);
        return parsedResult;
    }

    const today = new Date();
    const fallback = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
    console.log("⚠️ Date parsing failed, using fallback current date:", fallback);
    return fallback;
};

// Helper Function: Parse User ID safely into Integer
const parseUserId = (userId) => {
    if (userId === undefined || userId === null || userId === "null" || userId === "undefined" || userId === "") {
        return null;
    }
    const parsed = parseInt(userId, 10);
    return isNaN(parsed) ? null : parsed;
};

// Helper Function: Ensure Master Customer Exists in daily_customers
const ensureMasterCustomerExists = async (client, searchId, defaultName, userId) => {
    const cleanSearchId = searchId.trim().toLowerCase();
    const cleanName = defaultName.trim();

    const query = `
        INSERT INTO daily_customers (customer_name, search_id, user_id) 
        VALUES ($1, $2, $3)
        ON CONFLICT (search_id, user_id) DO NOTHING
    `;
    await client.query(query, [cleanName, cleanSearchId, userId]);
};

// 0. GET ALL FUEL RATES / PRICING
exports.getRates = async (req, res) => {
    try {
        const userId = parseUserId(req.query.userId);

        const query = `
            SELECT id, product_name, product_type, specific_category, 
                   rate_per_litre, purchase_price, rate_date, user_id
            FROM fuel_rates
            WHERE ($1::integer IS NULL AND user_id IS NULL)
               OR ($1::integer IS NOT NULL AND (user_id = $1::integer OR user_id IS NULL))
            ORDER BY id ASC
        `;

        const result = await db.query(query, [userId]);
        res.json({ status: "Success", data: result.rows });
    } catch (error) {
        console.error("Get Rates Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 1. GET NOZZLE READINGS FOR A SPECIFIC DATE
exports.getAllReadings = async (req, res) => {
    try {
        const { userId, date } = req.query;
        const parsedUserId = parseUserId(userId);

        if (!parsedUserId) {
            return res.status(400).json({ status: "Error", message: "Valid User ID is required!" });
        }

        const targetDate = formatDate(date);

        const query = `
            SELECT 
                mr.id,
                mr.nozzle_name,
                mr.fuel_type,
                mr.opening_reading,
                mr.closing_reading,
                mr.liters_sold,
                mr.reading_date,
                mr.user_id,
                COALESCE((
                    SELECT prev.closing_reading 
                    FROM meter_readings prev 
                    WHERE prev.user_id = $1::integer 
                      AND prev.nozzle_name = mr.nozzle_name 
                      AND prev.reading_date < $2::date
                    ORDER BY prev.reading_date DESC, prev.id DESC 
                    LIMIT 1
                ), 0) AS prev_closing
            FROM meter_readings mr
            WHERE mr.user_id = $1::integer AND mr.reading_date = $2::date
        `;

        let result = await db.query(query, [parsedUserId, targetDate]);

        if (result.rows.length === 0) {
            const prevQuery = `
                SELECT DISTINCT ON (nozzle_name)
                    nozzle_name,
                    fuel_type,
                    closing_reading AS closing_reading,
                    closing_reading AS opening_reading,
                    0 AS liters_sold,
                    reading_date
                FROM meter_readings
                WHERE user_id = $1::integer AND reading_date < $2::date
                ORDER BY nozzle_name, reading_date DESC, id DESC
            `;
            const prevResult = await db.query(prevQuery, [parsedUserId, targetDate]);
            return res.json({ status: "Success", data: prevResult.rows });
        }

        res.json({ status: "Success", data: result.rows });
    } catch (error) {
        console.error("Get All Readings Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 2. GET FUEL TANK STOCK FOR A SPECIFIC DATE
exports.getTankStock = async (req, res) => {
    try {
        const { userId, date } = req.query;
        const parsedUserId = parseUserId(userId);

        if (!parsedUserId) {
            return res.status(400).json({ status: "Error", message: "Valid User ID is required!" });
        }

        const targetDate = formatDate(date);

        const query = `
            SELECT 
                fs.fuel_type,
                (
                    fs.current_stock
                    - COALESCE((
                        SELECT SUM(liters) FROM (
                            SELECT 
                                liters_sold AS liters, 
                                fuel_type, 
                                reading_date AS tx_date 
                            FROM meter_readings 
                            WHERE user_id = $1::integer
                        ) sales 
                        WHERE LOWER(TRIM(sales.fuel_type)) = LOWER(TRIM(fs.fuel_type))
                          AND sales.tx_date > $2::date
                    ), 0)
                    + COALESCE((
                        SELECT SUM(debit_udhaar) 
                        FROM daily_sheets 
                        WHERE user_id = $1::integer 
                          AND sheet_date > $2::date
                          AND (
                            (LOWER(TRIM(fs.fuel_type)) LIKE '%diesel%' AND LOWER(TRIM(search_id)) = 'dl')
                            OR (LOWER(TRIM(fs.fuel_type)) LIKE '%super%' AND LOWER(TRIM(search_id)) = 'sp')
                          )
                    ), 0)
                ) AS current_stock
            FROM fuel_stocks fs
            WHERE fs.user_id = $1::integer
        `;

        let result = await db.query(query, [parsedUserId, targetDate]);
        let rows = result.rows;

        if (rows.length === 0) {
            await db.query(`
                INSERT INTO fuel_stocks (fuel_type, current_stock, user_id) 
                VALUES ('Diesel', 0.00, $1::integer), ('Super', 0.00, $1::integer)
                ON CONFLICT (fuel_type, user_id) DO NOTHING
            `, [parsedUserId]);

            const retryResult = await db.query(query, [parsedUserId, targetDate]);
            rows = retryResult.rows;
        }

        res.json({ status: "Success", data: rows });
    } catch (error) {
        console.error("Get Tank Stock Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 3. GET LUBRICANT STOCK FOR A SPECIFIC DATE
exports.getLubricantStock = async (req, res) => {
    try {
        const { userId, date } = req.query;
        const parsedUserId = parseUserId(userId);

        if (!parsedUserId) {
            return res.status(400).json({ status: "Error", message: "Valid User ID is required!" });
        }

        const targetDate = formatDate(date);

        let query = `
            SELECT 
                ls.item_name,
                (
                    ls.current_stock 
                    - COALESCE((
                        SELECT SUM(
                            CAST(
                                NULLIF(
                                    REGEXP_REPLACE(
                                        SUBSTRING(description FROM '([0-9]+\\s*' || REPLACE(REPLACE(ls.item_name, '.', '\\.'), '(', '\\(') || ')'), 
                                        '[^0-9]', '', 'g'
                                    ), ''
                                ) AS INTEGER
                            )
                        ) 
                        FROM daily_sheets 
                        WHERE LOWER(TRIM(search_id)) = 'lub' 
                          AND user_id = $1::integer 
                          AND sheet_date > $2::date 
                          AND credit_vasooli > 0 
                          AND description LIKE '%' || ls.item_name || '%'
                    ), 0)
                    + COALESCE((
                        SELECT SUM(
                            CAST(
                                NULLIF(
                                    REGEXP_REPLACE(
                                        SUBSTRING(description FROM '([0-9]+\\s*' || REPLACE(REPLACE(ls.item_name, '.', '\\.'), '(', '\\(') || ')'), 
                                        '[^0-9]', '', 'g'
                                    ), ''
                                ) AS INTEGER
                            )
                        ) 
                        FROM daily_sheets 
                        WHERE LOWER(TRIM(search_id)) = 'lub' 
                          AND user_id = $1::integer 
                          AND sheet_date > $2::date 
                          AND debit_udhaar > 0 
                          AND description LIKE '%' || ls.item_name || '%'
                    ), 0)
                ) AS current_stock,
                ls.shift_sales_deduct,
                COALESCE(fr.rate_per_litre, fr.purchase_price, 0) as sale_price,
                COALESCE(fr.purchase_price, fr.rate_per_litre, 0) as purchase_price
            FROM lubricant_stocks ls
            LEFT JOIN LATERAL (
                SELECT rate_per_litre, purchase_price 
                FROM fuel_rates 
                WHERE LOWER(TRIM(product_name)) = LOWER(TRIM(ls.item_name))
                   OR LOWER(TRIM(specific_category)) = LOWER(TRIM(ls.item_name))
                ORDER BY id DESC LIMIT 1
            ) fr ON true
            WHERE ls.user_id = $1::integer
        `;

        let result = await db.query(query, [parsedUserId, targetDate]);
        let rows = result.rows;

        if (rows.length === 0) {
            for (const item of DEFAULT_LUBRICANTS) {
                await db.query(`
                    INSERT INTO lubricant_stocks (item_name, current_stock, shift_sales_deduct, user_id) 
                    VALUES ($1, 0, 0, $2::integer)
                    ON CONFLICT (item_name, user_id) DO NOTHING
                `, [item, parsedUserId]);
            }
            const retryResult = await db.query(query, [parsedUserId, targetDate]);
            rows = retryResult.rows;
        }

        res.json({ status: "Success", data: rows });
    } catch (error) {
        console.error("Get Lubricant Stock Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 4. ADD / UPDATE METER READING (Updated with Daily Sheet date support)
exports.addReading = async (req, res) => {
    let client;
    try {
        console.log("=== ADD READING REQUEST RECEIVED ===");
        console.log("REQUEST BODY:", req.body);

        client = await db.getClient ? await db.getClient() : await db.connect();
        await client.query('BEGIN');

        const { nozzle_name, fuel_type, closing_reading, reading_date, date, selectedDate, readingDate, userId } = req.body;
        const parsedUserId = parseUserId(userId);
        
        const rawDate = reading_date || date || selectedDate || readingDate;
        const formattedDate = formatDate(rawDate);

        console.log("Extracted raw reading date:", rawDate, "=> Formatted Target Date:", formattedDate);

        if (!nozzle_name || closing_reading === undefined || !parsedUserId) {
            await client.query('ROLLBACK');
            return res.status(400).json({ status: "Error", message: "Missing required fields or invalid User ID!" });
        }

        const closingVal = parseFloat(closing_reading) || 0;

        const lastResult = await client.query(
            `SELECT closing_reading FROM meter_readings 
             WHERE nozzle_name = $1 AND user_id = $2::integer AND reading_date < $3::date 
             ORDER BY reading_date DESC, id DESC LIMIT 1`,
            [nozzle_name, parsedUserId, formattedDate]
        );

        const openingVal = lastResult.rows.length > 0 ? parseFloat(lastResult.rows[0].closing_reading) || 0 : 0.00;
        const litersSold = Math.max(0, closingVal - openingVal);

        await client.query(`
            INSERT INTO meter_readings (nozzle_name, fuel_type, opening_reading, closing_reading, liters_sold, reading_date, user_id)
            VALUES ($1, $2, $3, $4, $5, $6::date, $7::integer)
            ON CONFLICT (user_id, nozzle_name, reading_date) 
            DO UPDATE SET 
                fuel_type = EXCLUDED.fuel_type,
                opening_reading = EXCLUDED.opening_reading,
                closing_reading = EXCLUDED.closing_reading,
                liters_sold = GREATEST(0, EXCLUDED.closing_reading - EXCLUDED.opening_reading)
        `, [nozzle_name, fuel_type, openingVal, closingVal, litersSold, formattedDate, parsedUserId]);

        await client.query(`
            INSERT INTO fuel_stocks (fuel_type, current_stock, user_id) 
            VALUES ($1, 0.00, $2::integer)
            ON CONFLICT (fuel_type, user_id) DO NOTHING
        `, [fuel_type, parsedUserId]);

        await client.query('COMMIT');
        res.json({ status: "Success", message: "Meter reading updated successfully for date: " + formattedDate });
    } catch (error) {
        if (client) await client.query('ROLLBACK');
        console.error("Add Reading Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    } finally {
        if (client) client.release();
    }
};

// 5. UPDATE TANK RECEIPTS
exports.updateReceipt = async (req, res) => {
    let client;
    try {
        console.log("=== UPDATE RECEIPT REQUEST RECEIVED ===");
        console.log("REQUEST BODY:", req.body);

        client = await db.getClient ? await db.getClient() : await db.connect();
        await client.query('BEGIN');

        const { fuel_type, receipt_liters, total_amount, rate_per_liter, receipt_date, date, selectedDate, receiptDate, reading_date, userId } = req.body;
        const parsedUserId = parseUserId(userId);

        // Added reading_date to successfully capture the date from the payload
        const rawDate = receipt_date || date || selectedDate || receiptDate || reading_date;
        const entryDate = formatDate(rawDate);

        console.log("Extracted raw receipt date:", rawDate, "=> Final Entry Date:", entryDate);

        if (!fuel_type || !receipt_liters || !parsedUserId) {
            await client.query('ROLLBACK');
            return res.status(400).json({ status: "Error", message: "Missing receipt parameters or invalid User ID!" });
        }

        const liters = parseFloat(receipt_liters) || 0;
        const typeNormalized = fuel_type.trim().toLowerCase();

        const searchId = typeNormalized.includes('diesel') ? 'dl' : 'sp';
        const defaultCustomerName = typeNormalized.includes('diesel') ? 'Diesel Khata' : 'Super Petrol Khata';
        const fuelSearchType = typeNormalized.includes('diesel') ? 'Diesel' : 'Super';

        let calculatedTotal = 0;
        let finalRate = 0;

        if (total_amount !== undefined && total_amount !== null && total_amount !== '' && parseFloat(total_amount) > 0) {
            calculatedTotal = parseFloat(total_amount);
            finalRate = liters > 0 ? (calculatedTotal / liters) : 0;
        } 
        else if (rate_per_liter && parseFloat(rate_per_liter) > 0) {
            finalRate = parseFloat(rate_per_liter);
            calculatedTotal = liters * finalRate;
        } 
        else {
            let rateResult = await client.query(
                `SELECT purchase_price, rate_per_litre FROM fuel_rates 
                 WHERE (LOWER(TRIM(product_type)) LIKE LOWER($1) 
                    OR LOWER(TRIM(product_name)) LIKE LOWER($1) 
                    OR LOWER(TRIM(specific_category)) LIKE LOWER($1))
                    AND (user_id = $2::integer OR user_id IS NULL)
                 ORDER BY rate_date DESC, created_at DESC, id DESC LIMIT 1`,
                [`%${fuelSearchType.toLowerCase()}%`, parsedUserId]
            );

            if (rateResult.rows.length === 0) {
                rateResult = await client.query(
                    `SELECT purchase_price, rate_per_litre FROM fuel_rates 
                     WHERE LOWER(TRIM(product_type)) LIKE LOWER($1) 
                        OR LOWER(TRIM(product_name)) LIKE LOWER($1)
                     ORDER BY rate_date DESC, created_at DESC, id DESC LIMIT 1`,
                    [`%${fuelSearchType.toLowerCase()}%`]
                );
            }

            if (rateResult.rows.length > 0) {
                const row = rateResult.rows[0];
                const pPrice = parseFloat(row.purchase_price || 0);
                const rPrice = parseFloat(row.rate_per_litre || 0);
                finalRate = pPrice > 0 ? pPrice : rPrice;
            }

            calculatedTotal = liters * finalRate;
        }

        const formattedRate = finalRate.toFixed(2);
        const descriptionText = finalRate > 0 
            ? `${typeNormalized.includes('diesel') ? 'Diesel' : 'Petrol'} Stock Receipt (${liters}L @ ${formattedRate})`
            : `${typeNormalized.includes('diesel') ? 'Diesel' : 'Petrol'} Stock Receipt (${liters}L)`;

        await ensureMasterCustomerExists(client, searchId, defaultCustomerName, parsedUserId);

        await client.query(`
            INSERT INTO fuel_stocks (fuel_type, current_stock, opening_stock, receipt_stock, user_id) 
            VALUES ($1, 0.00, 0.00, 0.00, $2::integer)
            ON CONFLICT (fuel_type, user_id) DO NOTHING
        `, [fuel_type, parsedUserId]);

        await client.query(`
            UPDATE fuel_stocks 
            SET current_stock = current_stock + $1,
                receipt_stock = receipt_stock + $1
            WHERE LOWER(TRIM(fuel_type)) = LOWER(TRIM($2)) AND user_id = $3::integer
        `, [liters, fuel_type, parsedUserId]);

        await client.query(`
            INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id)
            VALUES ($1, $2, $3, $4, $5, $6::date, $7::integer)
        `, [
            searchId,
            calculatedTotal,
            0.00,
            descriptionText,
            -calculatedTotal,
            entryDate, 
            parsedUserId
        ]);

        await client.query('COMMIT');

        res.json({ 
            status: "Success", 
            message: `Stock added (${liters} Ltrs) under '${searchId}' for date ${entryDate}!`,
            data: { liters, rate: formattedRate, totalAmount: calculatedTotal, search_id: searchId, date: entryDate }
        });
    } catch (error) {
        if (client) await client.query('ROLLBACK');
        console.error("Update Receipt Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    } finally {
        if (client) client.release();
    }
};

// 6. BATCH UPDATE LUBRICANTS
exports.updateLubricants = async (req, res) => {
    let client;
    try {
        console.log("=== UPDATE LUBRICANTS REQUEST RECEIVED ===");
        console.log("REQUEST BODY:", req.body);

        client = await db.getClient ? await db.getClient() : await db.connect();
        await client.query('BEGIN');

        const { lubricant_sales, lubricant_receipts, receipt_date, date, reading_date, selectedDate, userId } = req.body;
        const parsedUserId = parseUserId(userId);
        
        const rawDate = receipt_date || date || reading_date || selectedDate;
        const entryDate = formatDate(rawDate);

        console.log("Extracted raw lubricant date:", rawDate, "=> Final Entry Date:", entryDate);

        if (!parsedUserId) {
            await client.query('ROLLBACK');
            return res.status(400).json({ status: "Error", message: "Valid User ID is required!" });
        }

        const searchId = 'lub';

        await ensureMasterCustomerExists(client, searchId, 'Moblile Khata', parsedUserId);

        // 1. Process Receipts (Stock Purchase -> Debit in Daily Sheet)
        if (lubricant_receipts && lubricant_receipts.length > 0) {
            for (const item of lubricant_receipts) {
                const qty = parseInt(item.qty, 10) || 0;
                if (qty > 0) {
                    await client.query(`
                        INSERT INTO lubricant_stocks (item_name, current_stock, shift_sales_deduct, user_id) 
                        VALUES ($1, 0, 0, $2::integer)
                        ON CONFLICT (item_name, user_id) DO NOTHING
                    `, [item.name, parsedUserId]);

                    await client.query(
                        'UPDATE lubricant_stocks SET current_stock = current_stock + $1 WHERE item_name = $2 AND user_id = $3::integer',
                        [qty, item.name, parsedUserId]
                    );

                    let rate = parseFloat(item.price || item.rate || 0);
                    if (rate <= 0) {
                        const rateRes = await client.query(`
                            SELECT purchase_price, rate_per_litre FROM fuel_rates 
                            WHERE LOWER(TRIM(product_name)) = LOWER(TRIM($1))
                               OR LOWER(TRIM(specific_category)) = LOWER(TRIM($1))
                            ORDER BY id DESC LIMIT 1
                        `, [item.name]);

                        if (rateRes.rows.length > 0) {
                            rate = parseFloat(rateRes.rows[0].purchase_price || rateRes.rows[0].rate_per_litre || 0);
                        }
                    }

                    const itemTotal = qty * rate;
                    const desc = `Mobiloil stock receipt (${qty} ${item.name} @ ${rate.toFixed(2)})`;

                    await client.query(`
                        INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id)
                        VALUES ($1, $2, $3, $4, $5, $6::date, $7::integer)
                    `, [
                        searchId,
                        itemTotal,
                        0.00,
                        desc,
                        -itemTotal,
                        entryDate,
                        parsedUserId
                    ]);
                }
            }
        }

        // 2. Process Sales (Stock Sale)
        if (lubricant_sales && lubricant_sales.length > 0) {
            for (const item of lubricant_sales) {
                const saleQty = parseInt(item.qty, 10) || 0;

                if (saleQty > 0) {
                    await client.query(`
                        INSERT INTO lubricant_stocks (item_name, current_stock, shift_sales_deduct, user_id) 
                        VALUES ($1, 0, 0, $2::integer)
                        ON CONFLICT (item_name, user_id) DO NOTHING
                    `, [item.name, parsedUserId]);

                    await client.query(
                        `UPDATE lubricant_stocks 
                         SET current_stock = current_stock - $1 
                         WHERE item_name = $2 AND user_id = $3::integer`,
                        [saleQty, item.name, parsedUserId]
                    );

                    await client.query(`
                        INSERT INTO lubricant_shift_sales (item_name, liters_sold, sale_date, user_id) 
                        VALUES ($1, $2, $3::date, $4::integer)
                    `, [item.name, saleQty, entryDate, parsedUserId]);
                }
            }
        }

        await client.query('COMMIT');
        res.json({ status: "Success", message: "Lubricant stock aur Daily Sheet successfully update ho gaye hain for date: " + entryDate });
    } catch (error) {
        if (client) await client.query('ROLLBACK');
        console.error("Update Lubricants Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    } finally {
        if (client) client.release();
    }
};