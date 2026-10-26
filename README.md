# Cafe Sales — Data Cleaning with MySQL

Cleaning a deliberately messy dataset of 10,000 cafe transactions, using only SQL in MySQL, to produce an analysis-ready table.

**Dataset:** [Cafe Sales – Dirty Data for Cleaning Training (Kaggle)](https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training)
**Tools:** MySQL 8, MySQL Workbench

---

## The problem

The raw file `dirty_cafe_sales.csv` has 10,000 rows and 8 columns:

| Column | Description |
| --- | --- |
| Transaction ID | Unique ID of the sale |
| Item | Product sold (Coffee, Cake, Sandwich…) |
| Quantity | Units sold |
| Price Per Unit | Unit price |
| Total Spent | Quantity × Price Per Unit |
| Payment Method | Cash, Credit Card, Digital Wallet |
| Location | In-store or Takeaway |
| Transaction Date | Date of the sale |

Data quality issues found:

- Placeholder values instead of real data: `ERROR`, `UNKNOWN` and blanks
- Numbers and dates stored as text
- Missing values in key columns (item, quantity, price, total)

## Cleaning steps

Every column follows the same approach: **profile** it with `GROUP BY`, **recover** what business logic allows, and turn the remaining placeholders into `NULL`.

1. **Profiling** — reviewed each column with `GROUP BY` to find invalid values (`ERROR`, `UNKNOWN`, blanks).
2. **Payment Method and Location** — no reliable rule to recover them, so placeholders became `NULL`.
3. **Quantity** — recovered as `Total Spent / Price Per Unit`; unrecoverable values set to `NULL`.
4. **Price Per Unit** — recovered as `Total Spent / Quantity`; unrecoverable values set to `NULL`.
5. **Total Spent** — recovered as `Quantity × Price Per Unit`; unrecoverable values set to `NULL`.
6. **Transaction Date** — converted from text to a real `DATE` column with `STR_TO_DATE`.
7. **Item** — placeholders set to `NULL`.
8. **Data types** — Quantity to `INT`, prices and totals to `DECIMAL(10,2)`.

## How to run

1. Run step 0 of `cleaning.sql` to create the database and an empty table (all columns as text).
2. Import `dirty_cafe_sales.csv` into that table with MySQL Workbench's *Table Data Import Wizard* → *Use existing table*.
3. Run the rest of the script.

## Files

- `cleaning.sql` — full cleaning script, commented step by step

## Next steps

- Build a Power BI dashboard on the clean data: sales by product, payment method and month.

---

**Author:** Piero Cafarelli Ferrante· [LinkedIn](https://www.linkedin.com/in/piero-sapiente-cafarelli-ferrante-1a2957223)
