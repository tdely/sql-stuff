-- Find invalid/broken views.
-- table_rows must be touched to evaluate the view and set table_comment (MariaDB 10.1.26)
SELECT table_name,
       table_schema
FROM information_schema.tables
      WHERE table_type='VIEW'
            AND table_rows IS NULL
            AND table_comment LIKE "%invalid%";
