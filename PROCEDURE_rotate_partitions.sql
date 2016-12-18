CREATE PROCEDURE `Rotate_partitions`(`Database_param` TEXT, `Table_param` TEXT, `Unit_param` TEXT, `UnitsToKeep_param` INT)
BEGIN

    -- Values
    DECLARE `OldPartitionName_val` TEXT;
    DECLARE `OldPartitionDescription_val` TEXT;

    DECLARE `NewPartitionName` CHAR(9);
    DECLARE `NewPartitionDescription` CHAR(10);

    DECLARE `CreatePartition` TINYINT DEFAULT 1;
    DECLARE `DropPartition` TINYINT;

    -- Cursor and loop control
    DECLARE `OutOfRows` BOOLEAN;
    DECLARE `RowCount` INT DEFAULT 0;

    DECLARE `c` CURSOR FOR
      SELECT `PARTITION_NAME`,
             Str_to_date(PARTITION_DESCRIPTION, '''%Y-%m-%d''')
      FROM   `INFORMATION_SCHEMA`.`PARTITIONS`
      WHERE  `TABLE_NAME`=`Table_param` COLLATE utf8_unicode_ci
             AND `TABLE_SCHEMA`=`Database_param` COLLATE utf8_unicode_ci;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET `OutOfRows` = TRUE;

    SELECT Concat('p', Date_format(Utc_timestamp(), '%Y%m%d')) INTO `NewPartitionName`;
    CASE UPPER(`Unit_param`)
      WHEN 'DAY' THEN SELECT Date_format(Utc_timestamp(), '%Y-%m-%d') + INTERVAL 1 DAY INTO `NewPartitionDescription`;
      WHEN 'WEEK' THEN SELECT Date_format(Utc_timestamp(), '%Y-%m-%d') + INTERVAL 1 WEEK INTO `NewPartitionDescription`;
      WHEN 'MONTH' THEN SELECT Date_format(Utc_timestamp(), '%Y-%m-%d') + INTERVAL 1 MONTH INTO `NewPartitionDescription`;
      WHEN 'QUARTER' THEN SELECT Date_format(Utc_timestamp(), '%Y-%m-%d') + INTERVAL 1 QUARTER INTO `NewPartitionDescription`;
      WHEN 'YEAR' THEN SELECT Date_format(Utc_timestamp(), '%Y-%m-%d') + INTERVAL 1 YEAR INTO `NewPartitionDescription`;
      ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Invalid time unit given for Rotate_partitions";
    END CASE;

    OPEN `c`;
    SELECT Found_rows() INTO `RowCount`;

    `HandleOldPartitions`: LOOP

      FETCH `c`
       INTO `OldPartitionName_val`,
            `OldPartitionDescription_val`;

      IF `OutOfRows` THEN
        CLOSE `c`;
        LEAVE `HandleOldPartitions`;
      END IF;

      SET `DropPartition` = 0;

      -- MAXVALUE will be NULL through Str_to_date
      IF `OldPartitionDescription_val` IS NULL THEN
        ITERATE `HandleOldPartitions`;
      END IF;

      CASE UPPER(`Unit_param`)
        WHEN 'DAY' THEN SELECT `OldPartitionDescription_val` < Utc_timestamp() - INTERVAL `UnitsToKeep_param` DAY INTO DropPartition;
        WHEN 'WEEK' THEN SELECT `OldPartitionDescription_val` < Utc_timestamp() - INTERVAL `UnitsToKeep_param` WEEK INTO DropPartition;
        WHEN 'MONTH' THEN SELECT `OldPartitionDescription_val` < Utc_timestamp() - INTERVAL `UnitsToKeep_param` MONTH INTO DropPartition;
        WHEN 'QUARTER' THEN SELECT `OldPartitionDescription_val` < Utc_timestamp() - INTERVAL `UnitsToKeep_param` QUARTER INTO DropPartition;
        WHEN 'YEAR' THEN SELECT `OldPartitionDescription_val` < Utc_timestamp() - INTERVAL `UnitsToKeep_param` YEAR INTO DropPartition;
      END CASE;

      IF DropPartition > 0 THEN
        SET @sql := Concat('ALTER TABLE ', `Database_param`, '.', `Table_param`, ' DROP PARTITION ', `OldPartitionName_val` , ';');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;

      IF `OldPartitionName_val` = `NewPartitionName` THEN
        SET CreatePartition = 0;
      END IF;

    END LOOP;

    IF `CreatePartition` = 1 THEN
      SET @sql := Concat('ALTER TABLE ', `Database_param`, '.', `Table_param`, ' REORGANIZE PARTITION pEOW INTO ('
                         , 'PARTITION ', `NewPartitionName`, ' VALUES LESS THAN ("', `NewPartitionDescription`, '"), '
                         , 'PARTITION pEOW VALUES LESS THAN (MAXVALUE)'
                         , ');');
      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END IF;

END