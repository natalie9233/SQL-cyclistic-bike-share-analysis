-- 2019 Q1 與 2020 Q1：騎乘行為分析
-- 已有 all_rides 時，選取需要的 SELECT 或 WITH 段落執行。

-- A. 確認合併結果與比較兩組騎乘行為

-- 1看看騎乘資料
select *
from smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides
limit 10;

-- 2 2019 Q1 vs. 2020 Q1 騎乘概況
with q1_summary as(
  select
  extract(year from started_at) as ride_year,
  member_casual,
  count(*) as ride_count,
  round(avg(ride_length_minutes), 2) AVG_ride_length_minutes,
  max(ride_length_minutes) as `Max Ride Minutes`
from `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides`
group by ride_year, member_casual
)
select ride_year,
member_casual,
ride_count,
round(ride_count / sum(ride_count) over(partition by ride_year)*100, 2) ride_percentage,
AVG_ride_length_minutes,
`Max Ride Minutes`
from q1_summary
order by ride_year, member_casual
;
-- monthly
select
  date_trunc(date(started_at), month) as month,
  countif(member_casual = 'member') as member_ride_count,
  round(100.0 * countif(member_casual = 'member') / count(*), 2) as member_ride_pct,
  round(avg(if(member_casual = 'member', ride_length_minutes, null)), 2)
    as member_avg_minutes,
  countif(member_casual = 'casual') as casual_ride_count,
  round(100.0 * countif(member_casual = 'casual') / count(*), 2) as casual_ride_pct,
  round(avg(if(member_casual = 'casual', ride_length_minutes, null)), 2)
    as casual_avg_minutes
from `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides`
group by month
order by extract(month from month), month;
-- week
select
  extract(year from started_at) as ride_year,
  mod(extract(dayofweek from started_at) + 5, 7) + 1 as day_of_week,
  countif(member_casual = 'member') as member_ride_count,
   round(100.0 * countif(member_casual = 'member') / count(*), 2) as member_ride_pct,
  round(avg(if(member_casual = 'member', ride_length_minutes, null)), 2)
    as member_avg_minutes,
  countif(member_casual = 'casual') as casual_ride_count,
  round(100.0 * countif(member_casual = 'casual') / count(*), 2) as casual_ride_pct,
  round(avg(if(member_casual = 'casual', ride_length_minutes, null)), 2)
    as casual_avg_minutes
from `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides`
group by ride_year, day_of_week
order by ride_year, day_of_week;

-- B. 比較第一季、每月與同月同比

-- 1 2019 Q1與 2020 Q1同月比較成長率
with gp as (
  select
    extract(month from started_at) as month,
    countif(extract(year from started_at) = 2019) as ride_count_2019,
    countif(extract(year from started_at) = 2020) as ride_count_2020,
    countif(extract(year from started_at) = 2019 and member_casual = 'member') as member_count_2019,
    countif(extract(year from started_at) = 2020 and member_casual = 'member') as member_count_2020,
    countif(extract(year from started_at) = 2019 and member_casual = 'casual') as casual_count_2019,
    countif(extract(year from started_at) = 2020 and member_casual = 'casual') as casual_count_2020
  from `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides`
  where ride_length_minutes > 0
  group by month
)
select
  month,
  ride_count_2019,
  ride_count_2020,
  round(safe_divide(ride_count_2020 - ride_count_2019, ride_count_2019) * 100, 2) as growth_percentage,
  member_count_2019,
  member_count_2020,
  round(safe_divide(member_count_2020 - member_count_2019, member_count_2019) * 100, 2) as member_growth_percentage,
  casual_count_2019,
  casual_count_2020,
  round(safe_divide(casual_count_2020 - casual_count_2019, casual_count_2019) * 100, 2) as casual_growth_percentage,
from gp
order by month;

-- C. 觀察熱門站點、會員占比與起訖站配對

