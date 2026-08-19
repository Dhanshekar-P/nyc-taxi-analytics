-- 1. Overall business KPIs
SELECT
    COUNT(*) AS total_trips,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_revenue_per_trip,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(revenue_per_mile), 2) AS avg_revenue_per_mile,
    ROUND(AVG(tip_percentage), 2) AS avg_tip_percentage
FROM fact_trips
WHERE is_negative_transaction = FALSE;


-- 2. Demand by hour
SELECT
    pickup_hour,
    COUNT(*) AS trips,
    ROUND(SUM(total_amount), 2) AS revenue,
    ROUND(AVG(total_amount), 2) AS avg_revenue
FROM fact_trips
WHERE is_negative_transaction = FALSE
GROUP BY pickup_hour
ORDER BY pickup_hour;


-- 3. Demand by day of week
SELECT
    day_of_week,
    COUNT(*) AS trips,
    ROUND(SUM(total_amount), 2) AS revenue,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration
FROM fact_trips
WHERE is_negative_transaction = FALSE
GROUP BY day_of_week
ORDER BY
    CASE day_of_week
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;


-- 4. Peak vs off-peak
SELECT
    time_period,
    COUNT(*) AS trips,
    ROUND(SUM(total_amount), 2) AS revenue,
    ROUND(AVG(total_amount), 2) AS avg_trip_revenue,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration,
    ROUND(AVG(revenue_per_mile), 2) AS avg_revenue_per_mile
FROM fact_trips
WHERE is_negative_transaction = FALSE
GROUP BY time_period
ORDER BY trips DESC;


-- 5. Top pickup zones
SELECT
    l.borough,
    l.zone,
    COUNT(*) AS trips,
    ROUND(SUM(f.total_amount), 2) AS revenue,
    ROUND(AVG(f.total_amount), 2) AS avg_revenue
FROM fact_trips f
JOIN dim_location l
    ON f.pickup_location_id = l.location_id
WHERE f.is_negative_transaction = FALSE
GROUP BY l.borough, l.zone
ORDER BY trips DESC
LIMIT 20;


-- 6. Highest revenue pickup zones
SELECT
    l.borough,
    l.zone,
    COUNT(*) AS trips,
    ROUND(SUM(f.total_amount), 2) AS revenue,
    ROUND(SUM(f.total_amount) / COUNT(*), 2) AS revenue_per_trip
FROM fact_trips f
JOIN dim_location l
    ON f.pickup_location_id = l.location_id
WHERE f.is_negative_transaction = FALSE
GROUP BY l.borough, l.zone
HAVING COUNT(*) >= 100
ORDER BY revenue DESC
LIMIT 20;


-- 7. High-demand but low-revenue zones
WITH zone_metrics AS (
    SELECT
        l.zone,
        l.borough,
        COUNT(*) AS trips,
        SUM(f.total_amount) AS revenue,
        AVG(f.total_amount) AS avg_revenue
    FROM fact_trips f
    JOIN dim_location l
        ON f.pickup_location_id = l.location_id
    WHERE f.is_negative_transaction = FALSE
    GROUP BY l.zone, l.borough
),
ranked AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY trips) AS demand_quartile,
        NTILE(4) OVER (ORDER BY avg_revenue) AS revenue_quartile
    FROM zone_metrics
)
SELECT *
FROM ranked
WHERE demand_quartile = 4
  AND revenue_quartile = 1
ORDER BY trips DESC;


-- 8. Payment behavior
SELECT
    p.payment_type_name,
    COUNT(*) AS trips,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS trip_share_pct,
    ROUND(SUM(f.total_amount), 2) AS revenue,
    ROUND(AVG(f.tip_amount), 2) AS avg_tip
FROM fact_trips f
JOIN dim_payment p
    ON f.payment_type_id = p.payment_type_id
WHERE f.is_negative_transaction = FALSE
GROUP BY p.payment_type_name
ORDER BY trips DESC;


-- 9. Tip behavior by payment method
SELECT
    p.payment_type_name,
    COUNT(*) AS trips,
    ROUND(AVG(f.tip_percentage), 2) AS avg_tip_pct,
    ROUND(
        SUM(f.tip_amount) /
        NULLIF(SUM(f.fare_amount), 0) * 100,
        2
    ) AS weighted_tip_pct
FROM fact_trips f
JOIN dim_payment p
    ON f.payment_type_id = p.payment_type_id
WHERE f.is_negative_transaction = FALSE
GROUP BY p.payment_type_name
ORDER BY weighted_tip_pct DESC;


-- 10. Airport vs non-airport trips
SELECT
    CASE
        WHEN airport_fee > 0 THEN 'Airport'
        ELSE 'Non-Airport'
    END AS trip_type,
    COUNT(*) AS trips,
    ROUND(SUM(total_amount), 2) AS revenue,
    ROUND(AVG(total_amount), 2) AS avg_revenue,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration
