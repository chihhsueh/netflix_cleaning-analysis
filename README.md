# Netflix Data Cleaning & Analysis (MySQL)

## Overview
End-to-end data cleaning and analysis of the Netflix Titles dataset (8,807 titles) using **MySQL** and **Python**. The project covers data ingestion, deduplication, normalization, missing value handling, and analytical queries.

**Dataset:** [Kaggle - Netflix Movies and TV Shows](https://www.kaggle.com/datasets/shivamb/netflix-shows)

## Project Structure

| File | Description |
|------|-------------|
| `netflix_data_extraction.py` | Downloads dataset from Kaggle, runs EDA sanity checks, and loads data into MySQL |
| `netflix_raw.sql` | Creates the raw staging table schema with appropriate data types |
| `netflix_data_cleaning.sql` | 5-step cleaning pipeline: foreign characters, dedup, normalization, missing values, final table |
| `netflix_data_analysis.sql` | 5 analytical queries exploring directors, genres, countries, and duration |
| `Netflix - Technical Documentation.docx` | Detailed documentation of observations, decisions, and errors encountered |

## Data Cleaning Pipeline

**Step 1: Handle Foreign Characters**
Used TEXT fields during table creation to support UTF-8 encoding. Without this, titles with accents and non-Latin characters would not display in MySQL.

**Step 2: Remove Duplicate Records**
Used a CTE with ROW_NUMBER() to identify duplicates. Initial dedup using only title and type incorrectly removed 4 rows instead of 3. Investigation revealed that "Veronica" (Spain, Paco Plaza) and "Verónica" (Mexico, Martinez-Beltran) are different films that MySQL's accent-insensitive collation treated as matches. Fixed by adding release_year and director to the partition criteria.

**Step 3: Normalize Multi-Value Columns**
Split comma-separated columns (director, cast, country, listed_in) into four normalized lookup tables. MySQL lacks SQL Server's STRING_SPLIT, so used a recursive CTE with SUBSTRING_INDEX as a workaround.

**Step 4: Handle Missing Values**
Built a director-country lookup by joining netflix_directors and netflix_countries, then used INSERT INTO to populate missing country values based on what country the director's other titles are from.

**Step 5: Create Final Clean Table**
Combined dedup, date conversion, duration fix, and column drop into a single CREATE TABLE statement.
- `CAST(date_added AS DATE)` failed with *Error Code: 1292: Incorrect datetime value* because MySQL cannot parse "July 19, 2019" directly. Switched to `STR_TO_DATE(date_added, '%M %d, %Y')`.
- Duration nulls were caused by values being incorrectly stored in the rating column. Used `CASE WHEN duration IS NULL THEN rating ELSE duration END` to fix.
- Initially encountered *Error Code: 1327: Undeclared variable: netflix* because `INTO` was included alongside `CREATE TABLE`. Removing it resolved the issue.

**Final result:** 8,804 rows, 8 columns, 4 normalized lookup tables.

## Analysis Questions

1. **Directors with both Movies and TV Shows** — Conditional aggregation with COUNT(CASE WHEN), filtered with HAVING COUNT(DISTINCT type) > 1
2. **Country with most comedy movies** — Three-table JOIN across normalized tables with LIMIT 1
3. **Top director per year by movie count** — Chained CTEs with ROW_NUMBER() window function (top N per group pattern)
4. **Average movie duration by genre** — String manipulation with REPLACE and CAST to convert "90 min" to numeric for AVG
5. **Directors who made both horror and comedy** — COUNT(DISTINCT CASE WHEN) with HAVING COUNT(DISTINCT genre) = 2

## Tools
- MySQL 8.0 (MySQL Workbench)
- Python (pandas, sqlalchemy, kagglehub)
- Jupyter Notebook

## Roadblocks & Lessons Learned
- **MySQL vs SQL Server differences:** No STRING_SPLIT, no CROSS APPLY, no SELECT INTO for table creation. Required workarounds throughout the project.
- **Accent-insensitive collation:** MySQL's default collation treated "Veronica" and "Verónica" as duplicates. Adding more columns to the partition criteria caught the false positive.
- **Date parsing:** MySQL's CAST cannot handle written date formats like "July 19, 2019". STR_TO_DATE with explicit format strings is required.
- **Misplaced data:** Duration values were stored in the rating column for some rows, requiring a CASE WHEN fix rather than a simple null fill.
