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

// 3. GET LUBRICANT STOCK (Filtered by user_id + Auto-Initialization)
exports.getLubricantStock = async (req, res) => {
    try {
        const userId = req.query.userId;
        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        let result = await db.query('SELECT item_name, current_stock FROM lubricant_stocks WHERE user_id = $1', [userId]);
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
            const retryResult = await db.query('SELECT item_name, current_stock FROM lubricant_stocks WHERE user_id = $1', [userId]);
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

        // 1️⃣ Scenario A: Agar Frontend se User ne Editable "total_amount" bheja ho
        if (total_amount !== undefined && total_amount !== null && total_amount !== '' && parseFloat(total_amount) > 0) {
            calculatedTotal = parseFloat(total_amount);
            finalRate = liters > 0 ? (calculatedTotal / liters) : 0;
        } 
        // 2️⃣ Scenario B: Agar rate_per_liter bheja gaya ho
        else if (rate_per_liter && parseFloat(rate_per_liter) > 0) {
            finalRate = parseFloat(rate_per_liter);
            calculatedTotal = liters * finalRate;
        } 
        // 3️⃣ Scenario C: Database se Latest Rate utha kar Calculate karein
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

        console.log(`[RECEIPT LOG] Product: ${fuelSearchType} | Liters: ${liters} | Effective Rate: ${formattedRate} | Final Total Debit: ${calculatedTotal}`);

        // Description Text
        const descriptionText = finalRate > 0 
            ? `${typeNormalized.includes('diesel') ? 'diesel' : 'petrol'} stock (${liters}L @ ${formattedRate})`
            : `${typeNormalized.includes('diesel') ? 'diesel' : 'petrol'} stock (${liters}L)`;

        // 1. Ensure target row exists in fuel_stocks
        await db.query(`
            INSERT INTO fuel_stocks (fuel_type, current_stock, opening_stock, receipt_stock, user_id) 
            VALUES ($1, 0.00, 0.00, 0.00, $2)
            ON CONFLICT (fuel_type, user_id) DO NOTHING
        `, [fuel_type, userId]);

        // 2. Update Stock Quantity in fuel_stocks
        await db.query(`
            UPDATE fuel_stocks 
            SET current_stock = current_stock + $1,
                receipt_stock = receipt_stock + $1
            WHERE LOWER(TRIM(fuel_type)) = LOWER(TRIM($2)) AND user_id = $3
        `, [liters, fuel_type, userId]);

        // 3. Insert Row in daily_sheets
        await db.query(`
            INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, total_balance, sheet_date, user_id, sheet_sr_no)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        `, [
            searchId,               // 'dl' ya 'sp'
            calculatedTotal,        // Debit amount (Editable / Calculated Total)
            0.00,                   // Credit vasooli
            descriptionText,        // Description
            -calculatedTotal,       // total_balance
            entryDate,              // Sheet Date
            userId,                 // User ID
            srNo                    // Sheet Sr No
        ]);

        res.json({ 
            status: "Success", 
            message: `Stock added (${liters} Ltrs). Rs. ${calculatedTotal} debited to daily sheet ('${searchId}')!`,
            data: {
                liters,
                rate: formattedRate,
                totalAmount: calculatedTotal
            }
        });
    } catch (error) {
        console.error("Update Receipt Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};
// 6. BATCH UPDATE LUBRICANTS (POST)
exports.updateLubricants = async (req, res) => {
    try {
        const { lubricant_sales, lubricant_receipts, userId } = req.body;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        // Process Receipts (Stock Add)
        if (lubricant_receipts && lubricant_receipts.length > 0) {
            for (const item of lubricant_receipts) {
                if (item.qty > 0) {
                    await db.query(`
                        INSERT INTO lubricant_stocks (item_name, current_stock, user_id) 
                        VALUES ($1, 0, $2)
                        ON CONFLICT (item_name, user_id) DO NOTHING
                    `, [item.name, userId]);

                    await db.query(
                        'UPDATE lubricant_stocks SET current_stock = current_stock + $1 WHERE item_name = $2 AND user_id = $3',
                        [parseInt(item.qty, 10), item.name, userId]
                    );
                }
            }
        }

        // Process Sales (Stock Deduct)
        if (lubricant_sales && lubricant_sales.length > 0) {
            for (const item of lubricant_sales) {
                if (item.qty > 0) {
                    await db.query(`
                        INSERT INTO lubricant_stocks (item_name, current_stock, user_id) 
                        VALUES ($1, 0, $2)
                        ON CONFLICT (item_name, user_id) DO NOTHING
                    `, [item.name, userId]);

                    await db.query(
                        'UPDATE lubricant_stocks SET current_stock = current_stock - $1 WHERE item_name = $2 AND user_id = $3',
                        [parseInt(item.qty, 10), item.name, userId]
                    );
                }
            }
        }

        res.json({ status: "Success", message: "Lubricant stock synced successfully!" });
    } catch (error) {
        console.error("Update Lubricants Error:", error);
        res.status(500).json({ status: "Error", message: error.message });
    }
};