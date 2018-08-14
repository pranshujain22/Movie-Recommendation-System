use movie_db1;

SELECT t.movieid as movieid, t.counts as rating_count, t.average as avg_rating, SUBSTRING(movies_orc.title, 1, 30) as movie_name, movies_orc.genres as genre FROM
(SELECT movieid, count(rating) as counts, round(avg(rating), 2) as average FROM ratings_orc GROUP BY movieid SORT BY average DESC, counts DESC	) t JOIN movies_orc ON (t.movieid = movies_orc.movieid)
WHERE counts > 10 AND array_contains(movies_orc.genres, 'Sci-Fi')
limit 15;