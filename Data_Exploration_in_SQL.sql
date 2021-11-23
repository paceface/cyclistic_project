-- This exploration happened in Google's BigQuery SQL workspace

-- Data cleaning

-- Find and remove rides that started or stopped at a maintenance facility.
-- Maintenance facilities names and ids seem to contain the words TEST
SELECT start_station_id, start_station_name, end_station_id, end_station_name
FROM `cyclistic.ride_data`
WHERE end_station_id LIKE '%TEST%'
OR end_station_name LIKE '%TEST%'
OR start_station_id LIKE '%TEST%'
OR start_station_name LIKE '%TEST%';

DELETE
FROM `cyclistic.ride_data`
WHERE end_station_id LIKE '%TEST%'
OR end_station_name LIKE '%TEST%'
OR start_station_id LIKE '%TEST%'
OR start_station_name LIKE '%TEST%';


-- Data exploration


-- Find total rides for each user type
SELECT member_casual, count(*) as total_ride
FROM `cyclistic.ride_data`
GROUP BY member_casual


-- Find average ride length for each user type
-- Create view with initial calculations: number of total rides and total length of all rides (in seconds)
CREATE VIEW cyclistic.calc_avg_ride(member_casual, num_rides, total_seconds) AS
    SELECT member_casual, COUNT(*) as num_rides, SUM(((EXTRACT(hour FROM ride_length) * 3600) + (EXTRACT(minute FROM ride_length) * 60) + EXTRACT(second FROM ride_length))) as total_seconds
    FROM `cyclistic.ride_data`
    GROUP BY member_casual

-- Use view to calculate average, in minutes
SELECT member_casual, num_rides, total_seconds/num_rides/60 AS avg_ride
FROM `cyclistic.calc_avg_ride`


-- Find total rides, avg number of rides, and ride length for each day of the week for each user type
-- Total number of rides
SELECT day_of_week, member_casual, count(*) as num_rides
FROM `cyclistic.ride_data`
GROUP BY day_of_week, member_casual

-- Create view with initial calculations per day of the week, per user type: num_rides, total_seconds
CREATE VIEW cyclistic.calc_avg_ride_day(num_rides, total_seconds, day_of_week, member_casual) AS
    SELECT count(*) as num_rides, SUM(((EXTRACT(hour FROM ride_length) * 3600) + (EXTRACT(minute FROM ride_length) * 60) + EXTRACT(second FROM ride_length))) as total_seconds, day_of_week, member_casual
    FROM `cyclistic.ride_data`
    GROUP BY day_of_week, member_casual

-- Use view to calculate average number of rides, and ride length in minutes
SELECT day_of_week, member_casual,
    total_seconds/num_rides/60 AS avg_ride_length,
    num_rides/52 AS avg_num_rides
FROM `cyclistic.calc_avg_ride_day`


-- Find total number of rides and average ride length for each month for each user type
-- Create view with initial calculations per month, per user type: num_rides, total_seconds
CREATE VIEW cyclistic.calc_avg_ride_month(month, num_rides, total_seconds, member_casual) AS
    SELECT DISTINCT EXTRACT(MONTH FROM started_at) AS month, count(*) as num_rides, SUM(((EXTRACT(hour FROM ride_length) * 3600) + (EXTRACT(minute FROM ride_length) * 60) + EXTRACT(second FROM ride_length))) as total_seconds, member_casual
    FROM `cyclistic.ride_data`
    GROUP BY month, member_casual
    ORDER BY month ASC

-- Use view to calculate average ride length in minutes
SELECT month, member_casual, num_rides, total_seconds/num_rides/60 AS avg_ride_length
FROM `cyclistic.calc_avg_ride_month`


-- Find which stations are the most popular for each user type
-- Create TABLE for each query to join results later on
-- Top 20 start stations for casual users
DROP TABLE IF EXISTS `cyclistic.c_start`
CREATE TABLE cyclistic.c_start(num_rides INT, station STRING, lat NUMERIC, lng NUMERIC) AS
    SELECT count(*) as num_rides, start_station_name, AVG(start_lat), AVG(start_lng)
    FROM `cyclistic.ride_data`
    WHERE start_station_name IS NOT NULL AND member_casual = 'casual'
    GROUP BY start_station_name
    ORDER BY num_rides DESC
    LIMIT 20

-- Top 20 start stations for member users
DROP TABLE IF EXISTS `cyclistic.m_start`
CREATE TABLE cyclistic.m_start (num_rides INT, station STRING, lat NUMERIC, lng NUMERIC) AS
    SELECT count(*) as num_rides, start_station_name, AVG(start_lat), AVG(start_lng)
    FROM `cyclistic.ride_data`
    WHERE start_station_name IS NOT NULL AND member_casual = 'member'
    GROUP BY start_station_name
    ORDER BY num_rides DESC
    LIMIT 20

-- Top 20 end stations for casual users
DROP TABLE IF EXISTS `cyclistic.c_end`
CREATE TABLE cyclistic.c_end(num_rides INT, station STRING, lat NUMERIC, lng NUMERIC) AS
    SELECT count(*) as num_rides, end_station_name, AVG(start_lat), AVG(start_lng)
    FROM `cyclistic.ride_data`
    WHERE end_station_name IS NOT NULL AND member_casual = 'casual'
    GROUP BY end_station_name
    ORDER BY num_rides DESC
    LIMIT 20

