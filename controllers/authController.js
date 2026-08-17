// Centralized DB config import karein
const db = require('../config/db'); 
const bcrypt = require('bcrypt');

// 🚀 Helper Function: Sabhi 9 Static Customers Add karne ke liye
const ensureStaticCustomers = async (userId) => {
    const staticCustomers = [
        { customer_name: 'Super Khata', search_id: 'sp' },
        { customer_name: 'Diesel Khata', search_id: 'dl' },
        { customer_name: 'mufariq ikhrajat', search_id: 'mi' },
        { customer_name: 'innum', search_id: 'i' },
        { customer_name: 'bill bajli', search_id: 'bb' },
        { customer_name: 'petrol moter cycle', search_id: 'pm' },
        { customer_name: 'raent gari', search_id: 'rg' },
        { customer_name: 'salary', search_id: 's' },
        { customer_name: 'less', search_id: 'l' }
    ];

    for (const customer of staticCustomers) {
        // Postgres Syntax: $1, $2 placeholders
        const existing = await db.query(
            'SELECT id FROM daily_customers WHERE user_id = $1 AND search_id = $2',
            [userId, customer.search_id]
        );

        if (existing.rows.length === 0) {
            // Agar nahi hai to insert kar do
            await db.query(
                'INSERT INTO daily_customers (customer_name, search_id, user_id) VALUES ($1, $2, $3)',
                [customer.customer_name, customer.search_id, userId]
            );
        }
    }
};

// 1. Register Function
const registerUser = async (req, res) => {
    const { fullName, username, password } = req.body;
    console.log("Register Request Received:", req.body);

    if (!fullName || !username || !password) {
        return res.status(400).json({ status: "Error", message: "Tamam fields required hain!" });
    }

    try {
        const existing = await db.query('SELECT id FROM users WHERE username = $1', [username]);

        if (existing.rows.length > 0) {
            return res.status(400).json({ status: "Error", message: "Yeh Username pehle se maujood hai!" });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        // RETURNING id se inserted user id milti hai Postgres mein
        const result = await db.query(
            'INSERT INTO users (full_name, username, password, role) VALUES ($1, $2, $3, $4) RETURNING id',
            [fullName, username, hashedPassword, 'Manager']
        );

        const newUserId = result.rows[0].id;

        // 🚀 A. Automatic Fuel Stock Initialize karna ($1, $2)
        const fuelQuery = `
            INSERT INTO fuel_stocks (fuel_type, current_stock, user_id) 
            VALUES 
            ('Diesel', 0.00, $1),
            ('Super', 0.00, $2)
        `;
        await db.query(fuelQuery, [newUserId, newUserId]);

        // 🚀 B. Automatic Lubricant Stock Initialize karna (All 9 items)
        const lubricantQuery = `
            INSERT INTO lubricant_stocks (item_name, current_stock, user_id) 
            VALUES 
            ('T 2 20Ltrs', 0, $1),
            ('Balize .75', 0, $2),
            ('Balize 1Ltrs', 0, $3),
            ('Cariant 3Ltrs', 0, $4),
            ('Cariant 4ltrs', 0, $5),
            ('Deo 6000 4Ltrs', 0, $6),
            ('Deo 6000 10Ltrs', 0, $7),
            ('Deo 8000 4Ltrs', 0, $8),
            ('Deo 8000 10Ltrs', 0, $9)
        `;
        await db.query(lubricantQuery, [
            newUserId, newUserId, newUserId, 
            newUserId, newUserId, newUserId, 
            newUserId, newUserId, newUserId
        ]);

        // 🚀 C. Automatic Static Customers Create karna
        await ensureStaticCustomers(newUserId);

        console.log(`Stocks and All 9 Static Customers initialized automatically for User ID: ${newUserId}`);

        return res.json({ status: "Success", message: "Manager account, default stocks aur static khatay create ho gaye hain!" });
    } catch (err) {
        console.error("Database Insert Error:", err);
        return res.status(500).json({ status: "Error", message: "Database Error: " + err.message });
    }
};

// 2. Login Function
const loginUser = async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ status: "Error", message: "Username aur Password dono zaroori hain!" });
    }

    try {
        const result = await db.query('SELECT * FROM users WHERE username = $1', [username]);

        if (result.rows.length === 0) {
            return res.status(401).json({ status: "Error", message: "Ghalat Username ya Password hai!" });
        }

        const user = result.rows[0];
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ status: "Error", message: "Ghalat Username ya Password hai!" });
        }

        // 🚀 Automatic check runs so every user gets all 9 static accounts
        await ensureStaticCustomers(user.id);

        return res.json({
            status: "Success",
            message: "Login successful",
            user: { id: user.id, name: user.full_name, role: user.role }
        });
    } catch (err) {
        console.error("Login Error:", err);
        return res.status(500).json({ status: "Error", message: "Database Error: " + err.message });
    }
};

module.exports = {
    registerUser,
    loginUser
};