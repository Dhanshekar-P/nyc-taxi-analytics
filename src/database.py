from pathlib import Path

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values


ROOT = Path(__file__).resolve().parents[1]

DB_CONFIG = {
    "host": "localhost",
    "port": 5433,
    "dbname": "nyc_taxi",
    "user": "analyst",
    "password": "analyst_password",
}

CLEANED_FILE = ROOT / "data/processed/yellow_tripdata_2025-01-cleaned.parquet"
ZONE_FILE = ROOT / "data/raw/taxi_zone_lookup.csv"


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def load_dimensions(conn, df):
    zones = pd.read_csv(ZONE_FILE)

    zones = zones.rename(
        columns={
            "LocationID": "location_id",
            "Borough": "borough",
            "Zone": "zone",
        }
    )

    location_rows = list(
        zones[
            ["location_id", "borough", "zone", "service_zone"]
        ].itertuples(index=False, name=None)
    )

    payment_rows = [
        (0, "Unknown"),
        (1, "Credit Card"),
        (2, "Cash"),
        (3, "No Charge"),
        (4, "Dispute"),
        (5, "Voided Trip"),
        (6, "Unknown/Other"),
    ]

    dates = pd.to_datetime(df["pickup_date"]).drop_duplicates()

    date_rows = [
        (
            date.date(),
            date.year,
            date.month,
            date.month_name(),
            date.day,
            date.dayofweek,
            date.day_name(),
            date.dayofweek >= 5,
        )
        for date in dates
    ]

    with conn.cursor() as cur:

        execute_values(
            cur,
            """
            INSERT INTO dim_location
                (location_id, borough, zone, service_zone)
            VALUES %s
            ON CONFLICT (location_id) DO NOTHING
            """,
            location_rows,
        )

        execute_values(
            cur,
            """
            INSERT INTO dim_payment
                (payment_type_id, payment_type_name)
            VALUES %s
            ON CONFLICT (payment_type_id) DO NOTHING
            """,
            payment_rows,
        )

        execute_values(
            cur,
            """
            INSERT INTO dim_datetime
                (
                    date_id,
                    year,
                    month,
                    month_name,
                    day,
                    day_of_week,
                    day_name,
                    is_weekend
                )
            VALUES %s
            ON CONFLICT (date_id) DO NOTHING
            """,
            date_rows,
        )


def load_trips(conn, df):

    # Rename the ACTUAL columns produced by cleaning.py
    df = df.rename(
        columns={
            "VendorID": "vendor_id",
            "PULocationID": "pickup_location_id",
            "DOLocationID": "dropoff_location_id",
            "RatecodeID": "rate_code_id",
            "payment_type": "payment_type_id",
            "Airport_fee": "airport_fee",
        }
    )

    columns = [
        "vendor_id",
        "tpep_pickup_datetime",
        "tpep_dropoff_datetime",
        "pickup_date",
        "pickup_hour",
        "pickup_location_id",
        "dropoff_location_id",
        "passenger_count",
        "trip_distance",
        "rate_code_id",
        "payment_type_id",
        "fare_amount",
        "extra",
        "mta_tax",
        "tip_amount",
        "tolls_amount",
        "improvement_surcharge",
        "total_amount",
        "congestion_surcharge",
        "airport_fee",
        "cbd_congestion_fee",
        "trip_duration_minutes",
        "day_of_week",
        "is_weekend",
        "time_period",
        "revenue_per_mile",
        "tip_percentage",
        "average_speed_mph",
        "is_negative_transaction",
        "is_zero_distance",
        "is_zero_passenger",
    ]

    missing = [column for column in columns if column not in df.columns]

    if missing:
        raise ValueError(
            f"Cleaned dataset is missing columns: {missing}"
        )

    df = df[columns].copy()

    # Convert pandas NaN/NaT to PostgreSQL NULL
    df = df.astype(object).where(pd.notna(df), None)

    insert_sql = """
        INSERT INTO fact_trips (
            vendor_id,
            pickup_datetime,
            dropoff_datetime,
            pickup_date,
            pickup_hour,
            pickup_location_id,
            dropoff_location_id,
            passenger_count,
            trip_distance,
            rate_code_id,
            payment_type_id,
            fare_amount,
            extra,
            mta_tax,
            tip_amount,
            tolls_amount,
            improvement_surcharge,
            total_amount,
            congestion_surcharge,
            airport_fee,
            cbd_congestion_fee,
            trip_duration_minutes,
            day_of_week,
            is_weekend,
            time_period,
            revenue_per_mile,
            tip_percentage,
            average_speed_mph,
            is_negative_transaction,
            is_zero_distance,
            is_zero_passenger
        )
        VALUES %s
    """

    batch_size = 10_000
    total = len(df)

    print(f"Loading {total:,} trips...")

    with conn.cursor() as cur:

        for start in range(0, total, batch_size):

            batch = df.iloc[start:start + batch_size]

            rows = list(
                batch.itertuples(index=False, name=None)
            )

            execute_values(
                cur,
                insert_sql,
                rows,
                page_size=batch_size,
            )

            loaded = min(start + batch_size, total)

            print(f"Loaded {loaded:,}/{total:,}")


def main():

    print("Reading cleaned data...")

    df = pd.read_parquet(CLEANED_FILE)

    print(f"Cleaned dataset: {len(df):,} rows")

    conn = get_connection()

    try:

        # Make the script safely re-runnable.
        with conn.cursor() as cur:
            cur.execute("TRUNCATE TABLE fact_trips RESTART IDENTITY CASCADE")

        load_dimensions(conn, df)

        load_trips(conn, df)

        conn.commit()

        with conn.cursor() as cur:

            cur.execute("SELECT COUNT(*) FROM fact_trips")
            trip_count = cur.fetchone()[0]

            cur.execute("SELECT COUNT(*) FROM dim_location")
            location_count = cur.fetchone()[0]

            cur.execute("SELECT COUNT(*) FROM dim_payment")
            payment_count = cur.fetchone()[0]

            cur.execute("SELECT COUNT(*) FROM dim_datetime")
            date_count = cur.fetchone()[0]

        print()
        print("DATABASE LOAD COMPLETE")
        print(f"Trips:      {trip_count:,}")
        print(f"Locations:  {location_count:,}")
        print(f"Payments:   {payment_count:,}")
        print(f"Dates:      {date_count:,}")

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    main()