-- 1 比較 2019 Q1 與 2020 Q1 的熱門出發站
with station_counts as (
  select
    extract(year from started_at) as ride_year,
    start_station_name,
    count(*) as ride_count,
    round(countif(member_casual = 'member') / count(*) * 100, 2) as member_percentage,
    round(countif(member_casual = 'casual') / count(*) * 100, 2) as casual_percentage
  from `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides`
  where nullif(trim(start_station_name), '') is not null
  group by ride_year, start_station_name
),
ranked_stations as (
  select *,
    dense_rank() over (
      partition by ride_year
      order by ride_count desc
    ) as ranking
  from station_counts
)
select
  ranking,
  string_agg(if(ride_year = 2019, start_station_name, null), ' | ' order by start_station_name) as start_station_name_2019,
  max(if(ride_year = 2019, ride_count, null)) as ride_count_2019,
  string_agg(if(ride_year = 2019, format('%.2f%%', member_percentage), null), ' | ' order by start_station_name) as member_percentage_2019,
  string_agg(if(ride_year = 2019, format('%.2f%%', casual_percentage), null), ' | ' order by start_station_name) as casual_percentage_2019,
  string_agg(if(ride_year = 2020, start_station_name, null), ' | ' order by start_station_name) as start_station_name_2020,
  max(if(ride_year = 2020, ride_count, null)) as ride_count_2020,
  string_agg(if(ride_year = 2020, format('%.2f%%', member_percentage), null), ' | ' order by start_station_name) as member_percentage_2020,
  string_agg(if(ride_year = 2020, format('%.2f%%', casual_percentage), null), ' | ' order by start_station_name) as casual_percentage_2020
from ranked_stations
group by ranking
order by ranking;

-- 2 比較 2019 Q1 與 2020 Q1 的熱門還車站
with station_counts as (
  select
    extract(year from started_at) as ride_year,
    end_station_name,
    count(*) as ride_count,
    round(countif(member_casual = 'member') / count(*) * 100, 2) as member_percentage,
    round(countif(member_casual = 'casual') / count(*) * 100, 2) as casual_percentage
  from `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides`
  where nullif(trim(end_station_name), '') is not null
  group by ride_year, end_station_name
),
ranked_stations as (
  select *,
    dense_rank() over (
      partition by ride_year
      order by ride_count desc
    ) as ranking
  from station_counts
)
select
  ranking,
  string_agg(if(ride_year = 2019, end_station_name, null), ' | ' order by end_station_name) as end_station_name_2019,
  max(if(ride_year = 2019, ride_count, null)) as ride_count_2019,
  string_agg(if(ride_year = 2019, format('%.2f%%', member_percentage), null), ' | ' order by end_station_name) as member_percentage_2019,
  string_agg(if(ride_year = 2019, format('%.2f%%', casual_percentage), null), ' | ' order by end_station_name) as casual_percentage_2019,
  string_agg(if(ride_year = 2020, end_station_name, null), ' | ' order by end_station_name) as end_station_name_2020,
  max(if(ride_year = 2020, ride_count, null)) as ride_count_2020,
  string_agg(if(ride_year = 2020, format('%.2f%%', member_percentage), null), ' | ' order by end_station_name) as member_percentage_2020,
  string_agg(if(ride_year = 2020, format('%.2f%%', casual_percentage), null), ' | ' order by end_station_name) as casual_percentage_2020
from ranked_stations
group by ranking
order by ranking;

-- 3 比較 2019 Q1 與 2020 Q1 的熱門路線
with route_counts as (
  select extract (year from started_at) year,
  start_station_name,
  end_station_name,
  count(*) ride_count,
  round(countif(member_casual = 'member') / count(*) * 100, 2) as member_percentage,
  round(countif(member_casual = 'casual') / count(*) * 100, 2) as casual_percentage
  from smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides
  where coalesce(trim(start_station_name), '') <> ''
  and coalesce(trim(end_station_name), '') <> ''
  group by year, start_station_name, end_station_name
  ),
rank_routes as(
  select *,
    dense_rank() over (
      partition by year
      order by ride_count desc
    ) as ranking
  from route_counts
)
select
  ranking,
  string_agg(
    if(year = 2019, concat(start_station_name, ' → ', end_station_name), null),
    ' | ' order by start_station_name, end_station_name
  ) as route_2019,
  max(if(year = 2019, ride_count, null)) as ride_count_2019,
  string_agg(
    if(year = 2019, format('%.2f%%', member_percentage), null),
    ' | ' order by start_station_name, end_station_name
  ) as member_percentage_2019,
  string_agg(
    if(year = 2019, format('%.2f%%', casual_percentage), null),
    ' | ' order by start_station_name, end_station_name
  ) as casual_percentage_2019,
  string_agg(
    if(year = 2020, concat(start_station_name, ' → ', end_station_name), null),
    ' | ' order by start_station_name, end_station_name
  ) as route_2020,
  max(if(year = 2020, ride_count, null)) as ride_count_2020,
  string_agg(
    if(year = 2020, format('%.2f%%', member_percentage), null),
    ' | ' order by start_station_name, end_station_name
  ) as member_percentage_2020,
  string_agg(
    if(year = 2020, format('%.2f%%', casual_percentage), null),
    ' | ' order by start_station_name, end_station_name
  ) as casual_percentage_2020
