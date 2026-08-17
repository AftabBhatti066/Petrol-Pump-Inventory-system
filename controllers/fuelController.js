const db = require('../config/db');

// Get all price history sorted by date (Filtered by user_id)
exports.getFuelRates = async (req, res) => {
    try {
        const userId = req.query.userId;
        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID missing!" });
        }

        // Fetching rates including purchase_price and calculated profit_per_liter
        const query = `
            SELECT id, rate_date, product_name, product_type, specific_category, 
                   rate_per_litre, purchase_price, user_id, created_at,
                   CAST((rate_per_litre - purchase_price) AS DECIMAL(10,2)) AS profit_per_liter
            FROM fuel_rates 
            WHERE user_id = $1 
            ORDER BY rate_date DESC, id DESC
        `;

        const { rows } = await db.query(query, [userId]);
        
        res.json({
            status: "Success",
            count: rows.length,
            data: rows
        });
    } catch (error) {
        console.error("Fetch Rates Error:", error);
        res.status(500).json({ status: "Error", message: "Database se rates fetch nahi ho sake." });
    }
};

// Insert or Update Fuel & Mobil Oil Rates (Includes purchase_price)
exports.updateFuelRate = async (req, res) => {
    try {
        const { rate_date, product_name, product_type, specific_category, rate_per_litre, purchase_price, userId } = req.body;

        if (!rate_date || !product_name || rate_per_litre === undefined || purchase_price === undefined || !userId) {
            return res.status(400).json({ status: "Error", message: "Tamam fields aur User ID required hain!" });
        }

        const query = `
            INSERT INTO fuel_rates (rate_date, product_name, product_type, specific_category, rate_per_litre, purchase_price, user_id) 
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        `;
        
        await db.query(query, [
            rate_date, 
            product_name, 
            product_type, 
            specific_category, 
            parseFloat(rate_per_litre), 
            parseFloat(purchase_price), 
            userId
        ]);

        res.json({
            status: "Success",
            message: `${product_name} ka rate successfully save ho gaya!`
        });
    } catch (error) {
        console.error("Update Rate Error:", error);
        res.status(500).json({ status: "Error", message: "Database saving error: " + error.message });
    }
};

// Delete Rate Entry
exports.deleteFuelRate = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.query.userId;

        if (!userId) {
            return res.status(400).json({ status: "Error", message: "User ID required for verification!" });
        }

        await db.query('DELETE FROM fuel_rates WHERE id = $1 AND user_id = $2', [id, userId]);

        res.json({
            status: "Success",
            message: "Price log entry successfully delete ho gayi!"
        });
    } catch (error) {
        console.error("Delete Rate Error:", error);
        res.status(500).json({ status: "Error", message: "Delete karne mein error aaya." });
    }
};