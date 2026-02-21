-- netflix data analysis

/*1  for each director count the no of movies and tv shows created by them in separate columns
for directors who have created tv shows and movies both */
SELECT nd.director
	,COUNT(CASE WHEN n.type = 'Movie' THEN n.show_id END) as no_of_movies
	,COUNT(CASE WHEN n.type = 'TV Show' THEN n.show_id END) as no_of_tvshows
FROM netflix n
INNER JOIN netflix_directors nd on n.show_id = nd.show_id
GROUP BY nd.director
HAVING COUNT(DISTINCT n.type)>1
ORDER BY no_of_movies + no_of_tvshows DESC;

-- 2 which country has highest number of comedy movies
SELECT DISTINCT genre FROM netflix_genres ORDER BY genre;

SELECT nc.country,
	COUNT(*) as comedy_count
FROM netflix_genres ng
INNER JOIN netflix_countries nc ON ng.show_id = nc.show_id
INNER JOIN netflix n ON ng.show_id = n.show_id
WHERE ng.genre = 'Comedies' AND n.type = 'Movie'
GROUP BY nc.country
ORDER BY comedy_count DESC
LIMIT 1;
-- 3 for each year (as per date added to netflix), which director has maximum number of movies released
WITH cte as (
SELECT 
	nd.director,
    YEAR(date_added) as date_year,
    COUNT(n.show_id) AS no_of_movies
FROM netflix n
INNER JOIN netflix_directors nd ON n.show_id = nd.show_id
WHERE type = 'Movie'
GROUP BY nd.director, YEAR(date_added)
)
, cte2 as (
SELECT *,
ROW_NUMBER () OVER(PARTITION BY date_year ORDER BY no_of_movies DESC, director) AS rank_num
FROM cte
-- ORDER BY date_year DESC
)
SELECT * FROM cte2 WHERE rank_num = 1;

-- 4 what is average duration of movies in each genre
SELECT 
    ng.genre, 
    ROUND(AVG(CAST(REPLACE(duration, ' min', '')AS UNSIGNED))) as avg_duration 
FROM netflix n
INNER JOIN netflix_genres ng on n.show_id = ng.show_id
WHERE type = 'Movie'
GROUP BY ng.genre
ORDER BY avg_duration DESC;
-- 5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them '
SELECT nd.director
, COUNT(DISTINCT CASE WHEN ng.genre = 'Comedies' THEN n.show_id end) as no_of_comedy 
, COUNT(DISTINCT CASE WHEN ng.genre = 'Horror Movies' THEN n.show_id end) as no_of_horror_movies
FROM netflix n
INNER JOIN netflix_genres ng on n.show_id=ng.show_id
INNER JOIN netflix_directors nd on n.show_id = nd.show_id
WHERE type = 'Movie' and ng.genre in ('Comedies', 'Horror Movies')
GROUP BY nd.director
HAVING COUNT(distinct ng.genre) =2;
