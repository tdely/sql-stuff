-- Check collation and charset of tables
SELECT T.table_name, ccsa.character_set_name,ccsa.collation_name FROM information_schema.`tables` T, information_schema.`collation_character_set_applicability` ccsa WHERE ccsa.collation_name = T.table_collation AND T.table_schema = schema_name;

-- Find table columns that are not utf8mb4_unicode_ci
SELECT table_name,column_name,character_set_name,collation_name FROM information_schema.`COLUMNS`  WHERE table_schema = schema_name AND collation_name IS NOT NULL AND character_set_name IS NOT NULL AND collation_name <> 'utf8mb4_unicode_ci';

-- Alter
ALTER TABLE table_name DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE table_name CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER DATABASE schema_name DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER DATABASE schema_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Build table alter queries for non-utf8mb4_unicode_ci tables
SELECT CONCAT('ALTER TABLE `', table_schema,'`.`', table_name,'` COLLATE utf8mb4_unicode_ci;') AS query FROM information_schema.tables WHERE TABLE_SCHEMA = schema_name AND table_type = 'BASE TABLE' AND table_collation <> 'utf8mb4_unicode_ci';