FROM fact_trips
WHERE is_negative_transaction = FALSE
GROUP BY 1;


-- 11. Distance efficiency
-- 11. Distance efficiency
WITH distance_metrics AS (
    SELECT
        CASE
            WHEN trip_distance = 0 THEN 'Zero'
            WHEN trip_distance < 2 THEN '<2 miles'
            WHEN trip_distance < 5 THEN '2-5 miles'
            WHEN trip_distance < 10 THEN '5-10 miles'
            WHEN trip_distance < 20 THEN '10-20 miles'
            ELSE '20+ miles'
        END AS distance_band,
        total_amount,
        revenue_per_mile
    FROM fact_trips
    WHERE is_negative_transaction = FALSE
)
SELECT
    distance_band,
    COUNT(*) AS trips,
    ROUND(AVG(total_amount), 2) AS avg_revenue,
    ROUND(AVG(revenue_per_mile), 2) AS avg_revenue_per_mile
FROM distance_metrics
GROUP BY distance_band
ORDER BY
    CASE distance_band
        WHEN 'Zero' THEN 1
        WHEN '<2 miles' THEN 2
        WHEN '2-5 miles' THEN 3
        WHEN '5-10 miles' THEN 4
        WHEN '10-20 miles' THEN 5
        WHEN '20+ miles' THEN 6
    END;

-- 12. Hourly efficiency
SELECT
    pickup_hour,
    COUNT(*) AS trips,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    ROUND(AVG(revenue_per_mile), 2) AS avg_revenue_per_mile,
    ROUND(AVG(average_speed_mph), 2) AS avg_speed_mph
FROM fact_trips
WHERE is_negative_transaction = FALSE
  AND is_zero_distance = FALSE
GROUP BY pickup_hour
ORDER BY pickup_hour;


-- 13. Pickup → dropoff corridors
SELECT
    pu.zone AS pickup_zone,
    doo.zone AS dropoff_zone,
    COUNT(*) AS trips,
    ROUND(SUM(f.total_amount), 2) AS revenue,
    ROUND(AVG(f.total_amount), 2) AS avg_revenue,
    ROUND(AVG(f.trip_duration_minutes), 2) AS avg_duration
FROM fact_trips f
JOIN dim_location pu
    ON f.pickup_location_id = pu.location_id
JOIN dim_location doo
    ON f.dropoff_location_id = doo.location_id
WHERE f.is_negative_transaction = FALSE
GROUP BY pu.zone, doo.zone
HAVING COUNT(*) >= 100
ORDER BY trips DESC
LIMIT 25;


-- 14. Weekend vs weekday
SELECT
    CASE
        WHEN is_weekend THEN 'Weekend'
        ELSE 'Weekday'
    END AS period,
    COUNT(*) AS trips,
    ROUND(SUM(total_amount), 2) AS revenue,
    ROUND(AVG(total_amount), 2) AS avg_revenue,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration
FROM fact_trips
WHERE is_negative_transaction = FALSE
GROUP BY 1;


-- 15. Passenger count
SELECT
    passenger_count,
    COUNT(*) AS trips,
    ROUND(AVG(total_amount), 2) AS avg_revenue,
    ROUND(AVG(trip_distance), 2) AS avg_distance
FROM fact_trips
WHERE is_negative_transaction = FALSE
  AND passenger_count > 0
GROUP BY passenger_count
ORDER BY passenger_count;


-- 16. Negative transactions / adjustments
SELECT
    COUNT(*) AS negative_transactions,
    ROUND(SUM(total_amount), 2) AS negative_value,
    ROUND(AVG(total_amount), 2) AS avg_negative_value
FROM fact_trips
WHERE is_negative_transaction = TRUE;


-- 17. Zero-distance trips
SELECT
    COUNT(*) AS zero_distance_trips,
    ROUND(SUM(total_amount), 2) AS associated_revenue,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration
FROM fact_trips
WHERE is_zero_distance = TRUE
  AND is_negative_transaction = FALSE;


-- 18. Monthly data validation
SELECT
    MIN(pickup_datetime) AS first_trip,
    MAX(pickup_datetime) AS last_trip,
    COUNT(*) AS total_rows
FROM fact_trips;


-- 19. Revenue concentration
WITH zone_revenue AS (
    SELECT
        l.zone,
        SUM(f.total_amount) AS revenue
    FROM fact_trips f
    JOIN dim_location l
        ON f.pickup_location_id = l.location_id
    WHERE f.is_negative_transaction = FALSE
    GROUP BY l.zone
)
SELECT
    zone,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        revenue * 100.0 /
        SUM(revenue) OVER (),
        2
    ) AS revenue_share_pct,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0 /
        SUM(revenue) OVER (),
        2
    ) AS cumulative_revenue_share_pct
FROM zone_revenue
ORDER BY revenue DESC
LIMIT 30;