-- =====================================================
-- Limpieza de datos: Dirty Cafe Sales (Kaggle) en MySQL
-- Autor: Piero S. Cafarelli
-- Dataset: https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training
-- Motor: MySQL 8 (MySQL Workbench)
--
-- CÓMO EJECUTARLO
--   Parte 1: ejecutar el PASO 0 (crea la base de datos y la tabla vacía).
--   Importar: clic derecho en la tabla dirty_cafe_sales > Table Data Import Wizard
--             > elegir dirty_cafe_sales.csv > "Use existing table" > Next hasta terminar.
--   Parte 2: ejecutar el resto del script desde el PASO 1.
-- =====================================================


-- -----------------------------------------------------
-- 0. PREPARACIÓN: base de datos y tabla vacía
-- Todas las columnas son texto porque el archivo original mezcla
-- números con 'ERROR', 'UNKNOWN' y celdas vacías. Si se importan
-- como números, MySQL descarta esas filas y se pierden datos.
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

-- >>> AQUÍ: importar dirty_cafe_sales.csv con el Table Data Import Wizard <<<


-- -----------------------------------------------------
-- Comprobación de la importación (debe dar 10000)
-- -----------------------------------------------------

USE master_ebis;
SET SQL_SAFE_UPDATES = 0;

SELECT COUNT(*) AS total_filas FROM dirty_cafe_sales;

-- -----------------------------------------------------
-- 1. PAYMENT METHOD
-- -----------------------------------------------------

SELECT `Payment Method`, COUNT(*) as cantidad
FROM dirty_cafe_sales
GROUP BY `Payment Method`;

UPDATE dirty_cafe_sales
SET `Payment Method` = NULL
WHERE `Payment Method` = ''
   OR `Payment Method` = 'UNKNOWN'
   OR `Payment Method` = 'ERROR';

SELECT `Payment Method`, COUNT(*) as cantidad
FROM dirty_cafe_sales
GROUP BY `Payment Method`;

-- -----------------------------------------------------
-- 2. LOCATION
-- -----------------------------------------------------

UPDATE dirty_cafe_sales
SET `Location` = NULL
WHERE `Location` = ''
   OR `Location` = 'UNKNOWN'
   OR `Location` = 'ERROR';   

-- -----------------------------------------------------
-- 3. QUANTITY
-- -----------------------------------------------------

SELECT `Quantity`, COUNT(*) as registros
FROM dirty_cafe_sales
GROUP BY `Quantity`
ORDER BY registros DESC;

-- Fase A: Reconstruir la cantidad con matemáticas (Total / Precio)
UPDATE dirty_cafe_sales
SET `Quantity` = CAST(`Total Spent` / `Price Per Unit` AS SIGNED)
WHERE (`Quantity` = 'ERROR' OR `Quantity` = 'UNKNOWN' OR `Quantity` = '')
  AND `Price Per Unit` NOT IN ('ERROR', 'UNKNOWN', '', '0')
  AND `Total Spent` NOT IN ('ERROR', 'UNKNOWN', '');

-- Fase B: Mandar los remanentes irrecuperables a NULL definitivo
UPDATE dirty_cafe_sales
SET `Quantity` = NULL
WHERE `Quantity` = 'ERROR'
   OR `Quantity` = 'UNKNOWN'
   OR `Quantity` = '';

SELECT `Quantity`, COUNT(*) as registros
FROM dirty_cafe_sales
GROUP BY `Quantity`
ORDER BY registros DESC;

-- -----------------------------------------------------
-- 4. PRICE PER UNIT (Perfilado obligatorio: auditar los precios)
-- -----------------------------------------------------

SELECT `Price Per Unit`, COUNT(*) as registros
FROM dirty_cafe_sales
GROUP BY `Price Per Unit`
ORDER BY registros DESC;

