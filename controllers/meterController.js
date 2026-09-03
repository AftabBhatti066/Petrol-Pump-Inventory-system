const db = require('../config/db');

// Default Lubricants list for recovery
const DEFAULT_LUBRICANTS = [
    'T 2 20Ltrs', 'Balize .75', 'Balize 1Ltrs', 'Cariant 3Ltrs',
    'Cariant 4ltrs', 'Deo 6000 4Ltrs', 'Deo 6000 10Ltrs',
    'Deo 8000 4Ltrs', 'Deo 8000 10Ltrs'
];

// Helper Function: Safe Date Formatting
const formatDate = (dateInput) => {
    if (!dateInput) {
        const today = new Date();
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = String(today.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    if (typeof dateInput === 'string') {
        const cleanDate = dateInput.split('T')[0];
        if (/^\d{4}-\d{2}-\d{2}$/.test(cleanDate)) {
            return cleanDate;
        }
    }

    const d = new Date(dateInput);
    const year = d.getUTCFullYear();
    const month = String(d.getUTCMonth() + 1).padStart(2, '0');
    return `${year}-${month}-${day}`;
};

// Helper Function: Get Next Day Date String (YYYY-MM-DD)
const getNextDate = (currentDateStr) => {
    const d = new Date(currentDateStr);
    d.setDate(d.getDate() + 1);
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
};

// 0. GET ALL FUEL RATES (Date Specific)
exports.getRates = async (req, res) => {
    try {
        const { userId, date } = req.query;
        const targetDate = formatDate(date);

        const query = `
            SELECT id, product_name, product_type, specific_category, 
                   rate_per_litre, purchase_price, rate_date, user_id
            FROM fuel_rates
            WHERE (user_id = $1 OR user_id IS NULL)
              AND rate_date <= $2
            ORDER BY rate_date DESC, id DESC
        `;

        const result = await db.query(query, [userId || null, targetDate]);
        res.json({ status: "Success", data: result.rows });
    } catch (error) {
        console.error("Get Rates Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 1. GET NOZZLE READINGS UP TO SELECTED DATE
exports.getAllReadings = async (req, res) => {
    try {
        const { userId, date } = req.query;
        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        const targetDate = formatDate(date);

        const query = `
            SELECT m1.* FROM meter_readings m1
            INNER JOIN (
                SELECT nozzle_name, MAX(id) as max_id 
                FROM meter_readings 
                WHERE user_id = $1 AND reading_date <= $2
                GROUP BY nozzle_name
            ) m2 ON m1.id = m2.max_id
            WHERE m1.user_id = $1
        `;

        const result = await db.query(query, [userId, targetDate]);
        res.json({ status: "Success", data: result.rows });
    } catch (error) {
        console.error("Get All Readings Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 2. GET FUEL TANK STOCK AS OF SELECTED DATE
exports.getTankStock = async (req, res) => {
    try {
        const { userId, date } = req.query;
        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        const targetDate = formatDate(date);

        const query = `
            SELECT 
                fs.fuel_type,
                (
                    COALESCE(fs.opening_stock, 0) 
                    + COALESCE(receipts.total_received, 0) 
                    - COALESCE(sales.total_sold, 0)
                ) AS current_stock
            FROM fuel_stocks fs
            LEFT JOIN (
                SELECT 
                    CASE 
                        WHEN LOWER(description) LIKE '%diesel%' THEN 'Diesel'
                        ELSE 'Super' 
                    END as fuel_type,
                    SUM(
                        CAST(SUBSTRING(description FROM '([0-9\.]+)L') AS NUMERIC)
                    ) as total_received
                FROM daily_sheets
                WHERE user_id = $1 AND sheet_date <= $2 AND search_id IN ('dl', 'sp')
                GROUP BY fuel_type
            ) receipts ON LOWER(fs.fuel_type) = LOWER(receipts.fuel_type)
            LEFT JOIN (
                SELECT fuel_type, SUM(liters_sold) as total_sold
                FROM meter_readings
                WHERE user_id = $1 AND reading_date <= $2
                GROUP BY fuel_type
            ) sales ON LOWER(fs.fuel_type) = LOWER(sales.fuel_type)
            WHERE fs.user_id = $1
        `;

        let result = await db.query(query, [userId, targetDate]);
        let rows = result.rows;

        if (rows.length === 0) {
            await db.query(`
                INSERT INTO fuel_stocks (fuel_type, current_stock, user_id) 
                VALUES ('Diesel', 0.00, $1), ('Super', 0.00, $1)
                ON CONFLICT (fuel_type, user_id) DO NOTHING
            `, [userId]);

            const retryResult = await db.query(query, [userId, targetDate]);
            rows = retryResult.rows;
        }

        res.json({ status: "Success", data: rows });
    } catch (error) {
        console.error("Get Tank Stock Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 3. GET LUBRICANT STOCK AS OF SELECTED DATE
exports.getLubricantStock = async (req, res) => {
    try {
        const { userId, date } = req.query;
        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        const targetDate = formatDate(date);

        let query = `
            SELECT ls.item_name, 
                   COALESCE(ls.current_stock, 0) as current_stock, 
                   COALESCE(ls.shift_sales_deduct, 0) as shift_sales_deduct,
                   COALESCE(fr.purchase_price, fr.rate_per_litre, 0) as purchase_price
            FROM lubricant_stocks ls
            LEFT JOIN LATERAL (
                SELECT purchase_price, rate_per_litre 
                FROM fuel_rates 
                WHERE (LOWER(TRIM(product_name)) = LOWER(TRIM(ls.item_name))
                   OR LOWER(TRIM(specific_category)) = LOWER(TRIM(ls.item_name)))
                  AND (user_id = $1 OR user_id IS NULL)
                  AND rate_date <= $2
                ORDER BY rate_date DESC, id DESC LIMIT 1
            ) fr ON true
            WHERE ls.user_id = $1
        `;

        let result = await db.query(query, [userId, targetDate]);
        let rows = result.rows;
        
        if (rows.length === 0) {
            for (const item of DEFAULT_LUBRICANTS) {
                await db.query(`
                    INSERT INTO lubricant_stocks (item_name, current_stock, shift_sales_deduct, user_id) 
                    VALUES ($1, 0, 0, $2)
                    ON CONFLICT (item_name, user_id) DO NOTHING
                `, [item, userId]);
            }
            const retryResult = await db.query(query, [userId, targetDate]);
            rows = retryResult.rows;
        }

        res.json({ status: "Success", data: rows });
    } catch (error) {
        console.error("Get Lubricant Stock Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 4. ADD NEW METER READING (Auto Next Working Date Return)
exports.addReading = async (req, res) => {
    const client = await db.connect();
    try {
        const { nozzle_name, fuel_type, closing_reading, reading_date, userId } = req.body;

        if (!nozzle_name || closing_reading === undefined || !reading_date || !userId) {
            return res.status(400).json({ status: "Error", message: "Missing required fields!" });
        }

        const safeDate = formatDate(reading_date);
        const nextWorkingDate = getNextDate(safeDate);

        await client.query('BEGIN');

        // Fetch last closing reading BEFORE or ON the target date
        const lastResult = await client.query(
            'SELECT closing_reading FROM meter_readings WHERE nozzle_name = $1 AND user_id = $2 AND reading_date <= $3 ORDER BY id DESC LIMIT 1',
            [nozzle_name, userId, safeDate]
        );

        const opening_reading = lastResult.rows.length > 0 ? parseFloat(lastResult.rows[0].closing_reading) : 0.00;
        const liters_sold = Math.max(0, parseFloat(closing_reading) - opening_reading);

        // Insert new reading
        const insertQuery = `
            INSERT INTO meter_readings (nozzle_name, fuel_type, opening_reading, closing_reading, liters_sold, reading_date, user_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        `;
        await client.query(insertQuery, [nozzle_name, fuel_type, opening_reading, closing_reading, liters_sold, safeDate, userId]);

        // Ensure stock record & deduct stock
        await client.query(`
            INSERT INTO fuel_stocks (fuel_type, current_stock, user_id) 
            VALUES ($1, 0.00, $2)
            ON CONFLICT (fuel_type, user_id) DO NOTHING
        `, [fuel_type, userId]);

        await client.query(
            'UPDATE fuel_stocks SET current_stock = current_stock - $1 WHERE LOWER(TRIM(fuel_type)) = LOWER(TRIM($2)) AND user_id = $3',
            [liters_sold, fuel_type, userId]
        );

        await client.query('COMMIT');

        res.json({ 
            status: "Success", 
            message: "Reading logged and stock updated successfully!",
            currentDate: safeDate,
            nextWorkingDate: nextWorkingDate
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Add Reading Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    } finally {
        client.release();
    }
};

// 5. UPDATE TANK RECEIPTS (Auto Next Working Date Return)
exports.updateReceipt = async (req, res) => {
    const client = await db.connect();
    try {
        const { fuel_type, receipt_liters, total_amount, rate_per_liter, receipt_date, sheet_sr_no, userId } = req.body;

        if (!fuel_type || !receipt_liters || !userId) {
            return res.status(400).json({ status: "Error", message: "Missing receipt parameters!" });
        }

        const liters = parseFloat(receipt_liters) || 0;
        const entryDate = formatDate(receipt_date);
        const nextWorkingDate = getNextDate(entryDate);

        const srNo = sheet_sr_no || 1;
        const typeNormalized = fuel_type.trim().toLowerCase();

        let searchId = typeNormalized.includes('diesel') ? 'dl' : (typeNormalized.includes('super') || typeNormalized.includes('petrol') ? 'sp' : typeNormalized);
        let fuelSearchType = typeNormalized.includes('diesel') ? 'Diesel' : (typeNormalized.includes('super') || typeNormalized.includes('petrol') ? 'Super' : fuel_type);

        let calculatedTotal = 0;
        let finalRate = 0;

        if (total_amount !== undefined && total_amount !== null && total_amount !== '' && parseFloat(total_amount) > 0) {
            calculatedTotal = parseFloat(total_amount);
            finalRate = liters > 0 ? (calculatedTotal / liters) : 0;
        } else if (rate_per_liter && parseFloat(rate_per_liter) > 0) {
            finalRate = parseFloat(rate_per_liter);
            calculatedTotal = liters * finalRate;
        } else {
            const searchTerm = `%${fuelSearchType.toLowerCase()}%`;
            let rateResult = await client.query(
                `SELECT purchase_price, rate_per_litre FROM fuel_rates 
                 WHERE (LOWER(TRIM(product_type)) LIKE $1 
                    OR LOWER(TRIM(product_name)) LIKE $1 
                    OR LOWER(TRIM(specific_category)) LIKE $1)
                   AND (user_id = $2 OR user_id IS NULL)
                   AND rate_date <= $3
                 ORDER BY rate_date DESC, created_at DESC, id DESC LIMIT 1`,
                [searchTerm, userId, entryDate]
            );

            if (rateResult.rows.length === 0) {
                rateResult = await client.query(
                    `SELECT purchase_price, rate_per_litre FROM fuel_rates 
                     WHERE (LOWER(TRIM(product_type)) LIKE $1 
                        OR LOWER(TRIM(product_name)) LIKE $1)
                       AND rate_date <= $2
                     ORDER BY rate_date DESC, created_at DESC, id DESC LIMIT 1`,
                    [searchTerm, entryDate]
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
            ? `${typeNormalized.includes('diesel') ? 'diesel' : 'petrol'} stock (${liters}L @ ${formattedRate})`
            : `${typeNormalized.includes('diesel') ? 'diesel' : 'petrol'} stock (${liters}L)`;

        await client.query('BEGIN');

        await client.query(`
            INSERT INTO fuel_stocks (fuel_type, current_stock, opening_stock, receipt_stock, user_id) 
            VALUES ($1, 0.00, 0.00, 0.00, $2)
            ON CONFLICT (fuel_type, user_id) DO NOTHING
        `, [fuel_type, userId]);

        await client.query(`
            UPDATE fuel_stocks 
            SET current_stock = current_stock + $1,
                receipt_stock = receipt_stock + $1
            WHERE LOWER(TRIM(fuel_type)) = LOWER(TRIM($2)) AND user_id = $3
        `, [liters, fuel_type, userId]);

        await client.query(`
            INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id, sheet_sr_no)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        `, [searchId, calculatedTotal, 0.00, descriptionText, -calculatedTotal, entryDate, userId, srNo]);

        await client.query('COMMIT');

        res.json({ 
            status: "Success", 
            message: `Stock added (${liters} Ltrs). Rs. ${calculatedTotal} debited!`,
            data: { liters, rate: formattedRate, totalAmount: calculatedTotal },
            currentDate: entryDate,
            nextWorkingDate: nextWorkingDate
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Update Receipt Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    } finally {
        client.release();
    }
};

// 6. BATCH UPDATE LUBRICANTS & AUTO-RECORD (Auto Next Working Date Return)
exports.updateLubricants = async (req, res) => {
    const client = await db.connect();
    try {
        const { lubricant_sales, lubricant_receipts, receipt_date, sheet_sr_no, userId } = req.body;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        const entryDate = formatDate(receipt_date);
        const nextWorkingDate = getNextDate(entryDate);

        const srNo = sheet_sr_no || 1;
        const searchId = 'lub';

        await client.query('BEGIN');

        // 1. Process Receipts
        if (lubricant_receipts && lubricant_receipts.length > 0) {
            let totalReceiptAmount = 0;
            let receiptDetails = [];

            for (const item of lubricant_receipts) {
                const qty = parseInt(item.qty, 10) || 0;
                if (qty > 0) {
                    await client.query(`
                        INSERT INTO lubricant_stocks (item_name, current_stock, shift_sales_deduct, user_id) 
                        VALUES ($1, 0, 0, $2)
                        ON CONFLICT (item_name, user_id) DO NOTHING
                    `, [item.name, userId]);

                    await client.query(
                        'UPDATE lubricant_stocks SET current_stock = current_stock + $1 WHERE item_name = $2 AND user_id = $3',
                        [qty, item.name, userId]
                    );

                    let rate = parseFloat(item.price || item.rate || 0);
                    if (rate <= 0) {
                        const rateRes = await client.query(`
                            SELECT purchase_price, rate_per_litre FROM fuel_rates 
                            WHERE (LOWER(TRIM(product_name)) = LOWER(TRIM($1))
                               OR LOWER(TRIM(specific_category)) = LOWER(TRIM($1)))
                              AND (user_id = $2 OR user_id IS NULL)
                              AND rate_date <= $3
                            ORDER BY rate_date DESC, id DESC LIMIT 1
                        `, [item.name, userId, entryDate]);

                        if (rateRes.rows.length > 0) {
                            rate = parseFloat(rateRes.rows[0].purchase_price || rateRes.rows[0].rate_per_litre || 0);
                        }
                    }

                    const itemTotal = qty * rate;
                    totalReceiptAmount += itemTotal;
                    receiptDetails.push(`${qty} ${item.name} @ ${rate.toFixed(2)}`);
                }
            }

            if (receiptDetails.length > 0) {
                const description = `Mobiloil stock receipt (${receiptDetails.join(', ')})`;
                
                await client.query(`
                    INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id, sheet_sr_no)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                `, [searchId, totalReceiptAmount, 0.00, description, -totalReceiptAmount, entryDate, userId, srNo]);
            }
        }

        // 2. Process Sales
        if (lubricant_sales && lubricant_sales.length > 0) {
            for (const item of lubricant_sales) {
                const newDeductQty = parseInt(item.qty, 10) || 0;

                await client.query(`
                    INSERT INTO lubricant_stocks (item_name, current_stock, shift_sales_deduct, user_id) 
                    VALUES ($1, 0, 0, $2)
                    ON CONFLICT (item_name, user_id) DO NOTHING
                `, [item.name, userId]);

                const currentRes = await client.query(
                    'SELECT shift_sales_deduct FROM lubricant_stocks WHERE item_name = $1 AND user_id = $2',
                    [item.name, userId]
                );

                const previousDeductQty = currentRes.rows.length > 0 
                    ? (parseInt(currentRes.rows[0].shift_sales_deduct, 10) || 0) 
                    : 0;

                const diff = newDeductQty - previousDeductQty;

                if (diff !== 0) {
                    await client.query(`
                        UPDATE lubricant_stocks 
                        SET current_stock = current_stock - $1,
                            shift_sales_deduct = $2 
                        WHERE item_name = $3 AND user_id = $4
                    `, [diff, newDeductQty, item.name, userId]);
                }
            }
        }

        await client.query('COMMIT');

        res.json({ 
            status: "Success", 
            message: "Lubricant stock successfully update ho gaya hai!",
            currentDate: entryDate,
            nextWorkingDate: nextWorkingDate
        });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error("Update Lubricants Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    } finally {
        client.release();
    }
};