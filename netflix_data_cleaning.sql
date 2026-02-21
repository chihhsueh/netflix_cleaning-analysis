-- Step 1: Handle foreign characters
-- (already completed during ingestion using TEXT as a text free field)

-- Step 2: Remove duplicate records
WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY UPPER(title), type, release_year, IFNULL(director, 'NA')
            ORDER BY show_id
        ) AS rn
    FROM netflix_raw
)
SELECT *
FROM cte
WHERE rn = 1;
-- Step 3: Normalize multi-value columns, (listed in, director, country, cast)
CREATE TABLE numbers AS
WITH RECURSIVE n AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM n WHERE n <= 50
)
SELECT * FROM n;
--
CREATE TABLE netflix_directors AS
SELECT show_id,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(director, ',', n), ',', -1)) AS director
FROM netflix_raw
JOIN numbers ON n <= 1 + LENGTH(director) - LENGTH(REPLACE(director, ',', ''))
WHERE director IS NOT NULL;
--
CREATE TABLE netflix_cast AS
SELECT show_id,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', n), ',', -1)) AS cast_member
FROM netflix_raw
JOIN numbers ON n <= 1 + LENGTH(cast) - LENGTH(REPLACE(cast, ',', ''))
WHERE cast IS NOT NULL;
--
CREATE TABLE netflix_genres AS
SELECT show_id,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', n), ',', -1)) AS genre
FROM netflix_raw
JOIN numbers ON n <= 1 + LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', ''))
WHERE listed_in IS NOT NULL;
--
CREATE TABLE netflix_countries AS
SELECT show_id,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', n), ',', -1)) AS country
FROM netflix_raw
JOIN numbers ON n <= 1 + LENGTH(country) - LENGTH(REPLACE(country, ',', ''))
WHERE country IS NOT NULL;

-- Step 4: Convert date_added to DATE, COMPLETED IN STEP 6


-- Step 5: Handle missing values
INSERT INTO netflix_countries
SELECT show_id, 
	m.country 
FROM netflix_raw nr
INNER JOIN ( 
SELECT director, 
	country
FROM netflix_countries nc
INNER JOIN netflix_directors nd on nc.show_id=nd.show_id
GROUP BY director, country
) m on nr.director = m.director
WHERE nr.country IS NULL
ORDER BY show_id;

-- Step 6: Drop denormalized columns
CREATE TABLE netflix AS
WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY UPPER(title), type, release_year, IFNULL(director, 'NA')
            ORDER BY show_id
        ) AS rn
    FROM netflix_raw
)
SELECT show_id, 
	type, title, 
		STR_TO_DATE(date_added, '%M %d, %Y') AS date_added, 
		release_year,
		rating, 
        CASE WHEN duration IS NULL THEN rating ELSE duration END AS duration, 
        description
FROM cte
WHERE rn = 1;
--
SELECT * FROM netflix