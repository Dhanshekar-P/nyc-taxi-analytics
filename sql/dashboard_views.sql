DROP VIEW IF EXISTS dashboard_kpis;
DROP VIEW IF EXISTS dashboard_hourly;
DROP VIEW IF EXISTS dashboard_zones;
DROP VIEW IF EXISTS dashboard_payment;
DROP VIEW IF EXISTS dashboard_airport;
DROP VIEW IF EXISTS dashboard_corridors;

CREATE VIEW dashboard_kpis AS
SELECT
    COUNT(*) AS total_trips,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_trip_revenue,
    AVG(trip_distance) AS avg_distance,
    AVG(trip_duration_minutes) AS avg_duration,
    AVG(revenue_per_mile) AS avg_revenue_per_mile,
    AVG(tip_percentage) AS avg_tip_percentage
FROM fact_trips
WHERE is_negative_transaction = FALSE;


CREATE VIEW dashboard_hourly AS
SELECT
    pickup_hour,
    COUNT(*) AS trips,
    SUM(total_amount) AS revenue,
    AVG(total_amount) AS avg_revenue,
    AVG(trip_duration_minutes) AS avg_duration,
    AVG(revenue_per_mile) AS revenue_per_mile
FROM fact_trips
WHERE is_negative_transaction = FALSE
GROUP BY pickup_hour
ORDER BY pickup_hour;


CREATE VIEW dashboard_zones AS
SELECT
    l.borough,
    l.zone,
    COUNT(*) AS trips,
    SUM(f.total_amount) AS revenue,
    AVG(f.total_amount) AS avg_revenue
FROM fact_trips f
JOIN dim_location l
    ON f.pickup_location_id = l.location_id
WHERE f.is_negative_transaction = FALSE
GROUP BY l.borough, l.zone;


CREATE VIEW dashboard_payment AS
SELECT
    p.payment_type_name,
    COUNT(*) AS trips,
    SUM(f.total_amount) AS revenue,
    AVG(f.tip_percentage) AS avg_tip_percentage
FROM fact_trips f
JOIN dim_payment p
    ON f.payment_type_id = p.payment_type_id
WHERE f.is_negative_transaction = FALSE
GROUP BY p.payment_type_name;


CREATE VIEW dashboard_airport AS
SELECT
    CASE
        WHEN airport_fee > 0 THEN 'Airport'
        ELSE 'Non-Airport'
    END AS trip_type,
    COUNT(*) AS trips,
    SUM(total_amount) AS revenue,
    AVG(total_amount) AS avg_revenue,
    AVG(trip_distance) AS avg_distance,
    AVG(trip_duration_minutes) AS avg_duration
FROM fact_trips
WHERE is_negative_transaction = FALSE
GROUP BY 1;


CREATE VIEW dashboard_corridors AS
SELECT
    pu.zone AS pickup_zone,
    doo.zone AS dropoff_zone,
    COUNT(*) AS trips,
    SUM(f.total_amount) AS revenue,
    AVG(f.total_amount) AS avg_revenue,
    AVG(f.trip_duration_minutes) AS avg_duration
FROM fact_trips f
JOIN dim_location pu
    ON f.pickup_location_id = pu.location_id
JOIN dim_location doo
    ON f.dropoff_location_id = doo.location_id
WHERE f.is_negative_transaction = FALSE
GROUP BY pu.zone, doo.zone
HAVING COUNT(*) >= 100;