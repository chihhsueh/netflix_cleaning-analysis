-- Create raw staging table for Netflix data import
-- TEXT used for title, director, cast, listed_in, and description to handle foreign characters and long values
CREATE TABLE netflix_raw (
    show_id VARCHAR(10) primary key,
    type VARCHAR(10),
    title TEXT,
    director TEXT,
    cast TEXT,
    country VARCHAR(255),
    date_added VARCHAR(50),
    release_year BIGINT,
    rating VARCHAR(50),
    duration VARCHAR(50),
    listed_in TEXT,
    description TEXT
);