-- Fase A: Reconstruir el precio unitario con matemáticas (Total / Cantidad)
UPDATE dirty_cafe_sales
SET `Price Per Unit` = CAST(`Total Spent` / `Quantity` AS DECIMAL(10,2))
WHERE (`Price Per Unit` = 'ERROR' OR `Price Per Unit` = 'UNKNOWN' OR `Price Per Unit` = '')
  -- El escudo: solo si tenemos cantidad real (mayor a 0) y el total está limpio

  -- se revisa aparte con IS NOT NULL
  AND `Quantity` IS NOT NULL AND `Quantity` <> '0'
  AND `Total Spent` NOT IN ('ERROR', 'UNKNOWN', '');

-- Fase B: Mandar los remanentes irrecuperables a NULL definitivo
UPDATE dirty_cafe_sales
SET `Price Per Unit` = NULL
WHERE `Price Per Unit` = 'ERROR'
   OR `Price Per Unit` = 'UNKNOWN'
   OR `Price Per Unit` = '';

-- -----------------------------------------------------
-- 5. TOTAL SPENT (auditar el total gastado)
-- -----------------------------------------------------

SELECT `Total Spent`, COUNT(*) as registros
FROM dirty_cafe_sales
GROUP BY `Total Spent`
ORDER BY registros DESC;

-- Fase A: Reconstruir el Total Gastado con la multiplicación (Cantidad * Precio)
UPDATE dirty_cafe_sales
SET `Total Spent` = CAST(`Quantity` * `Price Per Unit` AS DECIMAL(10,2))
WHERE (`Total Spent` = 'ERROR' OR `Total Spent` = 'UNKNOWN' OR `Total Spent` = '')
  -- El escudo: solo si la cantidad y el precio ya son números válidos
  
  AND `Quantity` IS NOT NULL AND `Quantity` <> '0'
  AND `Price Per Unit` IS NOT NULL AND `Price Per Unit` <> '0';

-- Fase B: Mandar los remanentes irrecuperables a NULL definitivo
UPDATE dirty_cafe_sales
SET `Total Spent` = NULL
WHERE `Total Spent` = 'ERROR'
   OR `Total Spent` = 'UNKNOWN'
   OR `Total Spent` = '';

-- -----------------------------------------------------
-- 6. TRANSACTION DATE
-- -----------------------------------------------------

SELECT `Transaction Date`, COUNT(*) AS cantidad
FROM dirty_cafe_sales
GROUP BY `Transaction Date`;

ALTER TABLE dirty_cafe_sales ADD COLUMN fecha_limpia DATE;

UPDATE dirty_cafe_sales
SET fecha_limpia = STR_TO_DATE(`Transaction Date`, '%Y-%m-%d')
WHERE `Transaction Date` NOT IN ('ERROR', 'UNKNOWN', '');

SELECT `Transaction Date`, fecha_limpia
FROM dirty_cafe_sales
LIMIT 20;

ALTER TABLE dirty_cafe_sales DROP COLUMN `Transaction Date`;

-- -----------------------------------------------------
-- 7. ITEM (normalización de productos)
-- Reemplazamos los errores, incógnitas o celdas vacías
-- -----------------------------------------------------

UPDATE dirty_cafe_sales
SET `Item` = NULL
WHERE `Item` = 'ERROR'
   OR `Item` = 'UNKNOWN'
   OR `Item` = '';

-- ===================================================
-- PASO FINAL: OPTIMIZACIÓN Y CAMBIO DE TIPOS DE DATOS
-- ===================================================

ALTER TABLE dirty_cafe_sales
MODIFY COLUMN `Quantity` INT NULL,
MODIFY COLUMN `Price Per Unit` DECIMAL(10,2) NULL,
MODIFY COLUMN `Total Spent` DECIMAL(10,2) NULL;

-- Resultado final
SELECT * FROM dirty_cafe_sales LIMIT 20;

SET SQL_SAFE_UPDATES = 1;
