-- Check collation and charset of tables
SELECT T.table_name, CCSA.character_set_name,CCSA.collation_name FROM information_schema.`TABLES` T, information_schema.`COLLATION_CHARACTER_SET_APPLICABILITY` CCSA WHERE CCSA.collation_name = T.table_collation AND T.table_schema = schema_name;

-- Find table columns that are not 'utf8_general_ci'
SELECT table_name,column_name,character_set_name,collation_name FROM information_schema.`COLUMNS`  WHERE table_schema = schema_name AND collation_name IS NOT NULL AND character_set_name IS NOT NULL AND collation_name <> 'utf8_general_ci';

-- Alter
ALTER TABLE table_name CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER DATABASE schema_name CHARACTER SET utf8 COLLATE utf8_general_ci;
