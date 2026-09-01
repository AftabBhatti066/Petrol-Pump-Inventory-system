const db = require('../config/db');

// Default Lubricants aur Fuels ki list taakay automatic system crash recovery ho sakay
const DEFAULT_LUBRICANTS = [
    'T 2 20Ltrs', 'Balize .75', 'Balize 1Ltrs', 'Cariant 3Ltrs',
    'Cariant 4ltrs', 'Deo 6000 4Ltrs', 'Deo 6000 10Ltrs',
    'Deo 8000 4Ltrs', 'Deo 8000 10Ltrs'
];

// Helper Function: Date YYYY-MM-DD Format karne ke liye
const formatDate = (dateInput) => {
    const d = dateInput ? new Date(dateInput) : new Date();
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
};

// 0. GET ALL FUEL RATES / PRICING
exports.getRates = async (req, res) => {
    try {
        const userId = req.query.userId;
        
        const query = `
            SELECT id, product_name, product_type, specific_category, 
                   rate_per_litre, purchase_price, rate_date, user_id
            FROM fuel_rates
            WHERE user_id = $1 OR user_id IS NULL
            ORDER BY id ASC
        `;

        const result = await db.query(query, [userId || null]);
        res.json({ status: "Success", data: result.rows });
    } catch (error) {
        console.error("Get Rates Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 1. GET ALL LATEST NOZZLE READINGS (Filtered by user_id)
exports.getAllReadings = async (req, res) => {
    try {
        const userId = req.query.userId;
        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        const query = `
            SELECT m1.* FROM meter_readings m1
            INNER JOIN (
                SELECT nozzle_name, MAX(id) as max_id 
                FROM meter_readings 
                WHERE user_id = $1 
                GROUP BY nozzle_name
            ) m2 ON m1.id = m2.max_id
            WHERE m1.user_id = $2
        `;

        const result = await db.query(query, [userId, userId]);
        res.json({ status: "Success", data: result.rows });
    } catch (error) {
        console.error("Get All Readings Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 2. GET FUEL TANK STOCK (Filtered by user_id + Auto-Initialization)
exports.getTankStock = async (req, res) => {
    try {
        const userId = req.query.userId;
        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        let result = await db.query('SELECT fuel_type, current_stock FROM fuel_stocks WHERE user_id = $1', [userId]);
        let rows = result.rows;

        // CRASH RECOVERY: Agar naye user ka fuel stock entry nahi hai
        if (rows.length === 0) {
            await db.query(`
                INSERT INTO fuel_stocks (fuel_type, current_stock, user_id) 
                VALUES ('Diesel', 0.00, $1), ('Super', 0.00, $2)
                ON CONFLICT (fuel_type, user_id) DO NOTHING
            `, [userId, userId]);

            const retryResult = await db.query('SELECT fuel_type, current_stock FROM fuel_stocks WHERE user_id = $1', [userId]);
            rows = retryResult.rows;
        }

        res.json({ status: "Success", data: rows });
    } catch (error) {
        console.error("Get Tank Stock Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 3. GET LUBRICANT STOCK (Filtered by user_id + Auto-Initialization + Pricing Support)
exports.getLubricantStock = async (req, res) => {
    try {
        const userId = req.query.userId;
        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        let query = `
            SELECT ls.item_name, ls.current_stock, 
                   COALESCE(fr.purchase_price, fr.rate_per_litre, 0) as purchase_price
            FROM lubricant_stocks ls
            LEFT JOIN LATERAL (
                SELECT purchase_price, rate_per_litre 
                FROM fuel_rates 
                WHERE LOWER(TRIM(product_name)) = LOWER(TRIM(ls.item_name))
                   OR LOWER(TRIM(specific_category)) = LOWER(TRIM(ls.item_name))
                ORDER BY id DESC LIMIT 1
            ) fr ON true
            WHERE ls.user_id = $1
        `;

        let result = await db.query(query, [userId]);
        let rows = result.rows;
        
        // CRASH RECOVERY: Automatic lubricant creation for new users
        if (rows.length === 0) {
            for (const item of DEFAULT_LUBRICANTS) {
                await db.query(`
                    INSERT INTO lubricant_stocks (item_name, current_stock, user_id) 
                    VALUES ($1, 0, $2)
                    ON CONFLICT (item_name, user_id) DO NOTHING
                `, [item, userId]);
            }
            const retryResult = await db.query(query, [userId]);
            rows = retryResult.rows;
        }

        res.json({ status: "Success", data: rows });
    } catch (error) {
        console.error("Get Lubricant Stock Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 4. ADD NEW METER READING (Safe Insert & Deduct)
exports.addReading = async (req, res) => {
    try {
        const { nozzle_name, fuel_type, closing_reading, reading_date, userId } = req.body;

        if (!nozzle_name || closing_reading === undefined || !reading_date || !userId) {
            return res.status(400).json({ status: "Error", message: "Missing required fields!" });
        }

        // 1. Purani closing reading fetch karein
        const lastResult = await db.query(
            'SELECT closing_reading FROM meter_readings WHERE nozzle_name = $1 AND user_id = $2 ORDER BY id DESC LIMIT 1',
            [nozzle_name, userId]
        );

        const opening_reading = lastResult.rows.length > 0 ? parseFloat(lastResult.rows[0].closing_reading) : 0.00;
        const liters_sold = Math.max(0, parseFloat(closing_reading) - opening_reading);

        // 2. Insert new reading record
        const insertQuery = `
            INSERT INTO meter_readings (nozzle_name, fuel_type, opening_reading, closing_reading, liters_sold, reading_date, user_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        `;
        await db.query(insertQuery, [nozzle_name, fuel_type, opening_reading, closing_reading, liters_sold, reading_date, userId]);

        // 3. Fuel Tank Stock safe check update
        await db.query(`
            INSERT INTO fuel_stocks (fuel_type, current_stock, user_id) 
            VALUES ($1, 0.00, $2)
            ON CONFLICT (fuel_type, user_id) DO NOTHING
        `, [fuel_type, userId]);

        await db.query(
            'UPDATE fuel_stocks SET current_stock = current_stock - $1 WHERE LOWER(TRIM(fuel_type)) = LOWER(TRIM($2)) AND user_id = $3',
            [liters_sold, fuel_type, userId]
        );

        res.json({ status: "Success", message: "Reading logged and stock updated successfully!" });
    } catch (error) {
        console.error("Add Reading Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 5. UPDATE TANK RECEIPTS (Editable Total & Auto Calculated Rate)
exports.updateReceipt = async (req, res) => {
    try {
        const { fuel_type, receipt_liters, total_amount, rate_per_liter, receipt_date, sheet_sr_no, userId } = req.body;

        if (!fuel_type || !receipt_liters || !userId) {
            return res.status(400).json({ status: "Error", message: "Missing receipt parameters!" });
        }

        const liters = parseFloat(receipt_liters) || 0;
        const entryDate = formatDate(receipt_date);
        const srNo = sheet_sr_no || 1;
        const typeNormalized = fuel_type.trim().toLowerCase();

        let searchId = '';
        let fuelSearchType = '';

        if (typeNormalized.includes('diesel')) {
            searchId = 'dl';
            fuelSearchType = 'Diesel';
        } else if (typeNormalized.includes('super') || typeNormalized.includes('petrol')) {
            searchId = 'sp';
            fuelSearchType = 'Super';
        } else {
            searchId = typeNormalized;
            fuelSearchType = fuel_type;
        }

        let calculatedTotal = 0;
        let finalRate = 0;

        // 1️⃣ Scenario A: Frontend se total_amount bheja gaya ho
        if (total_amount !== undefined && total_amount !== null && total_amount !== '' && parseFloat(total_amount) > 0) {
            calculatedTotal = parseFloat(total_amount);
            finalRate = liters > 0 ? (calculatedTotal / liters) : 0;
        } 
        // 2️⃣ Scenario B: rate_per_liter bheja gaya ho
        else if (rate_per_liter && parseFloat(rate_per_liter) > 0) {
            finalRate = parseFloat(rate_per_liter);
            calculatedTotal = liters * finalRate;
        } 
        // 3️⃣ Scenario C: Database se Latest Rate uthayen
        else {
            try {
                let rateResult = await db.query(
                    `SELECT purchase_price, rate_per_litre FROM fuel_rates 
                     WHERE (LOWER(TRIM(product_type)) LIKE LOWER($1) 
                        OR LOWER(TRIM(product_name)) LIKE LOWER($1) 
                        OR LOWER(TRIM(specific_category)) LIKE LOWER($1))
                       AND (user_id = $2 OR user_id IS NULL)
                     ORDER BY rate_date DESC, created_at DESC, id DESC LIMIT 1`,
                    [`%${fuelSearchType.toLowerCase()}%`, userId]
                );

                if (rateResult.rows.length === 0) {
                    rateResult = await db.query(
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
            } catch (rateErr) {
                console.error("DB Rate Fetch Error:", rateErr.message);
            }

            calculatedTotal = liters * finalRate;
        }

        const formattedRate = finalRate.toFixed(2);

        const descriptionText = finalRate > 0 
            ? `${typeNormalized.includes('diesel') ? 'diesel' : 'petrol'} stock (${liters}L @ ${formattedRate})`
            : `${typeNormalized.includes('diesel') ? 'diesel' : 'petrol'} stock (${liters}L)`;

        // Update Stock & Daily Sheet Entries
        await db.query(`
            INSERT INTO fuel_stocks (fuel_type, current_stock, opening_stock, receipt_stock, user_id) 
            VALUES ($1, 0.00, 0.00, 0.00, $2)
            ON CONFLICT (fuel_type, user_id) DO NOTHING
        `, [fuel_type, userId]);

        await db.query(`
            UPDATE fuel_stocks 
            SET current_stock = current_stock + $1,
                receipt_stock = receipt_stock + $1
            WHERE LOWER(TRIM(fuel_type)) = LOWER(TRIM($2)) AND user_id = $3
        `, [liters, fuel_type, userId]);

        await db.query(`
            INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id, sheet_sr_no)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        `, [
            searchId,
            calculatedTotal,
            0.00,
            descriptionText,
            -calculatedTotal,
            entryDate,
            userId,
            srNo
        ]);

        res.json({ 
            status: "Success", 
            message: `Stock added (${liters} Ltrs). Rs. ${calculatedTotal} debited!`,
            data: { liters, rate: formattedRate, totalAmount: calculatedTotal }
        });
    } catch (error) {
        console.error("Update Receipt Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};

// 6. BATCH UPDATE LUBRICANTS & AUTO-RECORD TO DAILY SHEET
exports.updateLubricants = async (req, res) => {
    try {
        const { lubricant_sales, lubricant_receipts, receipt_date, sheet_sr_no, userId } = req.body;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        const entryDate = formatDate(receipt_date);
        const srNo = sheet_sr_no || 1;
        const searchId = 'lub'; // Search ID set to 'lub'

        // -------------------------------------------------------------
        // 1. PROCESS RECEIPTS (Stock In -> Debit Entry in Daily Sheet)
        // -------------------------------------------------------------
        if (lubricant_receipts && lubricant_receipts.length > 0) {
            let totalReceiptAmount = 0;
            let receiptDetails = [];

            for (const item of lubricant_receipts) {
                const qty = parseInt(item.qty, 10) || 0;
                if (qty > 0) {
                    await db.query(`
                        INSERT INTO lubricant_stocks (item_name, current_stock, shift_sales_deduct, user_id) 
                        VALUES ($1, 0, 0, $2)
                        ON CONFLICT (item_name, user_id) DO NOTHING
                    `, [item.name, userId]);

                    await db.query(
                        'UPDATE lubricant_stocks SET current_stock = current_stock + $1 WHERE item_name = $2 AND user_id = $3',
                        [qty, item.name, userId]
                    );

                    let rate = parseFloat(item.price || item.rate || 0);
                    if (rate <= 0) {
                        const rateRes = await db.query(`
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
                    totalReceiptAmount += itemTotal;
                    
                    const formattedRate = rate.toFixed(2);
                    receiptDetails.push(`${qty} ${item.name} @ ${formattedRate}`);
                }
            }

            if (receiptDetails.length > 0) {
                const description = `Mobiloil stock receipt (${receiptDetails.join(', ')})`;
                
                await db.query(`
                    INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id, sheet_sr_no)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                `, [
                    searchId,
                    totalReceiptAmount,
                    0.00,
                    description,
                    -totalReceiptAmount,
                    entryDate,
                    userId,
                    srNo
                ]);
            }
        }

        // -------------------------------------------------------------
        // 2. PROCESS SALES (Stock Out -> Credit Entry in Daily Sheet & Update shift_sales_deduct)
        // -------------------------------------------------------------
        if (lubricant_sales && lubricant_sales.length > 0) {
            let totalSalesAmount = 0;
            let salesDetails = [];

            for (const item of lubricant_sales) {
                const qty = parseInt(item.qty, 10) || 0;
                if (qty > 0) {
                    await db.query(`
                        INSERT INTO lubricant_stocks (item_name, current_stock, shift_sales_deduct, user_id) 
                        VALUES ($1, 0, 0, $2)
                        ON CONFLICT (item_name, user_id) DO NOTHING
                    `, [item.name, userId]);

                    // Update current_stock and shift_sales_deduct for profit reporting
                    await db.query(
                        `UPDATE lubricant_stocks 
                         SET current_stock = current_stock - $1,
                             shift_sales_deduct = COALESCE(shift_sales_deduct, 0) + $1 
                         WHERE item_name = $2 AND user_id = $3`,
                        [qty, item.name, userId]
                    );

                    let rate = parseFloat(item.price || item.rate || 0);
                    if (rate <= 0) {
                        const rateRes = await db.query(`
                            SELECT rate_per_litre, purchase_price FROM fuel_rates 
                            WHERE LOWER(TRIM(product_name)) = LOWER(TRIM($1))
                               OR LOWER(TRIM(specific_category)) = LOWER(TRIM($1))
                            ORDER BY id DESC LIMIT 1
                        `, [item.name]);

                        if (rateRes.rows.length > 0) {
                            rate = parseFloat(rateRes.rows[0].rate_per_litre || rateRes.rows[0].purchase_price || 0);
                        }
                    }

                    const itemTotal = qty * rate;
                    totalSalesAmount += itemTotal;
                    
                    const formattedRate = rate.toFixed(2);
                    salesDetails.push(`${qty} ${item.name} @ ${formattedRate}`);
                }
            }

            if (salesDetails.length > 0) {
                const description = `Mobiloil sale (${salesDetails.join(', ')})`;
                
                await db.query(`
                    INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id, sheet_sr_no)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                `, [
                    searchId,
                    0.00,
                    totalSalesAmount,
                    description,
                    totalSalesAmount,
                    entryDate,
                    userId,
                    srNo
                ]);
            }
        }

        res.json({ status: "Success", message: "Lubricant stock aur Daily Sheet entry successfully update ho gayi hain!" });
    } catch (error) {
        console.error("Update Lubricants Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};