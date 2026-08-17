const mysqldump = require('mysqldump');

mysqldump({
    connection: {
        host: 'hayabusa.proxy.rlwy.net',
        port: 23897,
        user: 'root',
        password: 'lwUmbhqrohTcFrqyOLmduALuUkgphPMQ',
        database: 'railway',
    },
    dumpToFile: './live_client_backup.sql',
})
.then(() => console.log('? BACKUP SUCCESSFUL! File saved as live_client_backup.sql'))
.catch((err) => console.error('? Backup Error:', err));
