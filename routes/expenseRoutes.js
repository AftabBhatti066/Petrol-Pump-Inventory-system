const express = require('express');
const router = express.Router();
const db = require('../config/db');

// 1. Bulk Save Expenses
router.post('/save-bulk', async (req, res) => {
    try {
        const { userId, date, expenses } = req.body;

        if (!userId || !date || !expenses || !Array.isArray(expenses)) {
            return res.status(400).json({ status: "Error", message: "Required fields missing hain!" });
        }

        // Pehle purani date ke entries remove kar ke dobara sync karne ke liye (Optional, agar overwrite karna ho):
        // await db.query(`DELETE FROM expenses WHERE user_id = ? AND expense_date = ?`, [userId, date]);

        for (let exp of expenses) {
            await db.query(
                `INSERT INTO expenses (user_id, expense_date, title, description, amount) VALUES (?, ?, ?, ?, ?)`,
                [userId, date, exp.title, exp.description || '', exp.amount]
            );
        }

        return res.json({ status: "Success", message: "Expenses safalta se save ho gaye!" });

    } catch (error) {
        console.error("Expense Bulk Save Error:", error);
        return res.status(500).json({ status: "Error", message: error.message });
    }
});

// 2. Get Expenses By Date
router.get('/get-by-date', async (req, res) => {
    try {
        const { userId, date } = req.query;

        if (!userId || !date) {
            return res.status(400).json({ status: "Error", message: "User ID aur Date required hain!" });
        }

        const [rows] = await db.query(
            `SELECT * FROM expenses WHERE (user_id = ? OR user_id IS NULL) AND expense_date = ? ORDER BY id ASC`,
            [userId, date]
        );

        return res.json({ status: "Success", data: rows });

    } catch (error) {
        console.error("Fetch Expenses Error:", error);
        return res.status(500).json({ status: "Error", message: error.message });
    }
});

module.exports = router;