-- =====================================================
-- Data Cleaning: Dirty Cafe Sales (Kaggle) in MySQL
-- Author: Piero S. Cafarelli
-- Dataset: https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training
-- Engine: MySQL 8 (MySQL Workbench)
--
-- HOW TO RUN
--   Part 1: run STEP 0 (creates the database and an empty table).
--   Import: right-click the dirty_cafe_sales table > Table Data Import Wizard
--           > choose dirty_cafe_sales.csv > "Use existing table" > Next until done.
--   Part 2: run the rest of the script from STEP 1.
-- =====================================================


-- -----------------------------------------------------
-- 0. SETUP: database and empty table
-- All columns are text because the raw file mixes numbers
-- with 'ERROR', 'UNKNOWN' and blank cells. If they were imported
-- as numbers, MySQL would skip those rows and data would be lost.
-- -----------------------------------------------------

CREATE DATABASE IF NOT EXISTS master_ebis;
USE master_ebis;

DROP TABLE IF EXISTS dirty_cafe_sales;

CREATE TABLE dirty_cafe_sales (
    `Transaction ID`   VARCHAR(50),
    `Item`             VARCHAR(50),
    `Quantity`         VARCHAR(20),
    `Price Per Unit`   VARCHAR(20),
    `Total Spent`      VARCHAR(20),
    `Payment Method`   VARCHAR(50),
    `Location`         VARCHAR(50),
    `Transaction Date` VARCHAR(20)
);

-- >>> HERE: import dirty_cafe_sales.csv with the Table Data Import Wizard <<<


-- -----------------------------------------------------
-- Import check (expected: 10000)
-- -----------------------------------------------------

USE master_ebis;
SET SQL_SAFE_UPDATES = 0;

SELECT COUNT(*) AS total_rows FROM dirty_cafe_sales;

-- -----------------------------------------------------
-- 1. PAYMENT METHOD
-- No rule can recover it, so placeholders become NULL.
-- -----------------------------------------------------

SELECT `Payment Method`, COUNT(*) AS records
FROM dirty_cafe_sales
GROUP BY `Payment Method`;

UPDATE dirty_cafe_sales
SET `Payment Method` = NULL
WHERE `Payment Method` = ''
   OR `Payment Method` = 'UNKNOWN'
   OR `Payment Method` = 'ERROR';

SELECT `Payment Method`, COUNT(*) AS records
FROM dirty_cafe_sales
GROUP BY `Payment Method`;

-- -----------------------------------------------------
-- 2. LOCATION
-- No rule can recover it, so placeholders become NULL.
-- -----------------------------------------------------

SELECT `Location`, COUNT(*) AS records
FROM dirty_cafe_sales
GROUP BY `Location`;

UPDATE dirty_cafe_sales
SET `Location` = NULL
WHERE `Location` = ''
   OR `Location` = 'UNKNOWN'
   OR `Location` = 'ERROR';

-- -----------------------------------------------------
-- 3. QUANTITY
-- -----------------------------------------------------

SELECT `Quantity`, COUNT(*) AS records
FROM dirty_cafe_sales
GROUP BY `Quantity`
ORDER BY records DESC;

-- Phase A: rebuild the quantity with math (Total / Price)
UPDATE dirty_cafe_sales
SET `Quantity` = CAST(`Total Spent` / `Price Per Unit` AS SIGNED)
WHERE (`Quantity` = 'ERROR' OR `Quantity` = 'UNKNOWN' OR `Quantity` = '')
  AND `Price Per Unit` NOT IN ('ERROR', 'UNKNOWN', '', '0')
  AND `Total Spent` NOT IN ('ERROR', 'UNKNOWN', '');

-- Phase B: values that cannot be recovered become NULL
UPDATE dirty_cafe_sales
SET `Quantity` = NULL
WHERE `Quantity` = 'ERROR'
   OR `Quantity` = 'UNKNOWN'
   OR `Quantity` = '';

SELECT `Quantity`, COUNT(*) AS records
FROM dirty_cafe_sales
GROUP BY `Quantity`
ORDER BY records DESC;

