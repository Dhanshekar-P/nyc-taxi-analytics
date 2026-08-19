DROP TABLE IF EXISTS fact_trips CASCADE;
DROP TABLE IF EXISTS dim_payment CASCADE;
DROP TABLE IF EXISTS dim_location CASCADE;
DROP TABLE IF EXISTS dim_datetime CASCADE;

CREATE TABLE dim_location (
    location_id INTEGER PRIMARY KEY,
    borough VARCHAR(50),
    zone VARCHAR(100),
    service_zone VARCHAR(50)
);

CREATE TABLE dim_payment (
    payment_type_id INTEGER PRIMARY KEY,
    payment_type_name VARCHAR(50)
);

CREATE TABLE dim_datetime (
    date_id DATE PRIMARY KEY,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

CREATE TABLE fact_trips (
    trip_id BIGSERIAL PRIMARY KEY,
    vendor_id INTEGER,
    pickup_datetime TIMESTAMP NOT NULL,
    dropoff_datetime TIMESTAMP NOT NULL,
    pickup_date DATE NOT NULL,
    pickup_hour SMALLINT NOT NULL,
    pickup_location_id INTEGER NOT NULL,
    dropoff_location_id INTEGER NOT NULL,
    passenger_count NUMERIC,
    trip_distance NUMERIC,
    rate_code_id NUMERIC,
    payment_type_id INTEGER,
    fare_amount NUMERIC,
    extra NUMERIC,
    mta_tax NUMERIC,
    tip_amount NUMERIC,
    tolls_amount NUMERIC,
    improvement_surcharge NUMERIC,
    total_amount NUMERIC,
    congestion_surcharge NUMERIC,
    airport_fee NUMERIC,
    cbd_congestion_fee NUMERIC,
    trip_duration_minutes NUMERIC,
    day_of_week VARCHAR(15),
    is_weekend BOOLEAN,
    time_period VARCHAR(20),
    revenue_per_mile NUMERIC,
    tip_percentage NUMERIC,
    average_speed_mph NUMERIC,
    is_negative_transaction BOOLEAN,
    is_zero_distance BOOLEAN,
    is_zero_passenger BOOLEAN,

    CONSTRAINT fk_pickup_location
        FOREIGN KEY (pickup_location_id)
        REFERENCES dim_location(location_id),

    CONSTRAINT fk_dropoff_location
        FOREIGN KEY (dropoff_location_id)
        REFERENCES dim_location(location_id),

    CONSTRAINT fk_payment
        FOREIGN KEY (payment_type_id)
        REFERENCES dim_payment(payment_type_id)
);

CREATE INDEX idx_fact_pickup_datetime
    ON fact_trips(pickup_datetime);

CREATE INDEX idx_fact_pickup_date
    ON fact_trips(pickup_date);

CREATE INDEX idx_fact_pickup_location
    ON fact_trips(pickup_location_id);

CREATE INDEX idx_fact_dropoff_location
    ON fact_trips(dropoff_location_id);

CREATE INDEX idx_fact_payment_type
    ON fact_trips(payment_type_id);