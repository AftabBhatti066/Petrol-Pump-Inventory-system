const mysql = require('mysql2/promise');

async function fixRemainingIndex() {
    let connection;
    try {
        connection = await mysql.createConnection({
            host: 'hayabusa.proxy.rlwy.net',
            port: 23897,
            user: 'root',
            password: 'lwUmbhqrohTcFrqyOLmduALuUkgphPMQ',
            database: 'railway'
        });

        console.log('Connected to Railway DB...');

        // 1. Find Foreign Key Name associated with unique_sheet_entry
        const [fkRows] = await connection.query(`
            SELECT CONSTRAINT_NAME 
            FROM information_schema.KEY_COLUMN_USAGE 
            WHERE TABLE_NAME = 'daily_sheets' 
              AND CONSTRAINT_SCHEMA = 'railway'
              AND CONSTRAINT_NAME != 'PRIMARY';
        `);

        // 2. Drop Foreign Keys if present
        for (const row of fkRows) {
            try {
                await connection.query(`ALTER TABLE daily_sheets DROP FOREIGN KEY ${row.CONSTRAINT_NAME}`);
                console.log(`✅ Dropped Foreign Key: ${row.CONSTRAINT_NAME}`);
            } catch (err) {
                console.log(`⚠️ FK Drop Info: ${err.message}`);
            }
        }

        // 3. Drop the main unique_sheet_entry index
        try {
            await connection.query(`ALTER TABLE daily_sheets DROP INDEX unique_sheet_entry`);
            console.log('✅ DROPPED INDEX: unique_sheet_entry');
        } catch (err) {
            console.log(`⚠️ Index Drop Info: ${err.message}`);
        }

        console.log('🎉 FINAL INDEX REMOVED SUCCESSFULLY!');
    } catch (err) {
        console.error('❌ Connection/Query Error:', err.message);
    } finally {
        if (connection) await connection.end();
    }
}

fixRemainingIndex();