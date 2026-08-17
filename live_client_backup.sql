/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: account_types
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `account_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `type_name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE = InnoDB AUTO_INCREMENT = 5 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: chart_of_accounts
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `chart_of_accounts` (
  `account_id` int NOT NULL AUTO_INCREMENT,
  `account_name` varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  `account_type_id` int DEFAULT NULL,
  `opening_balance` decimal(15, 2) DEFAULT '0.00',
  `balance_type` enum('DEBIT', 'CREDIT') COLLATE utf8mb4_general_ci DEFAULT 'DEBIT',
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`account_id`),
  KEY `account_type_id` (`account_type_id`),
  CONSTRAINT `chart_of_accounts_ibfk_1` FOREIGN KEY (`account_type_id`) REFERENCES `account_types` (`id`)
) ENGINE = InnoDB AUTO_INCREMENT = 2 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: credit_ledgers
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `credit_ledgers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `gari_number` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `driver_name` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `product` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `litres` decimal(12, 2) NOT NULL,
  `rate_pkr` decimal(10, 2) NOT NULL,
  `total_amount` decimal(12, 2) NOT NULL,
  `payment_type` varchar(20) COLLATE utf8mb4_general_ci DEFAULT 'CREDIT',
  `entry_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `gari_number` (`gari_number`),
  KEY `fk_ledger_user` (`user_id`),
  CONSTRAINT `fk_ledger_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 100 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: daily_customers
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `daily_customers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `search_id` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_customer` (`user_id`, `search_id`),
  UNIQUE KEY `unique_user_search` (`user_id`, `search_id`),
  UNIQUE KEY `unique_customer_per_user` (`user_id`, `search_id`),
  CONSTRAINT `fk_customer_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 24882 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: daily_sheets
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `daily_sheets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `search_id` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `debit_udhaar` decimal(12, 2) DEFAULT '0.00',
  `credit_vasooli` decimal(12, 2) DEFAULT '0.00',
  `description` text COLLATE utf8mb4_general_ci,
  `total_balance` decimal(12, 2) DEFAULT '0.00',
  `sheet_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_sheet_entry` (`user_id`, `search_id`, `sheet_date`),
  UNIQUE KEY `unique_user_daily_entry` (`user_id`, `search_id`, `sheet_date`),
  UNIQUE KEY `unique_user_sheet` (`user_id`, `search_id`, `sheet_date`),
  UNIQUE KEY `unique_sheet_entry_per_user` (`user_id`, `search_id`, `sheet_date`),
  UNIQUE KEY `unique_daily_entry` (`search_id`, `sheet_date`, `user_id`),
  CONSTRAINT `fk_sheets_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 24500 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: expenses
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `expenses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `expense_date` date NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `amount` decimal(12, 2) NOT NULL DEFAULT '0.00',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `expenses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 100 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: fuel_rates
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `fuel_rates` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `product_type` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `specific_category` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `rate_per_litre` decimal(10, 2) NOT NULL,
  `purchase_price` decimal(10, 2) NOT NULL DEFAULT '0.00',
  `rate_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rates_user` (`user_id`),
  CONSTRAINT `fk_rates_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 13 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: fuel_stocks
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `fuel_stocks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `fuel_type` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `current_stock` decimal(15, 2) DEFAULT '0.00',
  `opening_stock` decimal(12, 2) DEFAULT '0.00',
  `receipt_stock` decimal(12, 2) DEFAULT '0.00',
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_fuel` (`user_id`, `fuel_type`)
) ENGINE = InnoDB AUTO_INCREMENT = 57 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: lubricant_stocks
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `lubricant_stocks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `item_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `current_stock` int DEFAULT '0',
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_lubricant` (`user_id`, `item_name`)
) ENGINE = InnoDB AUTO_INCREMENT = 109 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: meter_readings
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `meter_readings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nozzle_name` enum(
  'Diesel (N1)',
  'Diesel (N2)',
  'Diesel (N3)',
  'Diesel (N4)',
  'Super (N1)',
  'Super (N2)'
  ) COLLATE utf8mb4_general_ci NOT NULL,
  `fuel_type` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `opening_reading` decimal(15, 2) NOT NULL,
  `closing_reading` decimal(15, 2) NOT NULL,
  `liters_sold` decimal(15, 2) NOT NULL,
  `reading_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_meter_user` (`user_id`),
  CONSTRAINT `fk_meter_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 100 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: users
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `username` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `role` varchar(20) COLLATE utf8mb4_general_ci DEFAULT 'Manager',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE = InnoDB AUTO_INCREMENT = 12 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# SCHEMA DUMP FOR TABLE: vehicles
# ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `vehicles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `gari_number` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `owner_name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `address` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_vehicle_user_gari` (`user_id`, `gari_number`),
  UNIQUE KEY `unique_user_gari` (`gari_number`, `user_id`),
  CONSTRAINT `fk_vehicles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 100 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci;

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: account_types
# ------------------------------------------------------------

INSERT INTO
  `account_types` (`id`, `type_name`)
VALUES
  (1, 'Customer');
INSERT INTO
  `account_types` (`id`, `type_name`)
VALUES
  (2, 'Supplier');
INSERT INTO
  `account_types` (`id`, `type_name`)
VALUES
  (3, 'Bank');
INSERT INTO
  `account_types` (`id`, `type_name`)
VALUES
  (4, 'Owner Capital');

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: chart_of_accounts
# ------------------------------------------------------------

INSERT INTO
  `chart_of_accounts` (
    `account_id`,
    `account_name`,
    `account_type_id`,
    `opening_balance`,
    `balance_type`,
    `user_id`
  )
VALUES
  (1, 'Jahangir', 4, 50000.00, 'DEBIT', 4);

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: credit_ledgers
# ------------------------------------------------------------

INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2,
    'fsd-3344',
    'ali',
    'Diesel (HSD)',
    10.00,
    100.00,
    1000.00,
    'CREDIT',
    '2026-07-17',
    '2026-07-17 05:45:51',
    NULL
  );
INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3,
    '3344',
    'aftab',
    'Diesel (HSD)',
    10.00,
    100.00,
    1000.00,
    'CREDIT',
    '2026-07-17',
    '2026-07-17 06:03:46',
    NULL
  );
INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5,
    'fsd-3344',
    'ali',
    'Diesel (HSD)',
    22.00,
    100.00,
    2200.00,
    'CREDIT',
    '2026-07-17',
    '2026-07-17 06:10:31',
    NULL
  );
INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6,
    'fsd-3346',
    'ali',
    'Diesel (HSD)',
    30.00,
    300.00,
    9000.00,
    'CREDIT',
    '2026-07-19',
    '2026-07-19 06:28:04',
    1
  );
INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7,
    'fsd-3344',
    'ALI',
    'Diesel (HSD)',
    30.00,
    300.00,
    9000.00,
    'CREDIT',
    '2026-07-19',
    '2026-07-19 06:45:05',
    1
  );
INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8,
    'fsd-3344',
    'ali',
    'Diesel (HSD)',
    30.00,
    300.00,
    9000.00,
    'CREDIT',
    '2026-07-19',
    '2026-07-19 06:47:33',
    4
  );
INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9,
    'fsd-3344',
    'ali',
    'Diesel (HSD)',
    300.00,
    300.00,
    90000.00,
    'CREDIT',
    '2026-07-19',
    '2026-07-19 10:05:13',
    5
  );
INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10,
    'fsd-3345',
    'ali',
    'Diesel (HSD)',
    30.00,
    322.00,
    9660.00,
    'CREDIT',
    '2026-08-01',
    '2026-08-01 17:40:58',
    4
  );
INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11,
    'fsd-3344',
    'Hassan Sardar',
    'Balize .75',
    10.00,
    250.00,
    2500.00,
    'CREDIT',
    '2026-08-02',
    '2026-08-02 06:15:22',
    4
  );
INSERT INTO
  `credit_ledgers` (
    `id`,
    `gari_number`,
    `driver_name`,
    `product`,
    `litres`,
    `rate_pkr`,
    `total_amount`,
    `payment_type`,
    `entry_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12,
    'fsd-3344',
    'Hassan Sardar',
    'Cash Vasooli',
    0.00,
    0.00,
    5000.00,
    'VASOOLI',
    '2026-08-02',
    '2026-08-02 06:37:05',
    4
  );

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: daily_customers
# ------------------------------------------------------------

INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    19,
    'Mubashar Hassan Mulazam',
    'mh',
    '2026-07-19 06:17:38',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    20,
    'mubashar hassan',
    'mh',
    '2026-07-19 06:18:56',
    4
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (21, 'mubashar', 'mh', '2026-07-19 10:04:18', 5);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (23, 'mubashar', 'mh', '2026-07-20 21:24:15', 9);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (24, 'aftab', 'aa', '2026-08-01 17:45:47', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (25, 'ali', 'a', '2026-08-01 18:01:42', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (50, 'jahangir', 'j', '2026-08-02 07:39:09', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (55, 'Aslam', 'as', '2026-08-02 07:45:04', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    61,
    'mufariq ikhrajat',
    'mi',
    '2026-08-03 11:29:50',
    4
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (62, 'innum', 'i', '2026-08-03 11:30:07', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (63, 'bill bajli', 'bb', '2026-08-03 11:30:40', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    64,
    'petrol moter cycle',
    'pm',
    '2026-08-03 11:30:58',
    4
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (65, 'raent gari', 'rg', '2026-08-03 11:31:38', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (66, 'salary', 's', '2026-08-03 11:32:10', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (67, 'less', 'l', '2026-08-03 11:48:05', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (86, 'ley-5544', '5544', '2026-08-05 04:49:48', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (116, 'bill bijli', 'bb', '2026-08-05 08:43:14', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (120, 'faizan hassan', 'fh', '2026-08-05 08:53:10', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (134, 'sufyan', 'su', '2026-08-05 10:34:38', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    171,
    'mufariq ikhrajat',
    'mi',
    '2026-08-06 04:31:22',
    2
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (185, 'aftab', 'a', '2026-08-06 05:42:20', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    206,
    'Super Khata',
    'super',
    '2026-08-08 05:18:07',
    2
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    207,
    'Diesel Khata',
    'diesel',
    '2026-08-08 05:18:08',
    2
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (208, 'innum', 'i', '2026-08-08 05:18:09', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    209,
    'petrol moter cycle',
    'pm',
    '2026-08-08 05:18:09',
    2
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (210, 'raent gari', 'rg', '2026-08-08 05:18:10', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (211, 'salary', 's', '2026-08-08 05:18:11', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (212, 'less', 'l', '2026-08-08 05:18:11', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    213,
    'Super Khata',
    'super',
    '2026-08-08 05:19:00',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    214,
    'Diesel Khata',
    'diesel',
    '2026-08-08 05:19:01',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    215,
    'mufariq ikhrajat',
    'mi',
    '2026-08-08 05:19:01',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (216, 'innum', 'i', '2026-08-08 05:19:02', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (217, 'Babu Bhobhra', 'bbh', '2026-08-08 05:19:02', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    218,
    'petrol moter cycle',
    'pm',
    '2026-08-08 05:19:03',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (219, 'raent gari', 'rg', '2026-08-08 05:19:04', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (220, 'salary', 's', '2026-08-08 05:19:04', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (221, 'less', 'l', '2026-08-08 05:19:05', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (222, 'Super Khata', 'sp', '2026-08-08 05:43:35', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (223, 'Diesel Khata', 'dl', '2026-08-08 05:43:35', 2);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (224, 'Super Khata', 'sp', '2026-08-09 12:12:28', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (225, 'Diesel Khata', 'dl', '2026-08-09 12:12:28', 4);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    226,
    'Sarfraz Parr Ahmad',
    'sp',
    '2026-08-09 12:42:30',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (227, 'Diesel Khata', 'dl', '2026-08-09 12:42:30', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    231,
    'ubl sargodha',
    'ubls',
    '2026-08-10 05:16:17',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    233,
    'ubl sukheke',
    'ublsm',
    '2026-08-10 05:17:18',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    236,
    'attock oil dipo',
    'ao',
    '2026-08-10 05:22:30',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    240,
    'Muhammad Jahangir khan bhattie',
    'mj',
    '2026-08-10 05:23:12',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    245,
    'Muhammad Jahangir kahn bhatti 2',
    'mj2',
    '2026-08-10 05:24:46',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (251, 'Attock wakeel', 'aw', '2026-08-10 05:25:30', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (258, 'c2144', '2144', '2026-08-10 05:26:36', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    266,
    'Rana Khalid Thatha Paroothyan',
    'rk',
    '2026-08-10 05:27:13',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    294,
    '573 zegham bhatti',
    '573',
    '2026-08-10 05:28:31',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    306,
    '7053 Ahmad Ali',
    '7053',
    '2026-08-10 05:29:19',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    319,
    '1185 Haneef Odd',
    '1185',
    '2026-08-10 05:29:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (333, '7098 Ramzan', '7098', '2026-08-10 05:30:32', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (348, '5225 Imran', '5225', '2026-08-10 05:31:02', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    364,
    '605 Faisal Imran',
    '605',
    '2026-08-10 05:31:35',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (381, '9856 Qaisar', '9856', '2026-08-10 05:32:22', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    399,
    '1266 Dildaar Hussain',
    '1266',
    '2026-08-10 05:32:57',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    418,
    '5100 Sana Ullah',
    '5100',
    '2026-08-10 05:33:37',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    438,
    '239 Shabeer Lohar',
    '239',
    '2026-08-10 05:34:07',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    459,
    '8301 Asif Bhatti',
    '8301',
    '2026-08-10 05:34:41',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    481,
    '6469 Parvaiz Chaddhar',
    '6469',
    '2026-08-10 05:35:19',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    482,
    '7459 Parvaiz Chaddhar',
    '7459',
    '2026-08-10 05:37:59',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    505,
    '972 Parvaiz Chaddhar',
    '972',
    '2026-08-10 05:39:27',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    530,
    '789 Parvaiz Chaddhar',
    '789',
    '2026-08-10 05:39:57',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    580,
    '4837 Malik Qamar',
    '4837',
    '2026-08-10 05:43:37',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    606,
    '359 Abid Ali Bhobhra',
    '359',
    '2026-08-10 05:45:01',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    633,
    '057 Irfan Ullah',
    '057',
    '2026-08-10 05:45:49',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    661,
    'Muhammad alyas',
    'ma',
    '2026-08-10 05:46:40',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    690,
    'Amjad SO Ashraf',
    'aa',
    '2026-08-10 05:47:30',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    720,
    'Iftakhar c\\s  Bhobhra',
    'ics',
    '2026-08-10 05:48:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    751,
    'Rabnawaz c\\s Chowki',
    'rcs',
    '2026-08-10 05:49:42',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    783,
    'Rehmat c\\s Chowki',
    'rcsc',
    '2026-08-10 05:50:59',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    816,
    'Razan Abbas c\\s Bahuman',
    'racs',
    '2026-08-10 05:51:45',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    850,
    'Riasat Thatha Bhattian',
    'rt',
    '2026-08-10 05:52:15',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    885,
    'Mazhar Abbas c\\s Bahuman',
    'mcs',
    '2026-08-10 05:52:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    921,
    'Kharal c\\s Bahuman',
    'kcs',
    '2026-08-10 05:53:41',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    958,
    'Sultan c\\s Chowki',
    'scs',
    '2026-08-10 05:54:14',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    996,
    'Qais c\\s Bahuman',
    'qcs',
    '2026-08-10 05:54:44',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (1035, 'Khokhar cs', 'kcsp', '2026-08-10 05:55:30', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1075,
    'Asaf c\\ss Chowki',
    'acs',
    '2026-08-10 05:56:03',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1116,
    'Tariq Jawaid Parr Ahmad',
    'tj',
    '2026-08-10 05:56:41',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1158,
    'Waheed c\\s Bahuman',
    'wcs',
    '2026-08-10 05:57:27',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1201,
    'Punjab Trader',
    'pt',
    '2026-08-10 05:57:51',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1245,
    'New Star Gudds',
    'ns',
    '2026-08-10 05:58:27',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1290,
    'Rana Arshad Thatha Paroothyan',
    'ra',
    '2026-08-10 05:58:56',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1336,
    'Allah Ditta Thatha Bhattian',
    'ad',
    '2026-08-10 05:59:32',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1383,
    'Allah Ditta Parr Ahmad',
    'adp',
    '2026-08-10 06:00:12',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1431,
    'Asghar Ali Barhak Pur',
    'aab',
    '2026-08-10 06:00:53',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1432,
    'Ahmad Shair Thatha Bhattian',
    'aat',
    '2026-08-10 06:01:31',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1433,
    'Arshad Fouji Driver',
    'af',
    '2026-08-10 06:02:16',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1484,
    'Rana Ajmal Thatha Paroothyan',
    'rat',
    '2026-08-10 06:02:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1536,
    'Ishaq SO Fouji Muhammad Ali',
    'im',
    '2026-08-10 06:03:39',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1589,
    'Akhtar Khan Hotel',
    'ah',
    '2026-08-10 06:04:08',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1590,
    'Iqbal Hussain Bhatti Piranyki',
    'ih',
    '2026-08-10 06:07:33',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1645,
    'Ashraf Thatha Bhattian',
    'at',
    '2026-08-10 06:08:12',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1701,
    'Altaf SO Riaz',
    'ar',
    '2026-08-10 06:09:24',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1758,
    'Haji Asghar Thatha Bhattian',
    'ha',
    '2026-08-10 06:10:12',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1816,
    'Ahtisham Bhobhra',
    'ab',
    '2026-08-10 06:11:04',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1935,
    'Bilal SO Riaz Parr Ahmad',
    'br',
    '2026-08-10 06:12:25',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1996,
    'Tanvir Ahmad Mithu',
    'tam',
    '2026-08-10 06:13:28',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2058,
    'Jumma Khan Pathan',
    'jk',
    '2026-08-10 06:16:32',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2121,
    'Jahangir Chaddhar Rah Bhobhra',
    'jc',
    '2026-08-10 06:17:19',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2185,
    'Javed c\\s Bahuman',
    'jcs',
    '2026-08-10 06:18:09',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2186,
    'Habib Sultab Gujjar',
    'hs',
    '2026-08-10 06:18:39',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2187,
    'Dilshad c\\s',
    'dcs',
    '2026-08-10 06:19:11',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2254,
    'Khaild SO Ameer',
    'ka',
    '2026-08-10 06:19:59',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2323,
    'Rizwan SO Irshad Bhobhra',
    'ri',
    '2026-08-10 06:22:21',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (2324, 'Zohaib c\\s', 'zcs', '2026-08-10 06:23:03', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2325,
    'Sajid Nazeer c\\s Bahuman',
    'sncs',
    '2026-08-10 06:25:07',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (2956, 'Sajad Mughal', 'sm', '2026-08-10 06:33:20', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3029,
    'Shoaib Parr Ahmad',
    'spa',
    '2026-08-10 06:34:04',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3249,
    'Shahid Bhatti',
    'sb',
    '2026-08-10 06:36:18',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3324,
    'Shaid Thatha Paroothyan',
    'st',
    '2026-08-10 06:36:53',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3325,
    'shawaiz hargan',
    'sh',
    '2026-08-10 06:37:24',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3402,
    'Shoaib SO Arif Bhobhra',
    'sab',
    '2026-08-10 06:38:11',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3480,
    'Zaigham SO Bashir Bhobhra',
    'zb',
    '2026-08-10 06:38:50',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3719,
    'imran mochi thatha',
    'imt',
    '2026-08-10 06:41:28',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3800,
    'Abdur Raouf Oil Agency',
    'aro',
    '2026-08-10 06:42:44',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3881,
    'Adil SO Mazhar Bhobhra',
    'amb',
    '2026-08-10 06:43:46',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3963,
    'Abid SO Zakir Bhobhra',
    'azb',
    '2026-08-10 06:44:32',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3964,
    'Dr Imran Bhobhra',
    'di',
    '2026-08-10 06:45:13',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4048,
    'Usman Wirk Kharal Wala',
    'uw',
    '2026-08-10 06:46:31',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4049,
    'Ansar Abbas piranyki',
    'aap',
    '2026-08-10 06:47:00',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4135,
    'Mussawar SO Aslam Parr Lakhan',
    'map',
    '2026-08-10 06:47:55',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4222,
    'Abdur Razaq Chaddar',
    'arc',
    '2026-08-10 06:48:40',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4310,
    'Araf Odd Jhall Mona',
    'aoj',
    '2026-08-10 06:49:19',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4399,
    'Ghulam Sarwar Sipr',
    'gsp',
    '2026-08-10 06:55:03',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4489,
    'Farooq Bhatti Piranyki',
    'fbp',
    '2026-08-10 06:55:59',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4580,
    'Faisal Amin Bhatti Piranyki',
    'fab',
    '2026-08-10 06:56:32',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4763,
    'Qamar SO Bagga',
    'qb',
    '2026-08-10 06:57:20',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4856,
    'Kashif SO Bashir Piranyki',
    'kbp',
    '2026-08-10 06:58:29',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4857,
    'Muhammad Nawaz SO Nazir',
    'mn',
    '2026-08-10 06:59:23',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5332,
    'Mussawar SO Aslam Parr Lakhan',
    'mpl',
    '2026-08-10 07:01:59',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5428,
    'Mushtaq Bhatti Piranyki',
    'mbp',
    '2026-08-10 07:03:10',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5525,
    'Zain ALi SO Nawaz',
    'zan',
    '2026-08-10 07:03:47',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5623,
    'Mubashar Hassan SO Manzoor',
    'mhm',
    '2026-08-10 07:04:30',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5722,
    'Mansab Odd Bhobhra',
    'mo',
    '2026-08-10 07:04:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5822,
    'Rana Nasrullah Thatha Paroothyan',
    'rnt',
    '2026-08-10 07:05:44',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5923,
    'New Itfaq Gudds',
    'nit',
    '2026-08-10 07:06:30',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6025,
    'Nawaz Mill wala',
    'nm',
    '2026-08-10 07:07:14',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6128,
    'Nasar Abbas Qurashi',
    'naq',
    '2026-08-10 07:07:46',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6232,
    'Naveed SO Mansha Sabuka',
    'nms',
    '2026-08-10 07:08:28',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6337,
    'Nasrullah Thatha Bhattian',
    'ntb',
    '2026-08-10 07:09:02',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6443,
    'Hashim Jalal c\\s Bahuman',
    'hjcs',
    '2026-08-10 07:10:14',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6550,
    'Younas Mistri Bhobhra',
    'ym',
    '2026-08-10 07:10:57',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6767,
    'Aftab Ahmad Gunman',
    'aag',
    '2026-08-10 07:12:12',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6986,
    'Javed Iqbal Mulazam',
    'ji',
    '2026-08-10 07:13:36',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7097,
    'Fiaz Ahmad Mulazam',
    'fa',
    '2026-08-10 07:14:10',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7209,
    'Fizan Ali Mulazam',
    'fam',
    '2026-08-10 07:14:44',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7322,
    'Rizan Haider Mulazam',
    'rh',
    '2026-08-10 07:15:25',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7436,
    'Naouman Ali Mulazam',
    'na',
    '2026-08-10 07:17:23',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7550,
    'Aftab Ahmad Sfai wala',
    'aas',
    '2026-08-10 07:18:01',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7665,
    'Asghar Ali Janduki',
    'aaj',
    '2026-08-10 07:18:28',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7781,
    'Amjad SO Zulfiqar Thatha Bhattian',
    'az',
    '2026-08-10 07:19:21',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7782,
    '793 Parvaiz Chaddar',
    '793',
    '2026-08-10 07:20:57',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7783,
    '793 Parvaiz chaddar 672',
    '672',
    '2026-08-10 07:21:34',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7900,
    'Dr Shoaib Thatha Khair o Mutmal',
    'dst',
    '2026-08-10 07:22:38',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8018,
    'Mushtaq Chadhar Rah Bhobhra',
    'mc',
    '2026-08-10 07:23:13',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8137,
    'Ashraf Thatha Bhattian',
    'atb',
    '2026-08-10 07:23:45',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8257,
    '197 Sohail Jutt',
    '197',
    '2026-08-10 07:24:15',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8500,
    'Sarfraz Mahnga Bhobhra',
    'smb',
    '2026-08-10 07:25:52',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8622,
    '511 Mudassar ALi Piranyki',
    '511',
    '2026-08-10 07:26:23',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8745,
    '105 Rafaqat Chadhar',
    '105',
    '2026-08-10 07:26:55',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8869,
    'Suleman Dwai  dealer',
    'sdd',
    '2026-08-10 07:27:37',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8994,
    '5417 Zaman Thatha Lodika',
    '5417',
    '2026-08-10 07:28:17',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9120,
    '2715 Khadim Bhatti Sukheki',
    '2715',
    '2026-08-10 07:28:56',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9247,
    '137 Malik FIda Hussain Sukheki',
    '137',
    '2026-08-10 07:29:40',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9375,
    '0056 Pervaiz Chadhar 864',
    '864',
    '2026-08-10 07:30:20',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9504,
    '7011 Shakeel Sahab',
    '7011',
    '2026-08-10 07:31:24',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (9634, 'Agency Khata', 'ak', '2026-08-10 07:32:12', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9765,
    'Bashir Ahmad Kot Nakka',
    'bak',
    '2026-08-10 07:32:47',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9897,
    'Madni c\\s Chowki Sukheki',
    'mcds',
    '2026-08-10 07:35:08',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9898,
    'Madni c\\s Chowki Sukheki',
    'mdcs',
    '2026-08-10 07:35:35',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10031,
    'Card Machine',
    'cm',
    '2026-08-10 07:36:18',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10165,
    '9412 Pervaiz Chaddhar',
    '9412',
    '2026-08-10 07:36:51',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10300,
    'Nasir Barhakpur',
    'nb',
    '2026-08-10 07:38:51',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10436,
    'Nawaz SO Nazir Thatha paroothyan',
    'nnt',
    '2026-08-10 07:39:57',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10709,
    'Qasim Ali Thatha Bhattian',
    'qat',
    '2026-08-10 07:40:41',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10847,
    'Qari Muhammad Aslam',
    'qma',
    '2026-08-10 07:41:18',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10986,
    'Rabnawaz SO Anayt',
    'rba',
    '2026-08-10 07:42:13',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11126,
    'Muhammad Hussain Tahli Ghuraya',
    'mht',
    '2026-08-10 07:43:03',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11407,
    'Muzamal Abbas',
    'mza',
    '2026-08-10 07:44:17',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11549,
    'Shoaib SO Aslam',
    'sa',
    '2026-08-10 07:47:02',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11692,
    'Saqib Sokhal',
    'ss',
    '2026-08-10 07:47:37',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11693,
    'Skinder Bhobhra',
    'skb',
    '2026-08-10 07:47:54',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11837,
    'Ahsaan Jappa',
    'aj',
    '2026-08-10 07:48:25',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11982,
    'Hanif Parr Lakhan',
    'hpl',
    '2026-08-10 07:48:56',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (12128, 'TLG397', '397', '2026-08-10 07:49:46', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12275,
    'Amjad SO Bashir Sabri',
    'abs',
    '2026-08-10 07:50:18',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12423,
    'Ramzan Jappa',
    'rj',
    '2026-08-10 07:50:47',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12572,
    'Fida Hussain Kharal wala',
    'fhk',
    '2026-08-10 07:51:18',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12722,
    'Hamayoun Sokhal',
    'hsk',
    '2026-08-10 07:51:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12873,
    'Umer Farooq SO Araf Bhobhra',
    'uf',
    '2026-08-10 07:52:36',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    13025,
    'Haji Imtiaz Hussyki',
    'hi',
    '2026-08-10 07:53:13',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (13178, 'Imtiaz Kala', 'ik', '2026-08-10 07:53:49', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    13179,
    'Mian Filling Station Sukheki',
    'mfs',
    '2026-08-10 07:56:15',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    13404,
    'Isamail 2818',
    '2818',
    '2026-08-10 12:17:49',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    13559,
    'imran s\\o shumar par lakhan',
    'isp',
    '2026-08-10 12:19:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    13715,
    'qasim tori wala',
    'qtw',
    '2026-08-10 12:22:24',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    13872,
    'habib lohar kharal wala',
    'hlk',
    '2026-08-10 12:24:07',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14030,
    'azhar par ahmad',
    'apa',
    '2026-08-10 12:26:29',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14189,
    'Monda Egency Bhobrra',
    'me',
    '2026-08-10 12:55:31',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14349,
    'Muzafar Chadhrr',
    'mcm',
    '2026-08-10 12:57:02',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14510,
    'Umar Draz Bhobrra',
    'udb',
    '2026-08-10 12:57:55',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14672,
    'Foji Mehndi ththa lalaira',
    'fmt',
    '2026-08-10 12:58:54',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14835,
    'Imtiaz Sabar',
    'is',
    '2026-08-10 12:59:32',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14836,
    'Ghulam Shabir kemboka',
    'gsk',
    '2026-08-10 13:00:11',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14837,
    '3356 Tahir bhatti',
    '3356',
    '2026-08-10 13:01:00',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14838,
    'Tanvir Bhatti paranekee',
    'tbp',
    '2026-08-10 13:01:41',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14839,
    'Fardoos jamal thatha bhattian',
    'fjt',
    '2026-08-10 13:02:31',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15007,
    'Sarwar bhatti chabheel',
    'sbc',
    '2026-08-10 13:03:35',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15008,
    'Rana Ishaq ththa parothian',
    'rit',
    '2026-08-10 13:04:22',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15009,
    'Shani Rah bobrra',
    'srb',
    '2026-08-10 13:05:06',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15180,
    '1401 Mazhar bhatti',
    '1401',
    '2026-08-10 13:07:32',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15181,
    'Yasin s\\o Allah Dittan',
    'yad',
    '2026-08-10 13:09:08',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15182,
    'Rai Tahir Hussekee',
    'rth',
    '2026-08-10 13:09:50',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15183,
    '8143 Bilal',
    '8143',
    '2026-08-10 13:10:35',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15355,
    'Afzal Chadharr ththa porthian',
    'act',
    '2026-08-10 13:11:53',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15356,
    'Abid Wassi ththa',
    'awt',
    '2026-08-10 13:12:36',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15358,
    'Bilal Electrtition  bhobrra',
    'beb',
    '2026-08-10 13:13:31',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15359,
    'Haji Umar Draz paranekee',
    'hud',
    '2026-08-10 13:14:11',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15360,
    'Aftab mochi rahh bhobrra',
    'amr',
    '2026-08-10 13:14:59',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (15361, 'Samar UBL', 'subl', '2026-08-10 13:16:07', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15362,
    'Nasar Lohar jhal',
    'nlj',
    '2026-08-10 13:16:57',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15363,
    'Arshad chochak',
    'ac',
    '2026-08-10 13:17:51',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15364,
    'Foji ishaq parr ahmad',
    'fip',
    '2026-08-10 13:18:48',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15365,
    'Inzmam mochi bhobrra',
    'imb',
    '2026-08-10 13:19:23',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15366,
    'Safdar s\\o Wali',
    'sw',
    '2026-08-10 13:20:57',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15367,
    'Ashraf Sameka',
    'as',
    '2026-08-10 13:52:43',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15368,
    'Riaz s\\o Ameer bhobrra',
    'rab',
    '2026-08-10 13:53:32',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15369,
    'Qayoum parr ahmad',
    'qpa',
    '2026-08-10 13:54:23',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15370,
    'Nouman Pranekee',
    'np',
    '2026-08-10 13:54:54',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15557,
    'Nasir Iqbal Paraneke',
    'nip',
    '2026-08-10 13:55:35',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15558,
    'Faiz ul Hassan parr ahmad',
    'fuh',
    '2026-08-10 13:56:27',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15559,
    'Jameel Komhaar parr masso',
    'jkp',
    '2026-08-10 13:57:05',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15560,
    'Zameer Komhaar rah bobrra',
    'zkr',
    '2026-08-10 13:57:48',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15561,
    'Jaggo mistri',
    'jm',
    '2026-08-10 13:58:54',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15562,
    'Sultan chadharr rah bobrra',
    'scr',
    '2026-08-10 13:59:22',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15563,
    'Arshad ththa  hattian',
    'ath',
    '2026-08-10 14:00:04',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15564,
    'Molvi Khalid Araien',
    'mka',
    '2026-08-10 14:00:49',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15565,
    'Tanveer Bashir ththta',
    'tbt',
    '2026-08-10 14:01:32',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15761,
    'Javed s\\o Botta paranekee',
    'jbp',
    '2026-08-10 14:02:25',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15762,
    'Ghulab shah jhal mona',
    'gsj',
    '2026-08-10 14:22:16',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15763,
    'Amir oad chabeel',
    'aoc',
    '2026-08-10 14:25:14',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15765,
    'Mujahid Paranekee',
    'mp',
    '2026-08-10 14:26:07',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15766,
    'Zaheer Balak ka bhobrra',
    'zbk',
    '2026-08-10 14:26:59',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15767,
    'Yasin komhaar paranekee',
    'ykp',
    '2026-08-10 14:28:37',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15768,
    'Riast salt ka',
    'rsk',
    '2026-08-10 14:29:13',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15769,
    'Ishrat Shaik Parr lakhan',
    'ispl',
    '2026-08-10 14:29:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15770,
    'Zafar s\\o kameera ththa bhattian',
    'zkt',
    '2026-08-10 14:31:09',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15771,
    'Usman & Adnan Sokhal',
    'uas',
    '2026-08-10 14:32:12',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15772,
    'Ahmad Ali Tulla Bhobrra',
    'aatb',
    '2026-08-10 14:33:26',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15773,
    'Azhar Pappo bhobrra',
    'apb',
    '2026-08-10 14:34:11',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15774,
    'Amar Dairy',
    'amar',
    '2026-08-10 14:35:01',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15775,
    'Zain comission shop bhobrra',
    'zain',
    '2026-08-10 14:35:44',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15776,
    'Asif Chema rah bhobrra',
    'asif',
    '2026-08-10 14:36:23',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15777,
    'Munawar kharl wala',
    'mkw',
    '2026-08-10 14:37:01',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15778,
    'Moazam Kharl wala',
    'mnk',
    '2026-08-10 14:37:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15779,
    'Sadi Ahmad driver',
    'sad',
    '2026-08-10 14:38:27',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15993,
    'Rai shokat sabt shah',
    'rss',
    '2026-08-10 14:39:50',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15994,
    'Ali Hassan Sabt shah',
    'ahs',
    '2026-08-10 14:40:29',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15995,
    'Mazhar Aasi Bhobrra',
    'mab',
    '2026-08-10 14:41:05',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15996,
    'Ishaq Bhobrra',
    'ib',
    '2026-08-10 14:42:12',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15997,
    'Wasim Faisal Ali',
    'wfa',
    '2026-08-10 14:43:06',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16216,
    '271 Imdad paranekee',
    '271',
    '2026-08-10 14:43:44',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16217,
    'Rai Tikka khan bhobrra',
    'rtk',
    '2026-08-10 14:44:22',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16218,
    'Nusrat Nasir Saddi parr',
    'nns',
    '2026-08-10 14:45:22',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16219,
    'Fouji Yara paranekee',
    'fyp',
    '2026-08-10 14:46:46',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16220,
    'Mubashar Sokhal Parr Lakhan',
    'msp',
    '2026-08-10 14:47:31',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16221,
    'Bava Hasnain Shah',
    'bhs',
    '2026-08-10 14:48:08',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16222,
    'Sahb khan s\\o Niamt bhobrra',
    'skn',
    '2026-08-10 14:48:57',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16223,
    'Mian Sabtain mian raja',
    'msm',
    '2026-08-10 14:49:36',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16224,
    'Taswar Hafeez ijaz',
    'thi',
    '2026-08-10 14:50:48',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16225,
    'Rana sajid parr ghusro',
    'rsp',
    '2026-08-10 14:52:46',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16226,
    'Zawar Pouli ththa parothian',
    'zpt',
    '2026-08-10 14:53:23',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16456,
    'Mustansar paranekee bhatti',
    'mpb',
    '2026-08-10 14:55:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16458,
    'Shahid Shahzad Sajid',
    'sss',
    '2026-08-10 14:56:41',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16459,
    'Faisal Deendaar ththa bhattian',
    'fdt',
    '2026-08-10 15:00:45',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16692,
    'shahid saif Umar',
    'ssu',
    '2026-08-10 15:01:44',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16693,
    'Irfan Asmat Mudasar Kala',
    'iam',
    '2026-08-10 15:02:58',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16694,
    'Adeel Awais Tota oad parvez',
    'aato',
    '2026-08-10 15:04:17',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16695,
    'Asghar Sami Saqlain Yaqoob',
    'ass',
    '2026-08-10 15:05:50',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16932,
    'Naem Ibrar Irfan Taswar',
    'nii',
    '2026-08-10 15:07:50',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16933,
    'Azhar Ramzan Liaqt',
    'arl',
    '2026-08-10 15:09:14',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16934,
    'Mix page 604',
    '604',
    '2026-08-10 15:11:47',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16935,
    'Mix page 605',
    'm605',
    '2026-08-10 15:15:05',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (16936, 'Mix 606', '606', '2026-08-10 15:17:52', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (16937, 'Diesel', 'd', '2026-08-10 15:20:55', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (16938, 'MobilOil', 'm', '2026-08-10 15:22:06', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (17182, 'Not Found', 'cash', '2026-08-10 15:23:51', 1);
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    17669,
    'tanveer bhatti jalal',
    'tbj',
    '2026-08-11 07:08:48',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    19372,
    'molvi ashrif par ahmad',
    'molvi',
    '2026-08-11 09:04:03',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    19373,
    'sana s\\o ashrif bhobra',
    'sana',
    '2026-08-11 09:04:55',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    19374,
    'safdar bhatti php',
    'sphp',
    '2026-08-11 09:05:44',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    19622,
    'jhangeer samika',
    'js',
    '2026-08-11 09:08:27',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    20119,
    'safdar nai rah bhobra',
    'snr',
    '2026-08-11 10:39:46',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    22121,
    'rante khata 2144',
    'r2144',
    '2026-08-11 14:42:00',
    1
  );
INSERT INTO
  `daily_customers` (
    `id`,
    `customer_name`,
    `search_id`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    22622,
    'Babu Bhobhra',
    'bb',
    '2026-08-12 03:59:39',
    1
  );

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: daily_sheets
# ------------------------------------------------------------

INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1,
    'aa',
    5000.00,
    1000.00,
    NULL,
    4000.00,
    '2026-07-17',
    '2026-07-17 06:42:29',
    NULL
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2,
    'a',
    0.00,
    0.00,
    NULL,
    0.00,
    '2026-07-17',
    '2026-07-17 06:42:29',
    NULL
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3,
    'as',
    0.00,
    0.00,
    NULL,
    0.00,
    '2026-07-17',
    '2026-07-17 06:42:29',
    NULL
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4,
    'a',
    3000.00,
    1000.00,
    NULL,
    2000.00,
    '2026-07-18',
    '2026-07-18 18:55:56',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5,
    'mh',
    10000.00,
    15000.00,
    NULL,
    -5000.00,
    '2026-07-19',
    '2026-07-19 10:04:32',
    5
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7,
    'aa',
    1000.00,
    0.00,
    NULL,
    1000.00,
    '2026-08-01',
    '2026-08-01 18:02:12',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8,
    'a',
    1000.00,
    0.00,
    NULL,
    1000.00,
    '2026-08-01',
    '2026-08-01 18:02:12',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9,
    'mh',
    10000.00,
    5000.00,
    NULL,
    5000.00,
    '2026-08-02',
    '2026-08-01 18:03:08',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11,
    'a',
    1000.00,
    0.00,
    NULL,
    1000.00,
    '2026-08-02',
    '2026-08-01 18:03:08',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12,
    'mh',
    0.00,
    0.00,
    NULL,
    0.00,
    '2026-08-03',
    '2026-08-01 18:05:04',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    13,
    'aa',
    0.00,
    0.00,
    NULL,
    0.00,
    '2026-08-03',
    '2026-08-01 18:05:04',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14,
    'a',
    0.00,
    1000.00,
    NULL,
    -1000.00,
    '2026-08-03',
    '2026-08-01 18:05:04',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15,
    'a',
    0.00,
    1200.00,
    NULL,
    -1200.00,
    '2026-08-04',
    '2026-08-01 18:14:43',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16,
    'mh',
    0.00,
    5000.00,
    'liye gay',
    -5000.00,
    '2026-08-05',
    '2026-08-01 18:16:48',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    17,
    'j',
    1000.00,
    0.00,
    NULL,
    1000.00,
    '2026-08-02',
    '2026-08-02 07:39:14',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    18,
    'aa',
    0.00,
    1000.00,
    NULL,
    -1000.00,
    '2026-08-02',
    '2026-08-02 07:50:22',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    19,
    'aa',
    100.00,
    0.00,
    '',
    100.00,
    '2026-08-05',
    '2026-08-05 04:08:59',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    20,
    'a',
    3444.00,
    0.00,
    'given',
    3444.00,
    '2026-08-05',
    '2026-08-05 04:11:28',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    21,
    'as',
    0.00,
    10000.00,
    'for oil',
    -10000.00,
    '2026-08-05',
    '2026-08-05 04:18:32',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    22,
    'bb',
    5000.00,
    0.00,
    'paid',
    5000.00,
    '2026-08-05',
    '2026-08-05 04:37:16',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    23,
    'mi',
    5000.00,
    0.00,
    'rent',
    5000.00,
    '2026-08-05',
    '2026-08-05 04:37:16',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24,
    '5544',
    1000.00,
    0.00,
    'Oil',
    1000.00,
    '2026-08-05',
    '2026-08-05 04:50:02',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    51,
    'pm',
    5555.00,
    0.00,
    '',
    5555.00,
    '2026-08-05',
    '2026-08-05 10:47:05',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    61,
    'j',
    55.00,
    0.00,
    '',
    55.00,
    '2026-08-05',
    '2026-08-05 10:47:29',
    4
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    62,
    'bb',
    334.00,
    0.00,
    '',
    334.00,
    '2026-08-06',
    '2026-08-06 04:28:25',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    64,
    'mi',
    5000.00,
    0.00,
    'renovation',
    5000.00,
    '2026-08-06',
    '2026-08-06 04:31:49',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    79,
    'a',
    0.00,
    5000.00,
    'given',
    -5000.00,
    '2026-08-06',
    '2026-08-06 05:43:12',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    83,
    'fh',
    5000.00,
    0.00,
    'udhaar lia',
    -5000.00,
    '2026-08-05',
    '2026-08-06 05:54:22',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    84,
    'su',
    0.00,
    50000.00,
    'given',
    50000.00,
    '2026-08-05',
    '2026-08-06 05:54:22',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    85,
    'a',
    5000.00,
    0.00,
    'given',
    -5000.00,
    '2026-08-05',
    '2026-08-06 05:54:22',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    100,
    'bb',
    5000.00,
    0.00,
    'payed',
    -5000.00,
    '2026-08-07',
    '2026-08-08 04:16:22',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    120,
    'a',
    3434.00,
    0.00,
    'fdsdf',
    -3434.00,
    '2026-08-09',
    '2026-08-09 12:56:52',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    121,
    'bb',
    400.00,
    0.00,
    'payed',
    -400.00,
    '2026-08-09',
    '2026-08-09 12:56:52',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    21737,
    'bb',
    499.00,
    0.00,
    'pay',
    -499.00,
    '2026-08-08',
    '2026-08-11 12:51:34',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    21738,
    'mi',
    500.00,
    0.00,
    'renovation',
    -500.00,
    '2026-08-08',
    '2026-08-11 12:51:34',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    21739,
    'a',
    500.00,
    0.00,
    '',
    -500.00,
    '2026-08-08',
    '2026-08-11 12:51:34',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    21740,
    'fh',
    5000.00,
    0.00,
    '',
    -5000.00,
    '2026-08-08',
    '2026-08-11 12:51:34',
    2
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24246,
    'mh',
    0.00,
    58757.00,
    '',
    58757.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24247,
    'mi',
    44010.00,
    0.00,
    '',
    -44010.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24248,
    'bb',
    8000.00,
    0.00,
    '',
    -8000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24249,
    'l',
    4588.00,
    0.00,
    '',
    -4588.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24250,
    'sp',
    94415.00,
    0.00,
    '',
    -94415.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24251,
    'ubls',
    0.00,
    19080243.00,
    '',
    19080243.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24252,
    'ublsm',
    4689037.00,
    0.00,
    '',
    -4689037.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24253,
    'ao',
    410946.00,
    0.00,
    '',
    -410946.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24254,
    'mj',
    44162185.00,
    0.00,
    '',
    -44162185.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24255,
    'mj2',
    0.00,
    65284836.00,
    '',
    65284836.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24256,
    'aw',
    0.00,
    10000.00,
    '',
    10000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24257,
    '2144',
    319455.00,
    0.00,
    '',
    -319455.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24258,
    'rk',
    41636.00,
    0.00,
    '',
    -41636.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24259,
    '573',
    773868.00,
    0.00,
    '',
    -773868.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24260,
    '7053',
    620697.00,
    0.00,
    '',
    -620697.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24261,
    '1185',
    110297.00,
    0.00,
    '',
    -110297.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24262,
    '7098',
    9000.00,
    0.00,
    '',
    -9000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24263,
    '5225',
    32052.00,
    0.00,
    '',
    -32052.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24264,
    '605',
    672996.00,
    0.00,
    '',
    -672996.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24265,
    '9856',
    38589.00,
    0.00,
    '',
    -38589.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24266,
    '1266',
    932909.00,
    0.00,
    '',
    -932909.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24267,
    '5100',
    357268.00,
    0.00,
    '',
    -357268.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24268,
    '239',
    1353637.00,
    0.00,
    '',
    -1353637.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24269,
    '8301',
    1081805.00,
    0.00,
    '',
    -1081805.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24270,
    '7459',
    122517.00,
    0.00,
    '',
    -122517.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24271,
    '972',
    126228.00,
    0.00,
    '',
    -126228.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24272,
    '789',
    125307.00,
    0.00,
    '',
    -125307.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24273,
    '4837',
    243102.00,
    0.00,
    '',
    -243102.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24274,
    '359',
    65980.00,
    0.00,
    '',
    -65980.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24275,
    '057',
    390981.00,
    0.00,
    '',
    -390981.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24276,
    'ma',
    145774.00,
    0.00,
    '',
    -145774.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24277,
    'aa',
    295533.00,
    0.00,
    '',
    -295533.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24278,
    'ics',
    229965.00,
    0.00,
    '',
    -229965.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24279,
    'rcs',
    749377.00,
    0.00,
    '',
    -749377.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24280,
    'rcsc',
    391959.00,
    0.00,
    '',
    -391959.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24281,
    'racs',
    1626057.00,
    0.00,
    '',
    -1626057.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24282,
    'rt',
    630054.00,
    0.00,
    '',
    -630054.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24283,
    'mcs',
    992306.00,
    0.00,
    '',
    -992306.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24284,
    'kcs',
    447979.00,
    0.00,
    '',
    -447979.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24285,
    'scs',
    152933.00,
    0.00,
    '',
    -152933.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24286,
    'qcs',
    532943.00,
    0.00,
    '',
    -532943.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24287,
    'kcsp',
    69763.00,
    0.00,
    '',
    -69763.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24288,
    'acs',
    29789.00,
    0.00,
    '',
    -29789.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24289,
    'tj',
    48148.00,
    0.00,
    '',
    -48148.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24290,
    'wcs',
    905.00,
    0.00,
    '',
    -905.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24291,
    'pt',
    286684.00,
    0.00,
    '',
    -286684.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24292,
    'ns',
    136171.00,
    0.00,
    '',
    -136171.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24293,
    'ra',
    109771.00,
    0.00,
    '',
    -109771.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24294,
    'ad',
    183152.00,
    0.00,
    '',
    -183152.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24295,
    'adp',
    172524.00,
    0.00,
    '',
    -172524.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24296,
    'aab',
    17035.00,
    0.00,
    '',
    -17035.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24297,
    'aat',
    322851.00,
    0.00,
    '',
    -322851.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24298,
    'af',
    35127.00,
    0.00,
    '',
    -35127.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24299,
    'rat',
    12164.00,
    0.00,
    '',
    -12164.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24300,
    'im',
    75821.00,
    0.00,
    '',
    -75821.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24301,
    'ah',
    160455.00,
    0.00,
    '',
    -160455.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24302,
    'ih',
    85615.00,
    0.00,
    '',
    -85615.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24303,
    'ar',
    120803.00,
    0.00,
    '',
    -120803.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24304,
    'ha',
    64161.00,
    0.00,
    '',
    -64161.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24305,
    'ab',
    72244.00,
    0.00,
    '',
    -72244.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24306,
    'br',
    481480.00,
    0.00,
    '',
    -481480.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24307,
    'tam',
    65145.00,
    0.00,
    '',
    -65145.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24308,
    'jk',
    23255.00,
    0.00,
    '',
    -23255.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24309,
    'jc',
    0.00,
    508708.00,
    '',
    508708.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24310,
    'jcs',
    104784.00,
    0.00,
    '',
    -104784.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24311,
    'hs',
    186496.00,
    0.00,
    '',
    -186496.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24312,
    'dcs',
    242202.00,
    0.00,
    '',
    -242202.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24313,
    'ka',
    80781.00,
    0.00,
    '',
    -80781.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24314,
    'ri',
    80063.00,
    0.00,
    '',
    -80063.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24315,
    'zcs',
    48971.00,
    0.00,
    '',
    -48971.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24316,
    'sncs',
    237103.00,
    0.00,
    '',
    -237103.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24317,
    'sm',
    211264.00,
    0.00,
    '',
    -211264.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24318,
    'spa',
    37453.00,
    0.00,
    '',
    -37453.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24319,
    'sb',
    103841.00,
    0.00,
    '',
    -103841.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24320,
    'st',
    25637.00,
    0.00,
    '',
    -25637.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24321,
    'sh',
    224870.00,
    0.00,
    '',
    -224870.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24322,
    'sab',
    0.00,
    74351.00,
    '',
    74351.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24323,
    'zb',
    267241.00,
    0.00,
    '',
    -267241.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24324,
    'imt',
    311641.00,
    0.00,
    '',
    -311641.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24325,
    'aro',
    102627.00,
    0.00,
    '',
    -102627.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24326,
    'amb',
    0.00,
    58240.00,
    '',
    58240.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24327,
    'azb',
    86901.00,
    0.00,
    '',
    -86901.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24328,
    'di',
    31704.00,
    0.00,
    '',
    -31704.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24329,
    'uw',
    2688.00,
    0.00,
    '',
    -2688.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24330,
    'aap',
    78806.00,
    0.00,
    '',
    -78806.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24331,
    'map',
    975842.00,
    0.00,
    '',
    -975842.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24332,
    'arc',
    68818.00,
    0.00,
    '',
    -68818.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24333,
    'aoj',
    37670.00,
    0.00,
    '',
    -37670.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24334,
    'gsp',
    4338.00,
    0.00,
    '',
    -4338.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24335,
    'fbp',
    440935.00,
    0.00,
    '',
    -440935.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24336,
    'fab',
    93592.00,
    0.00,
    '',
    -93592.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24337,
    'qb',
    185652.00,
    0.00,
    '',
    -185652.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24338,
    'kbp',
    500.00,
    0.00,
    '',
    -500.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24339,
    'mn',
    460271.00,
    0.00,
    '',
    -460271.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24340,
    'mbp',
    79305.00,
    0.00,
    '',
    -79305.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24341,
    'zan',
    182225.00,
    0.00,
    '',
    -182225.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24342,
    'mhm',
    29901.00,
    0.00,
    '',
    -29901.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24343,
    'mo',
    13810.00,
    0.00,
    '',
    -13810.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24344,
    'rnt',
    329354.00,
    0.00,
    '',
    -329354.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24345,
    'nit',
    343752.00,
    0.00,
    '',
    -343752.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24346,
    'nm',
    45348.00,
    0.00,
    '',
    -45348.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24347,
    'naq',
    1188238.00,
    0.00,
    '',
    -1188238.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24348,
    'nms',
    5000.00,
    0.00,
    '',
    -5000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24349,
    'ntb',
    122868.00,
    0.00,
    '',
    -122868.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24350,
    'hjcs',
    546979.00,
    0.00,
    '',
    -546979.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24351,
    'ym',
    165103.00,
    0.00,
    '',
    -165103.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24352,
    'aag',
    316691.00,
    0.00,
    '',
    -316691.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24353,
    'ji',
    11708.00,
    0.00,
    '',
    -11708.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24354,
    'fa',
    14307.00,
    0.00,
    '',
    -14307.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24355,
    'fam',
    11484.00,
    0.00,
    '',
    -11484.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24356,
    'na',
    3006.00,
    0.00,
    '',
    -3006.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24357,
    'aas',
    18500.00,
    0.00,
    '',
    -18500.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24358,
    'aaj',
    118046.00,
    0.00,
    '',
    -118046.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24359,
    '672',
    125598.00,
    0.00,
    '',
    -125598.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24360,
    'dst',
    12700.00,
    0.00,
    '',
    -12700.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24361,
    'mc',
    79402.00,
    0.00,
    '',
    -79402.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24362,
    'atb',
    126255.00,
    0.00,
    '',
    -126255.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24363,
    '197',
    72028.00,
    0.00,
    '',
    -72028.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24364,
    'smb',
    0.00,
    237000.00,
    '',
    237000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24365,
    '511',
    2284.00,
    0.00,
    '1611 \\7927',
    -2284.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24366,
    '105',
    104005.00,
    0.00,
    '',
    -104005.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24367,
    'sdd',
    59112.00,
    0.00,
    '',
    -59112.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24368,
    '5417',
    119887.00,
    0.00,
    '',
    -119887.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24369,
    '2715',
    132564.00,
    0.00,
    '',
    -132564.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24370,
    '137',
    94470.00,
    0.00,
    '',
    -94470.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24371,
    '864',
    100000.00,
    0.00,
    '',
    -100000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24372,
    '7011',
    121691.00,
    0.00,
    '',
    -121691.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24373,
    'ak',
    0.00,
    14300.00,
    '',
    14300.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24374,
    'bak',
    1375500.00,
    0.00,
    '',
    -1375500.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24375,
    'mdcs',
    24071.00,
    0.00,
    '',
    -24071.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24376,
    'cm',
    18000.00,
    0.00,
    '',
    -18000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24377,
    '9412',
    100000.00,
    0.00,
    '',
    -100000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24378,
    'nb',
    85896.00,
    0.00,
    '',
    -85896.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24379,
    'nnt',
    145180.00,
    0.00,
    '',
    -145180.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24380,
    'qat',
    0.00,
    17650.00,
    '',
    17650.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24381,
    'qma',
    0.00,
    49527.00,
    '',
    49527.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24382,
    'rba',
    0.00,
    40523.00,
    '',
    40523.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24383,
    'mht',
    158440.00,
    0.00,
    '',
    -158440.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24384,
    'mza',
    0.00,
    890543.00,
    '',
    890543.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24385,
    'sa',
    64503.00,
    0.00,
    '',
    -64503.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24386,
    'skb',
    46839.00,
    0.00,
    '',
    -46839.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24387,
    'aj',
    49761.00,
    0.00,
    '',
    -49761.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24388,
    'hpl',
    121460.00,
    0.00,
    '',
    -121460.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24389,
    '397',
    85000.00,
    0.00,
    '',
    -85000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24390,
    'abs',
    146500.00,
    0.00,
    '',
    -146500.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24391,
    'rj',
    39206.00,
    0.00,
    '',
    -39206.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24392,
    'fhk',
    19570.00,
    0.00,
    '',
    -19570.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24393,
    'hsk',
    50683.00,
    0.00,
    '',
    -50683.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24394,
    'uf',
    224559.00,
    0.00,
    '',
    -224559.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24395,
    'hi',
    192118.00,
    0.00,
    '',
    -192118.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24396,
    'mfs',
    7900.00,
    0.00,
    '',
    -7900.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24397,
    '2818',
    2000.00,
    0.00,
    '',
    -2000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24398,
    'isp',
    3000.00,
    0.00,
    '',
    -3000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24399,
    'qtw',
    0.00,
    52000.00,
    '',
    52000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24400,
    'hlk',
    5000.00,
    0.00,
    '',
    -5000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24401,
    'apa',
    7656.00,
    0.00,
    '',
    -7656.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24402,
    'me',
    600.00,
    0.00,
    '',
    -600.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24403,
    'mcm',
    1300.00,
    0.00,
    '',
    -1300.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24404,
    'udb',
    3000.00,
    0.00,
    '',
    -3000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24405,
    'fmt',
    10000.00,
    0.00,
    '',
    -10000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24406,
    'is',
    4000.00,
    0.00,
    '',
    -4000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24407,
    'gsk',
    6000.00,
    0.00,
    '',
    -6000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24408,
    '3356',
    30621.00,
    0.00,
    '',
    -30621.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24409,
    'tbp',
    5000.00,
    0.00,
    '',
    -5000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24410,
    'fjt',
    989.00,
    0.00,
    '',
    -989.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24411,
    'sbc',
    2229.00,
    0.00,
    '',
    -2229.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24412,
    'rit',
    6000.00,
    0.00,
    '',
    -6000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24413,
    'srb',
    3800.00,
    0.00,
    '',
    -3800.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24414,
    '8143',
    9900.00,
    0.00,
    '',
    -9900.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24415,
    'act',
    65419.00,
    0.00,
    '',
    -65419.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24416,
    'awt',
    42564.00,
    0.00,
    '',
    -42564.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24417,
    'beb',
    9878.00,
    0.00,
    '',
    -9878.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24418,
    'hud',
    60344.00,
    0.00,
    '',
    -60344.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24419,
    'amr',
    19173.00,
    0.00,
    'saif chowki 15673',
    -19173.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24420,
    'subl',
    17700.00,
    0.00,
    '',
    -17700.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24421,
    'nlj',
    15229.00,
    0.00,
    '',
    -15229.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24422,
    'ac',
    85663.00,
    0.00,
    '',
    -85663.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24423,
    'fip',
    1888.00,
    0.00,
    '',
    -1888.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24424,
    'imb',
    155852.00,
    0.00,
    '',
    -155852.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24425,
    'sw',
    14961.00,
    0.00,
    '',
    -14961.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24426,
    'as',
    21402.00,
    0.00,
    '',
    -21402.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24427,
    'rab',
    38272.00,
    0.00,
    '',
    -38272.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24428,
    'qpa',
    8094.00,
    0.00,
    '',
    -8094.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24429,
    'np',
    63321.00,
    0.00,
    '',
    -63321.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24430,
    'nip',
    99224.00,
    0.00,
    '',
    -99224.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24431,
    'fuh',
    75037.00,
    0.00,
    '',
    -75037.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24432,
    'jkp',
    46016.00,
    0.00,
    '',
    -46016.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24433,
    'zkr',
    29600.00,
    0.00,
    'asghar 8500 akbar chowki 13100',
    -29600.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24434,
    'jm',
    1000.00,
    0.00,
    '',
    -1000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24435,
    'scr',
    83319.00,
    0.00,
    '',
    -83319.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24436,
    'ath',
    5000.00,
    0.00,
    'yousaf 1000',
    -5000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24437,
    'mka',
    466367.00,
    0.00,
    '',
    -466367.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24438,
    'tbt',
    28508.00,
    0.00,
    '',
    -28508.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24439,
    'jbp',
    54170.00,
    0.00,
    '14018 ali umar draz',
    -54170.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24440,
    'gsj',
    47556.00,
    0.00,
    '',
    -47556.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24441,
    'aoc',
    24766.00,
    0.00,
    '1000 shavez',
    -24766.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24442,
    'mp',
    4000.00,
    0.00,
    '1500 zaheer shah',
    -4000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24443,
    'zbk',
    110647.00,
    0.00,
    '',
    -110647.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24444,
    'ykp',
    15376.00,
    0.00,
    '',
    -15376.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24445,
    'rsk',
    9397.00,
    0.00,
    '',
    -9397.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24446,
    'ispl',
    7970.00,
    0.00,
    '',
    -7970.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24447,
    'zkt',
    13098.00,
    0.00,
    '',
    -13098.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24448,
    'uas',
    4600.00,
    0.00,
    '',
    -4600.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24449,
    'aatb',
    30000.00,
    0.00,
    '',
    -30000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24450,
    'apb',
    11480.00,
    0.00,
    '',
    -11480.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24451,
    'amar',
    24757.00,
    0.00,
    '',
    -24757.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24452,
    'zain',
    38368.00,
    0.00,
    '',
    -38368.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24453,
    'asif',
    40558.00,
    0.00,
    '',
    -40558.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24454,
    'mkw',
    20334.00,
    0.00,
    '',
    -20334.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24455,
    'mnk',
    55021.00,
    0.00,
    '',
    -55021.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24456,
    'sad',
    4200.00,
    0.00,
    'Rab nawaz 3000',
    -4200.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24457,
    'rss',
    58189.00,
    0.00,
    '',
    -58189.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24458,
    'ahs',
    5736.00,
    0.00,
    '',
    -5736.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24459,
    'mab',
    18968.00,
    0.00,
    '',
    -18968.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24460,
    'ib',
    137758.00,
    0.00,
    '15000 riaz',
    -137758.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24461,
    'wfa',
    3600.00,
    0.00,
    '',
    -3600.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24462,
    '271',
    147184.00,
    0.00,
    '',
    -147184.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24463,
    'rtk',
    38393.00,
    0.00,
    '3000 ahmad raza',
    -38393.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24464,
    'nns',
    45871.00,
    0.00,
    '17000\\ 19465\\9406',
    -45871.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24465,
    'fyp',
    4221.00,
    0.00,
    '',
    -4221.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24466,
    'msp',
    62000.00,
    0.00,
    '',
    -62000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24467,
    'bhs',
    31850.00,
    0.00,
    '',
    -31850.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24468,
    'skn',
    19755.00,
    0.00,
    '',
    -19755.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24469,
    'msm',
    53014.00,
    0.00,
    '37514 Sattar 5500 Iqbal',
    -53014.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24470,
    'thi',
    33250.00,
    0.00,
    '1000\\5485\\8571\\18194',
    -33250.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24471,
    'rsp',
    34391.00,
    0.00,
    '',
    -34391.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24472,
    'zpt',
    22327.00,
    0.00,
    '5000 abbas',
    -22327.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24473,
    'mpb',
    67752.00,
    0.00,
    '',
    -67752.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24474,
    'sss',
    40876.00,
    0.00,
    '2560\\3000\\17000\\10316\\8000',
    -40876.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24475,
    'fdt',
    46500.00,
    0.00,
    '6000 hassan lohar',
    -46500.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24476,
    'ssu',
    24706.00,
    0.00,
    '15350\\3656\\1200\\4500',
    -24706.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24477,
    'iam',
    34856.00,
    0.00,
    '3500\\3147\\8300\\1909',
    -34856.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24478,
    'aato',
    176942.00,
    0.00,
    '820\\116800\\5970\\53352',
    -176942.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24479,
    'ass',
    327642.00,
    0.00,
    '254453\\62240\\9949\\1000',
    -327642.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24480,
    'nii',
    77826.00,
    0.00,
    '6500\\40950\\28376\\2000',
    -77826.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24481,
    'arl',
    9957.00,
    0.00,
    '',
    -9957.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24482,
    '604',
    776660.00,
    0.00,
    '',
    -776660.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24483,
    'm605',
    289964.00,
    0.00,
    '',
    -289964.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24484,
    '606',
    724885.00,
    0.00,
    '',
    -724885.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24485,
    'd',
    936662.00,
    0.00,
    '',
    -936662.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24486,
    'm',
    67125.00,
    0.00,
    '',
    -67125.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24487,
    'tbj',
    0.00,
    1000000.00,
    '',
    1000000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24488,
    'yad',
    17245.00,
    0.00,
    '10357\\6268\\620',
    -17245.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24489,
    '1401',
    59701.00,
    0.00,
    '',
    -59701.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24490,
    'molvi',
    188647.00,
    0.00,
    '',
    -188647.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24491,
    'sana',
    33239.00,
    0.00,
    '',
    -33239.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24492,
    'sphp',
    78255.00,
    0.00,
    '',
    -78255.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24493,
    'js',
    1650.00,
    0.00,
    '',
    -1650.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24494,
    'snr',
    0.00,
    80000.00,
    '',
    80000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );
INSERT INTO
  `daily_sheets` (
    `id`,
    `search_id`,
    `debit_udhaar`,
    `credit_vasooli`,
    `description`,
    `total_balance`,
    `sheet_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24495,
    'r2144',
    19000.00,
    0.00,
    '',
    -19000.00,
    '2026-08-10',
    '2026-08-12 17:00:24',
    1
  );

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: expenses
# ------------------------------------------------------------

INSERT INTO
  `expenses` (
    `id`,
    `user_id`,
    `expense_date`,
    `title`,
    `description`,
    `amount`,
    `created_at`
  )
VALUES
  (
    1,
    4,
    '2026-08-01',
    'bill',
    'given to xyz',
    5500.00,
    '2026-08-01 20:28:41'
  );

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: fuel_rates
# ------------------------------------------------------------

INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1,
    'Diesel (HSD)',
    'Diesel',
    'Standard (HSD)',
    100.00,
    0.00,
    '2026-07-17',
    '2026-07-17 05:26:08',
    NULL
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2,
    'Petrol (Super)',
    'Super',
    'Petrol (PMG)',
    100.00,
    0.00,
    '2026-07-17',
    '2026-07-17 05:26:16',
    NULL
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3,
    'T 2 20Ltrs',
    'Mobil',
    'Mobil Oil 20L',
    100.00,
    0.00,
    '2026-07-17',
    '2026-07-17 05:26:24',
    NULL
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4,
    'Diesel (HSD)',
    'Diesel',
    'Standard (HSD)',
    300.00,
    0.00,
    '2026-07-18',
    '2026-07-18 18:54:22',
    1
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5,
    'Petrol (Super)',
    'Super',
    'Petrol (PMG)',
    300.00,
    0.00,
    '2026-07-18',
    '2026-07-18 18:54:31',
    1
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6,
    'Diesel (HSD)',
    'Diesel',
    'Standard (HSD)',
    300.00,
    0.00,
    '2026-07-19',
    '2026-07-19 06:47:15',
    4
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7,
    'Diesel (HSD)',
    'Diesel',
    'Standard (HSD)',
    300.00,
    0.00,
    '2026-07-19',
    '2026-07-19 10:04:59',
    5
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8,
    'Petrol (Super)',
    'Super',
    'Petrol (PMG)',
    300.00,
    0.00,
    '2026-07-21',
    '2026-07-20 20:58:09',
    4
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9,
    'Diesel (HSD)',
    'Diesel',
    'Standard (HSD)',
    322.00,
    321.00,
    '2026-08-01',
    '2026-08-01 17:03:47',
    4
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11,
    'Petrol (Super)',
    'Super',
    'Petrol (PMG)',
    352.00,
    350.00,
    '2026-08-02',
    '2026-08-01 19:58:20',
    4
  );
INSERT INTO
  `fuel_rates` (
    `id`,
    `product_name`,
    `product_type`,
    `specific_category`,
    `rate_per_litre`,
    `purchase_price`,
    `rate_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12,
    'Balize .75',
    'Mobil',
    'Mobil Oil .75L',
    250.00,
    222.00,
    '2026-08-02',
    '2026-08-02 06:14:52',
    4
  );

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: fuel_stocks
# ------------------------------------------------------------

INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (1, 'Diesel', 200.00, 0.00, 0.00, NULL);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (2, 'Super', 200.00, 0.00, 0.00, NULL);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (3, 'Diesel', 15.00, 0.00, 0.00, 1);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (4, 'Super', 20.00, 0.00, 0.00, 1);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (13, 'Diesel', -10000.00, 0.00, 0.00, 4);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (14, 'Super', 38988.00, 0.00, 0.00, 4);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (15, 'Diesel', 0.00, 0.00, 0.00, 3);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (16, 'Super', 0.00, 0.00, 0.00, 3);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (17, 'Diesel', 0.00, 0.00, 0.00, 5);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (18, 'Super', 0.00, 0.00, 0.00, 5);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (25, 'Diesel', 0.00, 0.00, 0.00, 6);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (26, 'Super', 0.00, 0.00, 0.00, 6);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (27, 'Diesel', 0.00, 0.00, 0.00, 7);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (28, 'Super', 0.00, 0.00, 0.00, 7);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (35, 'Diesel', 0.00, 0.00, 0.00, 8);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (36, 'Super', 0.00, 0.00, 0.00, 8);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (37, 'Diesel', 100.00, 0.00, 0.00, 9);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (38, 'Super', 100.00, 0.00, 0.00, 9);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (47, 'Diesel', 0.00, 0.00, 0.00, 10);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (48, 'Super', 0.00, 0.00, 0.00, 10);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (49, 'Diesel', 0.00, 0.00, 0.00, 11);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (50, 'Super', 0.00, 0.00, 0.00, 11);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (51, 'Diesel', 0.00, 0.00, 0.00, 2);
INSERT INTO
  `fuel_stocks` (
    `id`,
    `fuel_type`,
    `current_stock`,
    `opening_stock`,
    `receipt_stock`,
    `user_id`
  )
VALUES
  (52, 'Super', 0.00, 0.00, 0.00, 2);

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: lubricant_stocks
# ------------------------------------------------------------

INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (1, 'T 2 20Ltrs', 100, NULL);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (2, 'Balize .75', 100, NULL);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (3, 'Balize 1Ltrs', 100, NULL);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (4, 'Cariant 3Ltrs', 0, NULL);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (5, 'Cariant 4ltrs', 0, NULL);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (6, 'Deo 6000 4Ltrs', 0, NULL);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (7, 'Deo 6000 10Ltrs', 0, NULL);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (8, 'Deo 8000 4Ltrs', 0, NULL);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (9, 'Deo 8000 10Ltrs', 0, NULL);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (10, 'T 2 20Ltrs', 0, 1);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (11, 'Balize .75', 0, 1);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (12, 'Balize 1Ltrs', 0, 1);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (13, 'Cariant 3Ltrs', 0, 1);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (14, 'Cariant 4ltrs', 0, 1);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (15, 'Deo 6000 4Ltrs', 0, 1);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (16, 'Deo 6000 10Ltrs', 0, 1);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (17, 'Deo 8000 4Ltrs', 0, 1);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (18, 'Deo 8000 10Ltrs', 0, 1);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (19, 'T 2 20Ltrs', 0, 4);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (20, 'Balize .75', 0, 4);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (21, 'Balize 1Ltrs', 0, 4);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (22, 'Cariant 3Ltrs', 0, 4);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (23, 'Cariant 4ltrs', 0, 4);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (24, 'Deo 6000 4Ltrs', 0, 4);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (25, 'Deo 6000 10Ltrs', 0, 4);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (26, 'Deo 8000 4Ltrs', 0, 4);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (27, 'Deo 8000 10Ltrs', 0, 4);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (28, 'T 2 20Ltrs', 0, 3);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (29, 'Balize .75', 0, 3);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (30, 'Balize 1Ltrs', 0, 3);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (31, 'Cariant 3Ltrs', 0, 3);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (32, 'Cariant 4ltrs', 0, 3);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (33, 'Deo 6000 4Ltrs', 0, 3);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (34, 'Deo 6000 10Ltrs', 0, 3);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (35, 'Deo 8000 4Ltrs', 0, 3);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (36, 'Deo 8000 10Ltrs', 0, 3);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (37, 'T 2 20Ltrs', 0, 5);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (38, 'Balize .75', 0, 5);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (39, 'Balize 1Ltrs', 0, 5);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (40, 'Cariant 3Ltrs', 0, 5);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (41, 'Cariant 4ltrs', 0, 5);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (42, 'Deo 6000 4Ltrs', 0, 5);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (43, 'Deo 6000 10Ltrs', 0, 5);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (44, 'Deo 8000 4Ltrs', 0, 5);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (45, 'Deo 8000 10Ltrs', 0, 5);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (46, 'T 2 20Ltrs', 0, 6);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (47, 'Balize .75', 0, 6);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (48, 'Balize 1Ltrs', 0, 6);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (49, 'Cariant 3Ltrs', 0, 6);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (50, 'Cariant 4ltrs', 0, 6);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (51, 'Deo 6000 4Ltrs', 0, 6);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (52, 'Deo 6000 10Ltrs', 0, 6);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (53, 'Deo 8000 4Ltrs', 0, 6);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (54, 'Deo 8000 10Ltrs', 0, 6);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (55, 'T 2 20Ltrs', 0, 7);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (56, 'Balize .75', 0, 7);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (57, 'Balize 1Ltrs', 0, 7);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (58, 'Cariant 3Ltrs', 0, 7);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (59, 'Cariant 4ltrs', 0, 7);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (60, 'Deo 6000 4Ltrs', 0, 7);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (61, 'Deo 6000 10Ltrs', 0, 7);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (62, 'Deo 8000 4Ltrs', 0, 7);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (63, 'Deo 8000 10Ltrs', 0, 7);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (64, 'T 2 20Ltrs', 0, 8);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (65, 'Balize .75', 0, 8);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (66, 'Balize 1Ltrs', 0, 8);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (67, 'Cariant 3Ltrs', 0, 8);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (68, 'Cariant 4ltrs', 0, 8);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (69, 'Deo 6000 4Ltrs', 0, 8);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (70, 'Deo 6000 10Ltrs', 0, 8);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (71, 'Deo 8000 4Ltrs', 0, 8);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (72, 'Deo 8000 10Ltrs', 0, 8);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (73, 'T 2 20Ltrs', 0, 9);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (74, 'Balize .75', 0, 9);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (75, 'Balize 1Ltrs', 0, 9);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (76, 'Cariant 3Ltrs', 0, 9);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (77, 'Cariant 4ltrs', 0, 9);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (78, 'Deo 6000 4Ltrs', 0, 9);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (79, 'Deo 6000 10Ltrs', 0, 9);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (80, 'Deo 8000 4Ltrs', 0, 9);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (81, 'Deo 8000 10Ltrs', 0, 9);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (82, 'T 2 20Ltrs', 0, 10);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (83, 'Balize .75', 0, 10);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (84, 'Balize 1Ltrs', 0, 10);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (85, 'Cariant 3Ltrs', 0, 10);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (86, 'Cariant 4ltrs', 0, 10);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (87, 'Deo 6000 4Ltrs', 0, 10);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (88, 'Deo 6000 10Ltrs', 0, 10);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (89, 'Deo 8000 4Ltrs', 0, 10);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (90, 'Deo 8000 10Ltrs', 0, 10);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (91, 'T 2 20Ltrs', 0, 11);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (92, 'Balize .75', 0, 11);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (93, 'Balize 1Ltrs', 0, 11);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (94, 'Cariant 3Ltrs', 0, 11);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (95, 'Cariant 4ltrs', 0, 11);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (96, 'Deo 6000 4Ltrs', 0, 11);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (97, 'Deo 6000 10Ltrs', 0, 11);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (98, 'Deo 8000 4Ltrs', 0, 11);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (99, 'Deo 8000 10Ltrs', 0, 11);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (100, 'T 2 20Ltrs', 0, 2);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (101, 'Balize .75', 0, 2);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (102, 'Balize 1Ltrs', 0, 2);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (103, 'Cariant 3Ltrs', 0, 2);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (104, 'Cariant 4ltrs', 0, 2);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (105, 'Deo 6000 4Ltrs', 0, 2);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (106, 'Deo 6000 10Ltrs', 0, 2);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (107, 'Deo 8000 4Ltrs', 0, 2);
INSERT INTO
  `lubricant_stocks` (`id`, `item_name`, `current_stock`, `user_id`)
VALUES
  (108, 'Deo 8000 10Ltrs', 0, 2);

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: meter_readings
# ------------------------------------------------------------

INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1,
    'Diesel (N1)',
    'Diesel',
    0.00,
    500.00,
    500.00,
    '2026-07-17',
    '2026-07-17 05:23:27',
    NULL
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    2,
    'Diesel (N1)',
    'Diesel',
    500.00,
    1000.00,
    500.00,
    '2026-07-17',
    '2026-07-17 05:41:48',
    NULL
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    3,
    'Diesel (N1)',
    'Diesel',
    1000.00,
    1500.00,
    500.00,
    '2026-07-17',
    '2026-07-17 05:42:03',
    NULL
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    4,
    'Diesel (N1)',
    'Diesel',
    1500.00,
    1700.00,
    200.00,
    '2026-07-17',
    '2026-07-17 05:44:27',
    NULL
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    5,
    'Diesel (N2)',
    'Diesel',
    0.00,
    200.00,
    200.00,
    '2026-07-17',
    '2026-07-17 05:44:27',
    NULL
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    6,
    'Diesel (N3)',
    'Diesel',
    0.00,
    200.00,
    200.00,
    '2026-07-17',
    '2026-07-17 05:44:27',
    NULL
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7,
    'Diesel (N4)',
    'Diesel',
    0.00,
    200.00,
    200.00,
    '2026-07-17',
    '2026-07-17 05:44:27',
    NULL
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    8,
    'Super (N1)',
    'Super',
    0.00,
    500.00,
    500.00,
    '2026-07-17',
    '2026-07-17 05:44:27',
    NULL
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9,
    'Super (N2)',
    'Super',
    0.00,
    300.00,
    300.00,
    '2026-07-17',
    '2026-07-17 05:44:27',
    NULL
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10,
    'Diesel (N1)',
    'Diesel',
    0.00,
    50.00,
    50.00,
    '2026-07-18',
    '2026-07-18 18:55:27',
    1
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11,
    'Diesel (N2)',
    'Diesel',
    0.00,
    10.00,
    10.00,
    '2026-07-18',
    '2026-07-18 18:55:27',
    1
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12,
    'Diesel (N3)',
    'Diesel',
    0.00,
    5.00,
    5.00,
    '2026-07-18',
    '2026-07-18 18:55:27',
    1
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    13,
    'Diesel (N4)',
    'Diesel',
    0.00,
    20.00,
    20.00,
    '2026-07-18',
    '2026-07-18 18:55:28',
    1
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    14,
    'Super (N1)',
    'Super',
    0.00,
    50.00,
    50.00,
    '2026-07-18',
    '2026-07-18 18:55:28',
    1
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    15,
    'Super (N2)',
    'Super',
    0.00,
    30.00,
    30.00,
    '2026-07-18',
    '2026-07-18 18:55:28',
    1
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    16,
    'Diesel (N1)',
    'Diesel',
    0.00,
    450000.00,
    450000.00,
    '2026-07-19',
    '2026-07-19 10:23:41',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    17,
    'Super (N1)',
    'Super',
    0.00,
    4500.00,
    4500.00,
    '2026-07-19',
    '2026-07-19 10:24:13',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    18,
    'Super (N2)',
    'Super',
    0.00,
    400000.00,
    400000.00,
    '2026-07-19',
    '2026-07-19 10:24:50',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    19,
    'Diesel (N2)',
    'Diesel',
    0.00,
    500.00,
    500.00,
    '2026-07-17',
    '2026-07-20 20:57:43',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    20,
    'Super (N1)',
    'Super',
    4500.00,
    45000.00,
    40500.00,
    '2026-07-17',
    '2026-07-20 20:57:43',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    21,
    'Diesel (N3)',
    'Diesel',
    0.00,
    40000.00,
    40000.00,
    '2026-07-21',
    '2026-07-20 21:00:48',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    22,
    'Super (N2)',
    'Super',
    400000.00,
    420012.00,
    20012.00,
    '2026-07-21',
    '2026-07-20 21:00:49',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    23,
    'Diesel (N2)',
    'Diesel',
    500.00,
    9500.00,
    9000.00,
    '2026-07-21',
    '2026-07-20 21:07:23',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    24,
    'Diesel (N4)',
    'Diesel',
    0.00,
    500.00,
    500.00,
    '2026-07-21',
    '2026-07-20 21:13:53',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    25,
    'Diesel (N1)',
    'Diesel',
    0.00,
    100.00,
    100.00,
    '2026-07-21',
    '2026-07-20 21:23:46',
    9
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    26,
    'Diesel (N2)',
    'Diesel',
    0.00,
    100.00,
    100.00,
    '2026-07-21',
    '2026-07-20 21:23:46',
    9
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    27,
    'Diesel (N3)',
    'Diesel',
    0.00,
    100.00,
    100.00,
    '2026-07-21',
    '2026-07-20 21:23:46',
    9
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    28,
    'Diesel (N4)',
    'Diesel',
    0.00,
    100.00,
    100.00,
    '2026-07-21',
    '2026-07-20 21:23:46',
    9
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    29,
    'Super (N1)',
    'Super',
    0.00,
    100.00,
    100.00,
    '2026-07-21',
    '2026-07-20 21:23:46',
    9
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    30,
    'Super (N2)',
    'Super',
    0.00,
    100.00,
    100.00,
    '2026-07-21',
    '2026-07-20 21:23:46',
    9
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    31,
    'Diesel (N2)',
    'Diesel',
    9500.00,
    10000.00,
    500.00,
    '2026-08-02',
    '2026-08-01 19:47:29',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    32,
    'Super (N1)',
    'Super',
    45000.00,
    46000.00,
    1000.00,
    '2026-08-02',
    '2026-08-01 19:49:06',
    4
  );
INSERT INTO
  `meter_readings` (
    `id`,
    `nozzle_name`,
    `fuel_type`,
    `opening_reading`,
    `closing_reading`,
    `liters_sold`,
    `reading_date`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    33,
    'Diesel (N1)',
    'Diesel',
    450000.00,
    460000.00,
    10000.00,
    '2026-08-03',
    '2026-08-03 11:21:40',
    4
  );

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: users
# ------------------------------------------------------------

INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    1,
    'Admin',
    'admin123',
    '$2b$10$IxLODma/vYIneA2JP1Eoxuj.LWUzQL0xASPrM4YXih1zQZWFyeCLC',
    'Manager',
    '2026-07-17 05:21:11'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    2,
    'Aftab Ahmad Bhatti',
    'aftab123',
    '$2b$10$BxOEEezjsT5npL/u3gku/.j0/BvrLU.PibbZ2XwUxiJ6q7ZQOKTNO',
    'Manager',
    '2026-07-17 05:21:55'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    3,
    'Ahsan Shahzad',
    'ahsan917      ',
    '$2b$10$Dr0yJWnUM90GL6S9.sIaiOw8nao2QkDtyX81QVIC4xnXYhkm5RDK.',
    'Manager',
    '2026-07-17 06:53:36'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    4,
    'admin',
    'admin',
    '$2b$10$K1w9hiEX9YxnajgDaJLPI.eDN8s3TY80J3sVT9PkIlej2BqImACBa',
    'Manager',
    '2026-07-19 06:18:22'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    5,
    'Hassan ',
    'hassan123',
    '$2b$10$1zg0SifM1in8EjnEExgotOqrrz5gv6YoRVsR7OGyqhp1cTyLfAgQ.',
    'Manager',
    '2026-07-19 10:02:20'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    6,
    'Aftab Ahmad',
    'aftab1234',
    '$2b$10$HfLqlhZ/TsFOiWZXB2J.C.GRLKGPZmsR7lIaXzhhAXvxxDVW.MBLq',
    'Manager',
    '2026-07-20 09:57:03'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    7,
    'Aftab Ahmad',
    'aftab12',
    '$2b$10$PGzoNpKmCOMI.k3rc2t0quYI5ynw0FvNH3vj8STiiKTjKGNd3bu8S',
    'Manager',
    '2026-07-20 09:58:16'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    8,
    'Aftab Ahmad Bhatti',
    'aaa',
    '$2b$10$vbY1apQ85FNW/kXYDCAW0.2jmy6tH3vA9r7SStJMl3UJgDmXWX9gi',
    'Manager',
    '2026-07-20 21:20:59'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    9,
    'ali',
    'ali123',
    '$2b$10$cOcEDzgGMqyliEKpwQISuOwdC6ul8qZeBxNpOE5qelEHGy4m7Y7hG',
    'Manager',
    '2026-07-20 21:22:52'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    10,
    'Aftab Ahmad Bhatti',
    'aftab40',
    '$2b$10$MHS8jT.s7id3hoeJOSVXcO.tWbfYcnSY6jk5d3W4Ygi8UMEi8r73G',
    'Manager',
    '2026-07-21 06:19:04'
  );
INSERT INTO
  `users` (
    `id`,
    `full_name`,
    `username`,
    `password`,
    `role`,
    `created_at`
  )
VALUES
  (
    11,
    'Aftab Ahmad Bhatti',
    'aftab49',
    '$2b$10$csTeLHBBb2nSrEp4DMzZrerjPG9tZqGtbAxDMziK6TQXKEhXIl6VO',
    'Manager',
    '2026-07-21 06:20:09'
  );

# ------------------------------------------------------------
# DATA DUMP FOR TABLE: vehicles
# ------------------------------------------------------------

INSERT INTO
  `vehicles` (
    `id`,
    `gari_number`,
    `owner_name`,
    `contact_number`,
    `address`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    1,
    'fsd-3344',
    'ali',
    '032456641020',
    'bhobhra',
    '2026-07-17 05:33:10',
    NULL
  );
INSERT INTO
  `vehicles` (
    `id`,
    `gari_number`,
    `owner_name`,
    `contact_number`,
    `address`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    7,
    'fsd-3346',
    'ali',
    '032456641020',
    'bhobhra',
    '2026-07-19 06:27:57',
    1
  );
INSERT INTO
  `vehicles` (
    `id`,
    `gari_number`,
    `owner_name`,
    `contact_number`,
    `address`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    9,
    'fsd-3344',
    'ali',
    '032456641020',
    'bhobhra',
    '2026-07-19 06:44:11',
    1
  );
INSERT INTO
  `vehicles` (
    `id`,
    `gari_number`,
    `owner_name`,
    `contact_number`,
    `address`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    10,
    'fsd-3344',
    'ali',
    '032456641020',
    'bhobhra',
    '2026-07-19 06:46:57',
    4
  );
INSERT INTO
  `vehicles` (
    `id`,
    `gari_number`,
    `owner_name`,
    `contact_number`,
    `address`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    11,
    'fsd-3344',
    'ali',
    '032456641020',
    'bhobhra',
    '2026-07-19 10:04:44',
    5
  );
INSERT INTO
  `vehicles` (
    `id`,
    `gari_number`,
    `owner_name`,
    `contact_number`,
    `address`,
    `created_at`,
    `user_id`
  )
VALUES
  (
    12,
    'fsd-3345',
    'ali',
    '3459383',
    'FHALDFL',
    '2026-08-01 17:40:50',
    4
  );

/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