-- -----------------------------------------------------
-- 4. PRICE PER UNIT
-- -----------------------------------------------------

SELECT `Price Per Unit`, COUNT(*) AS records
FROM dirty_cafe_sales
GROUP BY `Price Per Unit`
ORDER BY records DESC;

-- Phase A: rebuild the unit price with math (Total / Quantity)
UPDATE dirty_cafe_sales
SET `Price Per Unit` = CAST(`Total Spent` / `Quantity` AS DECIMAL(10,2))
WHERE (`Price Per Unit` = 'ERROR' OR `Price Per Unit` = 'UNKNOWN' OR `Price Per Unit` = '')
  -- Guard: only when quantity is a real number above 0 and the total is clean.
  -- Note: NULL is checked with IS NOT NULL, because NOT IN (..., NULL)
  -- never matches any row in SQL.
  AND `Quantity` IS NOT NULL AND `Quantity` <> '0'
  AND `Total Spent` NOT IN ('ERROR', 'UNKNOWN', '');

-- Phase B: values that cannot be recovered become NULL
UPDATE dirty_cafe_sales
SET `Price Per Unit` = NULL
WHERE `Price Per Unit` = 'ERROR'
   OR `Price Per Unit` = 'UNKNOWN'
   OR `Price Per Unit` = '';

-- -----------------------------------------------------
-- 5. TOTAL SPENT
-- -----------------------------------------------------

SELECT `Total Spent`, COUNT(*) AS records
FROM dirty_cafe_sales
GROUP BY `Total Spent`
ORDER BY records DESC;

-- Phase A: rebuild the total with math (Quantity × Price)
UPDATE dirty_cafe_sales
SET `Total Spent` = CAST(`Quantity` * `Price Per Unit` AS DECIMAL(10,2))
WHERE (`Total Spent` = 'ERROR' OR `Total Spent` = 'UNKNOWN' OR `Total Spent` = '')
  -- Guard: only when quantity and price are already valid numbers
  AND `Quantity` IS NOT NULL AND `Quantity` <> '0'
  AND `Price Per Unit` IS NOT NULL AND `Price Per Unit` <> '0';

-- Phase B: values that cannot be recovered become NULL
UPDATE dirty_cafe_sales
SET `Total Spent` = NULL
WHERE `Total Spent` = 'ERROR'
   OR `Total Spent` = 'UNKNOWN'
   OR `Total Spent` = '';

-- -----------------------------------------------------
-- 6. TRANSACTION DATE
-- Text is converted into a real DATE column.
-- -----------------------------------------------------

SELECT `Transaction Date`, COUNT(*) AS records
FROM dirty_cafe_sales
GROUP BY `Transaction Date`;

ALTER TABLE dirty_cafe_sales ADD COLUMN clean_date DATE;

UPDATE dirty_cafe_sales
SET clean_date = STR_TO_DATE(`Transaction Date`, '%Y-%m-%d')
WHERE `Transaction Date` NOT IN ('ERROR', 'UNKNOWN', '');

-- Compare old and new values before dropping the original column
SELECT `Transaction Date`, clean_date
FROM dirty_cafe_sales
LIMIT 20;

ALTER TABLE dirty_cafe_sales DROP COLUMN `Transaction Date`;

-- -----------------------------------------------------
-- 7. ITEM
-- Errors, unknowns and blank cells become NULL.
-- -----------------------------------------------------

UPDATE dirty_cafe_sales
SET `Item` = NULL
WHERE `Item` = 'ERROR'
   OR `Item` = 'UNKNOWN'
   OR `Item` = '';

-- ===================================================
-- FINAL STEP: DATA TYPES
-- Text columns become numbers.
-- ===================================================

ALTER TABLE dirty_cafe_sales
MODIFY COLUMN `Quantity` INT NULL,
MODIFY COLUMN `Price Per Unit` DECIMAL(10,2) NULL,
MODIFY COLUMN `Total Spent` DECIMAL(10,2) NULL;

-- Final result
SELECT * FROM dirty_cafe_sales LIMIT 20;

SET SQL_SAFE_UPDATES = 1;
