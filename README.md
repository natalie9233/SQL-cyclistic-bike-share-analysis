# Cyclistic Bike-Share Analysis in BigQuery

**Role** — Junior Data Analyst  
**Analysis period** — January–March 2019 and January–March 2020

## Business Task

I compared how members and casual riders used Cyclistic bikes in the first quarter of each year. I looked at how often they rode, how long their trips lasted, when they rode, and which stations they used. The findings help the marketing team decide where and when to test offers that encourage casual riders to become members.

## Data and Preparation

I used `Divvy_Trips_2019_Q1.csv` and `Divvy_Trips_2020_Q1.csv`. Each row represents one trip. The public trip data is anonymized, so trip counts measure usage and cannot identify individual riders or track membership conversions. [Divvy system data](https://divvybikes.com/system-data) · [Official trip archive](https://divvy-tripdata.s3.amazonaws.com/index.html)

I inspected row counts, distinct ride IDs, and ride duration in the 2020 source table. To build `all_rides`, I aligned the two schemas, mapped `Subscriber` to `member` and `Customer` to `casual`, and appended the trip records with `UNION ALL`. I calculated ride duration in minutes from the start and end timestamps. I kept trips with an end time later than their start time and excluded `HQ QR → HQ QR` test trips.

The combined table keeps trips with missing station names for overall usage analysis. Departure rankings require a start station name, return rankings require an end station name, and route rankings require both.

| Period | Source trips | Nonpositive duration | HQ QR test trips after duration filtering | Trips retained |
| --- | ---: | ---: | ---: | ---: |
| 2019 Q1 | 365,069 | 0 | 0 | 365,069 |
| 2020 Q1 | 426,887 | 210 | 3,556 | 423,121 |

## SQL Workflow

1. [Prepare and combine](01_prepare_and_combine.sql). Import both CSVs into their source tables, then run the inspection queries and the `all_rides` build. The build uses `CREATE OR REPLACE TABLE`, so rerunning that statement replaces the analysis table.
2. [Analyze rider behavior](02_analyze_rider_behavior.sql). Run the query for the section you want to inspect. A summarizes usage by quarter, month, and weekday. B compares ride counts with the same month a year earlier. C ranks departures, returns, and station pairs separately for each year. D saves the combined first-quarter results in `station_rankings` and `routes_combinations`. E compares casual rides lasting at least 20 minutes on weekdays and weekends and identifies the hours with the most such departures.

The scripts reference a specific BigQuery project and datasets. To reproduce the analysis in another project, update the table references to match the imported sources and your destination dataset. The D statements use `CREATE TABLE` and require unused destination table names when rerun.

## Key Findings

### A. First-quarter riding behavior and membership opportunities

| Period | Member rides | Casual rides | Casual share of all rides | Member average (min) | Casual average (min) |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2019 Q1 | 341,906 | 23,163 | 6.34% | 13.89 | 61.94 |
| 2020 Q1 | 378,406 | 44,715 | 10.57% | 12.68 | 103.84 |

**Casual trips grew faster than member trips.** Total rides increased by **15.90%**, and casual rides nearly doubled from **23,163 to 44,715** (**+93.04%**). Member trips grew by **10.68%**. The casual share of all rides rose from **6.34% to 10.57%**, an increase of **4.23 percentage points**. That higher volume gives the marketing team more opportunities to present a membership offer during a casual trip. The figures count trips, so the number of individual riders who could convert remains unknown.

**Casual trips lasted longer on average.** The average rose from **61.94 to 103.84 minutes**, an increase of about **68%**. Member trips averaged **13.89 minutes** in 2019 Q1 and **12.68 minutes** in 2020 Q1. Longer recorded use gives the team a reason to test a membership benefit tied to accumulated ride time. Some recorded durations exceeded 100 days and remained in the analysis, so extreme values can lift the averages. Rider trust and willingness to join would need separate evidence.

#### Busiest departure days

| Period | Members | Casual riders |
| --- | --- | --- |
| 2019 Q1 | Thursday (63,983 trips) | Saturday (5,993 trips) |
| 2020 Q1 | Tuesday (69,697 trips) | Sunday (14,886 trips) |

Weekends accounted for **42.13%** of casual trips in 2019 Q1 and **50.02%** in 2020 Q1. The corresponding shares for members were **15.66%** and **17.46%**. Weekends are therefore a candidate for testing a membership offer with casual riders. This comparison covers the same three months in both years. Assessing seasonality would require data from other parts of the year.

### B. Same-month changes in ride volume

Each percentage compares the same calendar month in 2020 and 2019.

| Month | All rides | Member rides | Casual rides |
| --- | ---: | ---: | ---: |
| January | +39.33% | +37.93% | +69.17% |
| February | +44.54% | +35.45% | +366.83% |
| March | −15.34% | −22.78% | +54.59% |

**February had the largest increase in casual rides.** Casual trips rose from **2,638 to 12,315**, adding **9,677 trips**. The small 2019 base made the **366.83%** increase especially large, and February still had the largest gain in absolute trips among the three months. I would examine which days and stations contributed most to that increase to identify where the marketing team could reach more casual riders.

**Member ride volume shifted from growth to decline in March.** Member trips rose **37.93%** in January and **35.45%** in February, then fell **22.78%** in March compared with the same month a year earlier. March had **34,095 fewer member trips** and **8,692 more casual trips**, leaving total rides down **15.34%**. Casual rides made up **17.56%** of March 2020 trips, the highest share among the six months studied. I would compare daily counts and station-level changes to see when the member decline began and whether it was concentrated at particular stations. Explaining the cause would require additional evidence.

### C. Stations and routes by quarter

#### Casual riders' busiest stations

**Streeter Dr & Grand Ave had the most casual departures in 2019 Q1, and Lake Shore Dr & Monroe St led in 2020 Q1.** Lake Shore Dr & Monroe St had the higher casual share of departures in both quarters.

| Departure station | 2019 Q1 casual departures | 2020 Q1 casual departures |
| --- | ---: | ---: |
| Streeter Dr & Grand Ave | **1,219 trips** (58.92%) | 1,530 trips (62.09%) |
| Lake Shore Dr & Monroe St | 1,142 trips (**74.06%**) | **1,590 trips** (**70.07%**) |

Each percentage is the share of all departures from that station made by casual riders in that quarter. **Streeter Dr & Grand Ave** also recorded the most casual returns in both quarters.

#### Members' busiest stations

In each quarter, the same station led in both member departures and member returns. The top station changed from **Clinton St & Washington Blvd** in 2019 Q1 to **Canal St & Adams St** in 2020 Q1.

| Quarter | Busiest member station | Member departures | Member returns |
| --- | --- | ---: | ---: |
| 2019 Q1 | Clinton St & Washington Blvd | 7,611 trips (98.86%) | 7,570 trips (98.32%) |
| 2020 Q1 | Canal St & Adams St | 7,586 trips (97.09%) | 8,158 trips (98.02%) |

Each percentage is the member share of all departures or all returns at that station in that quarter.

#### Most common start-to-end station pairs

Members accounted for most trips on the busiest station pair overall in both quarters. **The busiest casual pair started at Lake Shore Dr & Monroe St in both quarters.** It ended at Streeter Dr & Grand Ave in 2019 Q1 and back at Lake Shore Dr & Monroe St in 2020 Q1.

| Ranked by | 2019 Q1 most common station pair | 2020 Q1 most common station pair |
| --- | --- | --- |
| All trips | Michigan Ave & Washington St → Clinton St & Washington Blvd (513 trips, **99.61% member**) | Ellis Ave & 60th St → University Ave & 57th St (479 trips, **91.02% member**) |
| Member trips | Michigan Ave & Washington St → Clinton St & Washington Blvd (511 of 513 trips, **99.61% member**) | Canal St & Adams St → Michigan Ave & Washington St (451 of 455 trips, **99.12% member**) |
| Casual trips | Lake Shore Dr & Monroe St → Streeter Dr & Grand Ave (319 of 334 trips, **95.51% casual**) | Lake Shore Dr & Monroe St → Lake Shore Dr & Monroe St (413 of 468 trips, **88.25% casual**) |

Each percentage uses all trips on that station pair in the same quarter as its denominator.

The busiest Divvy station for both departures and returns was in Chicago’s West Loop in each quarter. In Q1 2019, Clinton St & Washington Blvd near Ogilvie Transportation Center ranked first. In Q1 2020, Canal St & Adams St near Chicago Union Station took the lead. Members accounted for more than 97% of both departures and returns at these stations. West Loop station locations

### D. Busiest stations and routes across both first quarters

I combined trips from 2019 Q1 and 2020 Q1 and ranked departures, returns, and station pairs by trip count within each rider type.

| Activity | Members | Casual riders |
| --- | --- | --- |
| Busiest departure station | Canal St & Adams St (13,799 of 14,155 departures, **97.48% member**) | Streeter Dr & Grand Ave (2,749 of 4,533 departures, **60.64% casual**) |
| Busiest return station | Canal St & Adams St (14,807 of 15,067 returns, **98.27% member**) | Streeter Dr & Grand Ave (3,790 of 5,416 returns, **69.98% casual**) |
| Most common station pair | Michigan Ave & Washington St → Clinton St & Washington Blvd (961 of 966 trips, **99.48% member**) | Lake Shore Dr & Monroe St → Lake Shore Dr & Monroe St (703 of 770 trips, **91.30% casual**) |

Each percentage uses all trips for that station activity or station pair across both quarters as its denominator. **Streeter Dr & Grand Ave** is a candidate for a membership promotion because it had the most casual departures and returns. **Lake Shore Dr & Monroe St** is another candidate because it was the start and return station for the most common casual station pair.

### E. Long casual rides on weekdays and weekends

I defined a long ride as a trip lasting at least 20 minutes. The percentage in the third column uses all casual trips in the same quarter and day type as its denominator.

| Period | Day type | Long trips / all casual trips | Busiest departure hour for long trips |
| --- | --- | ---: | --- |
| 2019 Q1 | Weekday | 7,404 / 13,404 (**55.24%**) | 3 p.m. (1,050 trips) |
| 2019 Q1 | Weekend | 6,106 / 9,759 (**62.57%**) | 2 p.m. (878 trips) |
| 2020 Q1 | Weekday | 11,028 / 22,349 (**49.34%**) | 5 p.m. (1,345 trips) |
| 2020 Q1 | Weekend | 14,318 / 22,366 (**64.02%**) | 2 p.m. (2,308 trips) |

**Long casual rides were common on both weekdays and weekends.** Around half of weekday casual trips reached 20 minutes in both quarters, and the weekday count rose from **7,404 to 11,028**. Weekends had a higher share in both quarters. In 2019 Q1, weekdays still recorded more long casual trips in total.

**Long casual rides were concentrated in the afternoon.** From noon through 5:59 p.m., **65.45%** of weekday long casual trips started in 2019 Q1 and **61.98%** in 2020 Q1. The busiest weekday departure hour shifted from 3 p.m. to 5 p.m., and 2 p.m. was the busiest weekend hour in both quarters.

I would prioritize casual riders taking longer trips when testing a membership offer based on accumulated ride time. The weekday afternoon volume gives the team a clear window to test that offer, and the recurring weekend peak provides a time to promote a weekend riding challenge. The percentages describe trips. Measuring membership conversion would require tracking the results of the offer.

## Key Findings for Q1 Membership Outreach

### 1. Long casual rides concentrated on weekday afternoons

| Period | Weekday members | Weekday casual riders | Weekend members | Weekend casual riders |
| --- | ---: | ---: | ---: | ---: |
| 2019 Q1 | 10.77% | 55.24% | 13.68% | 62.57% |
| 2020 Q1 | 11.82% | 49.34% | 17.88% | 64.02% |

Each percentage is the share of trips lasting at least 20 minutes among all trips for the same quarter, rider type, and day type. On weekdays, around half of casual trips reached that threshold, compared with about one in ten member trips in both quarters.

The share of weekday casual trips lasting at least 20 minutes fell from **55.24%** in 2019 Q1 to **49.34%** in 2020 Q1. The number of these trips still grew by about **49%**, from **7,404 to 11,028**, as total weekday casual trips increased. Between noon and 5:59 p.m., **65.45%** of longer weekday trips started in 2019 Q1 and **61.98%** in 2020 Q1. That recurring afternoon concentration gives the marketing team a window to test an offer based on accumulated ride time.

### 2. Long weekend rides peaked at 2 p.m.

In both first quarters, weekend casual trips were more likely than weekday casual trips to last at least 20 minutes. The weekend shares were **62.57%** in 2019 Q1 and **64.02%** in 2020 Q1. The busiest hour for those longer weekend rides was **2:00–2:59 p.m.** in both periods, with **878** and **2,308** departures, respectively. That recurring peak gives the marketing team a specific hour to test promoting a member-only weekend riding challenge.

### 3. Two stations led casual departures in both quarters

**Streeter Dr & Grand Ave** and **Lake Shore Dr & Monroe St** ranked first or second for casual departures in both quarters. Across both periods, Streeter Dr & Grand Ave recorded **2,749 casual departures** and **3,790 casual returns**, the highest counts for both activities. Lake Shore Dr & Monroe St recorded **2,732 casual departures**, and casual riders accounted for **74.06%** and **70.07%** of all departures there in the two quarters. It was also the departure station for the most common casual station pair in each quarter. Streeter Dr & Grand Ave offers a place to test a message after riders return their bikes, and Lake Shore Dr & Monroe St offers a place to test a message at pickup.

## Three Recommendations Based on Q1 Findings

### 1. Test a first-month membership credit after a long ride

About half of weekday casual trips lasted at least 20 minutes in both quarters, compared with about one in ten member trips. I would start on weekday afternoons and offer casual riders who have just completed a trip of at least 20 minutes a credit toward their first month of membership. The credit would cover part of that trip's fare. I would compare sign-up rates with a group of eligible riders who did not receive the offer.

### 2. Test a weekend membership invitation at 2 p.m.

In both first quarters, weekend casual trips lasting at least 20 minutes most often started between **2:00 and 2:59 p.m.** I would show the same membership invitation during that hour and during another weekend time slot, then compare sign-up rates to see whether the busiest riding hour is also a better time to reach casual riders.

### 3. Compare pickup and return prompts at two busy stations

**Streeter Dr & Grand Ave** and **Lake Shore Dr & Monroe St** were the two busiest casual departure stations in both first quarters. At each station, I would test showing a membership prompt before pickup and after return. Comparing sign-up rates for the two timings at each station would show which timing works better and whether the result differs by location.

I would measure conversion as the share of eligible casual riders who sign up in each test group, using campaign and membership records.

## How the Q1 Tests Fit the Full-Year Strategy

Both analyses found that casual riders averaged longer trips and took a larger share of their trips on weekends than members did. The Q1 analysis identified weekday afternoons, the 2 p.m. weekend hour, and two busy stations as starting points for testing how to reach casual riders. [2025 full-year analysis](../../README.md)

If the first-month credit increases sign-ups, I would pair it with the accumulated ride-time plan. If the 2 p.m. invitation performs better than the comparison time slot, I would use that hour to promote the weekend riding challenge. At Streeter Dr & Grand Ave and Lake Shore Dr & Monroe St, I would use the better-performing pickup or return prompt to promote a member benefit. An e-bike benefit would also depend on bike availability at the station.

I would use the measured sign-up rates to decide which Q1 tests to combine with the full-year membership strategy.