from rank_routes
group by ranking
order by ranking;

-- D. 2019 Q1 與 2020 Q1 合計站點與路線概覽
-- 建表與更名語句需按順序另行執行。

-- merge hot & end station
create table `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.station_rankings` as 
with `start` as(
  select start_station_name,
  count(*) ride_count,
  round(countif(member_casual='member')/count(*)*100, 2) member_percentage,
  round(countif(member_casual='casual')/count(*)*100, 2) casual_percentage,
  row_number() over(order by count(*) desc, start_station_name) rn
  from smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides
  where ride_length_minutes > 0
    and nullif(trim(start_station_name), '') is not null
  group by start_station_name
  order by rn
),
`end` as(
  select end_station_name,
  count(*) ride_count,
  round(countif(member_casual='member')/count(*)*100, 2) member_percentage,
  round(countif(member_casual='casual')/count(*)*100, 2) casual_percentage,
  row_number() over(order by count(*) desc, end_station_name) rn
  from smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides
  where ride_length_minutes > 0
    and nullif(trim(end_station_name), '') is not null
  group by end_station_name
  order by rn
)
select s.rn ranking,
s.start_station_name,
s.ride_count strat_ride_count,
s.member_percentage start_member_percentage,
s.casual_percentage start_casual_percentage,
e.end_station_name,
e.ride_count end_ride_count,
e.member_percentage end_member_percentage,
e.casual_percentage end_casual_percentage
from `start` s
join `end` e
on s.rn=e.rn
order by s.rn;

-- route combinations
create table `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.routes_combinations` AS
SELECT
  start_station_name,
  end_station_name,
  COUNT(*) ride_count,
  round(countif(member_casual='member')/count(*)*100, 2) member_percentage,
  round(countif(member_casual='casual')/count(*)*100, 2) casual_percentage,
  round(avg(ride_length_minutes), 2) ride_length_minutes
FROM `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides`
WHERE NULLIF(TRIM(start_station_name), '') IS NOT NULL
  AND NULLIF(TRIM(end_station_name), '') IS NOT NULL
GROUP BY start_station_name, end_station_name
ORDER BY ride_count DESC, start_station_name, end_station_name;

-- E. 非會員長時間騎乘：平日與週末比較

-- 各年第一季非會員平日與週末騎滿 20 分鐘的趟數及占比
select
  extract(year from started_at) as ride_year,
  case
    when extract(dayofweek from started_at) in (1, 7) then 'weekend'
    else 'weekday'
  end as day_type,
  count(*) as ride_count,
  countif(ride_length_minutes >= 20) as long_ride_count,
  format('%.2f%%', 100.0 * countif(ride_length_minutes >= 20) / count(*)) as long_ride_pct
from `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides`
where member_casual = 'casual'
group by ride_year, day_type
order by ride_year, day_type;

-- 長途騎行熱門時段
with hourly_rides as (
  select
    extract(year from started_at) as ride_year,
    case
      when extract(dayofweek from started_at) in (1, 7) then 'weekend'
      else 'weekday'
    end as day_type,
    extract(hour from started_at) as started_hour,
    count(*) as ride_count,
    countif(ride_length_minutes >= 20) as long_ride_count
  from `smooth-reason-511909-r7.Divvy_Trips_2020_Q1.all_rides`
  where member_casual = 'casual'
  group by ride_year, day_type, started_hour
)
select
  ride_year,
  day_type,
  started_hour,
  ride_count,
  long_ride_count,
  format('%.2f%%', 100.0 * long_ride_count / ride_count) as long_ride_pct
from hourly_rides
where long_ride_count > 0
qualify dense_rank() over (
  partition by ride_year, day_type
  order by long_ride_count desc
) = 1
order by ride_year, day_type, started_hour;