-- Top 20 end stations for member users
DROP TABLE IF EXISTS `cyclistic.m_end`
CREATE TABLE cyclistic.m_end(num_rides INT, station STRING, lat NUMERIC, lng NUMERIC) AS
    SELECT count(*) as num_rides, end_station_name, AVG(start_lat), AVG(start_lng)
    FROM `cyclistic.ride_data`
    WHERE end_station_name IS NOT NULL AND member_casual = 'member'
    GROUP BY end_station_name
    ORDER BY num_rides DESC
    LIMIT 20

-- Perform a join of the previous 4 tables to see what the overlap is in station popularity
-- Full outer join is used to get a complete picture of overlap, or lack thereof
SELECT
    cs.station AS cs_station,
    cs.num_rides AS cs_rides,
    ms.station AS ms_station,
    ms.num_rides AS ms_rides,
    ce.station AS ce_station,
    ce.num_rides AS ce_rides,
    me.station AS me_station,
    me.num_rides AS me_rides
FROM cyclistic.c_start cs
FULL OUTER JOIN cyclistic.c_end ce ON cs.station = ce.station
FULL OUTER JOIN cyclistic.m_start ms ON cs.station = ms.station
FULL OUTER JOIN cyclistic.m_end me ON cs.station = me.station

-- Inner join to get only startion that are on all 4 top 20 lists
SELECT
    cs.station AS station,
    cs.lat AS lat,
    cs.lng AS lng,
    cs.num_rides AS cs_rides,
    ms.num_rides AS ms_rides,
    ce.num_rides AS ce_rides,
    me.num_rides AS me_rides
FROM cyclistic.c_start cs
JOIN cyclistic.c_end ce ON cs.station = ce.station
JOIN cyclistic.m_start ms ON cs.station = ms.station
JOIN cyclistic.m_end me ON cs.station = me.station

-- JOIN the Start Station and End Station lists to determine the most popular stations for Casual users
SELECT
    cs.station AS station,
    cs.lat AS lat,
    cs.lng AS lng,
    cs.num_rides AS cs_rides,
    ce.num_rides AS ce_rides
FROM cyclistic.c_start cs
FULL OUTER JOIN cyclistic.c_end ce ON cs.station = ce.station

-- JOIN the Start Station and End Station lists to determine the most popular stations for Members
SELECT
    ms.station AS station,
    ms.lat AS lat,
    ms.lng AS lng,
    ms.num_rides AS ms_rides,
    me.num_rides AS me_rides
FROM cyclistic.m_start ms
FULL OUTER JOIN cyclistic.m_end me ON ms.station = me.station


-- Find out how many rides each type of user takes on each type of bike, what is the average ride length time for each
-- Create view with initial calculations: number of total rides and total length of all rides (in seconds)
CREATE VIEW cyclistic.calc_bike_type(member_casual, rideable_type, num_rides, total_seconds) AS
    SELECT member_casual, rideable_type, COUNT(*) as num_rides, SUM(((EXTRACT(hour FROM ride_length) * 3600) + (EXTRACT(minute FROM ride_length) * 60) + EXTRACT(second FROM ride_length))) as total_seconds
    FROM `cyclistic.ride_data`
    GROUP BY member_casual, rideable_type
-- Use view to calculate average, in minutes
SELECT member_casual, rideable_type, num_rides, total_seconds/num_rides/60 AS avg_ride
FROM `cyclistic.calc_bike_type`

-- Create a table with the station info and ride duration for a casual rides where the ride originated and finished at a station
DROP TABLE IF EXISTS `cyclistic.time_measures`
CREATE TABLE cyclistic.time_measures(
    start_station_name STRING,
    start_lat FLOAT64,
    start_lng FLOAT64,
    end_station_name STRING,
    end_lat FLOAT64,
    end_lng FLOAT64,
    ride_length_min FLOAT64) AS
SELECT
    start_station_name,
    start_lat,
    start_lng,
    end_station_name,
    end_lat,
    end_lng,
    ROUND((((EXTRACT(hour FROM ride_length) * 3600) + (EXTRACT(minute FROM ride_length) * 60) + EXTRACT(second FROM ride_length)))/ 60) as ride_length_min
FROM `rare-highway-221701.cyclistic.ride_data`
WHERE member_casual = 'casual' AND
    start_station_name IS NOT NULL AND
    end_station_name IS NOT NULL

-- Remove rows where the ride duration is not plus or minus 3 minutes of the the average ride duration of members (13.79778)
DELETE FROM `cyclistic.time_measures`
WHERE ride_length_min < 10.79778 OR ride_length_min > 16.79778


-- Get the most popular stations from this list
-- First create a view with each starting station and a count of how many rides started there
CREATE VIEW cyclistic.start_station_count(station_count, name, lat, lng) AS
SELECT
    count(*),
    start_station_name,
    AVG(start_lat),
    AVG(start_lng)
FROM `cyclistic.time_measures`
GROUP BY start_station_name

-- Create a similar view for ending stations
CREATE VIEW cyclistic.end_station_count(station_count, name, lat, lng) AS
SELECT
    count(*),
    end_station_name,
    AVG(end_lat),
    AVG(end_lng)
FROM `cyclistic.time_measures`
GROUP BY end_station_name


-- Join these two views to get a full list of stations
-- Since I'm going to limit the most popular 20 stations, I'll do an inner join to get only the station on both lists
SELECT
    ss.station_count + es.station_count AS station_count,
    ss.name AS name,
    ss.lat AS lat,
    ss.lng AS lng
FROM `cyclistic.start_station_count` ss
INNER JOIN `cyclistic.end_station_count` es ON ss.name = es.name
ORDER BY station_count DESC
LIMIT 20
