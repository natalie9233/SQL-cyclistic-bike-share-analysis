-- A. 檢查來源資料

-- total number of rows
select count(ride_id)
from smooth-reason-511909-r7.Divvy_Trips_2020_Q1.Divvy_Trips_2020_Q1;

-- distinct values
select count(distinct ride_id)
from smooth-reason-511909-r7.Divvy_Trips_2020_Q1.Divvy_Trips_2020_Q1;

-- ride length
select TIMESTAMP_DIFF(ended_at, started_at, SECOND) ride_length
from smooth-reason-511909-r7.Divvy_Trips_2020_Q1.Divvy_Trips_2020_Q1
where TIMESTAMP_DIFF(ended_at, started_at, SECOND)  < 0;

-- maximum, minimum, or mean values.
select max(ride_length_minutes) max_ride_length,
min(ride_length_minutes) min_ride_length,
round(avg(ride_length_minutes), 2) avg_ride_length
from(
  select TIMESTAMP_DIFF(ended_at, started_at, SECOND) / 60 ride_length_minutes
from smooth-reason-511909-r7.Divvy_Trips_2020_Q1.Divvy_Trips_2020_Q1
)
where ride_length_minutes > 0;

-- B. 建立合併表。下段為原始 CREATE OR REPLACE，執行會重建 all_rides。

-- creat union table
CREATE OR REPLACE TABLE `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides` AS
WITH combined AS (
  SELECT
  CAST(trip_id AS STRING) AS ride_id,
  CAST(start_time AS TIMESTAMP) AS started_at,
  CAST(end_time AS TIMESTAMP) AS ended_at,
  cast(from_station_name as string) start_station_name,
  cast(to_station_name as string)end_station_name,
  CASE usertype
    WHEN 'Subscriber' THEN 'member'
    WHEN 'Customer' THEN 'casual'
    END 
    AS member_casual,
  ROUND(TIMESTAMP_DIFF(CAST(end_time AS TIMESTAMP), CAST(start_time AS TIMESTAMP), SECOND) / 60, 2) AS ride_length_minutes
  FROM `smooth-reason-511909-r7.Divvy_Trips_2019_Q1.Divvy_Trips_2019_Q1`

UNION ALL

SELECT
  ride_id,
  started_at,
  ended_at,
  start_station_name,
  end_station_name,
  member_casual,
  round(TIMESTAMP_DIFF(ended_at, started_at, SECOND) / 60,2) ride_length_minutes
FROM `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.Divvy_Trips_2020_Q1`
)
SELECT *
FROM combined
WHERE ended_at > started_at
AND NOT (
  COALESCE(TRIM(start_station_name), '') = 'HQ QR'
  AND COALESCE(TRIM(end_station_name), '') = 'HQ QR'
);
