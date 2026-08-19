from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "raw"

trip_file = DATA / "yellow_tripdata_2025-01.parquet"
zone_file = DATA / "taxi_zone_lookup.csv"

print("Loading taxi data...")
df = pd.read_parquet(trip_file)

print("\n--- SHAPE ---")
print(df.shape)

print("\n--- COLUMNS ---")
print(df.columns.tolist())

print("\n--- DATA TYPES ---")
print(df.dtypes)

print("\n--- MISSING VALUES ---")
print(df.isna().sum())

print("\n--- DUPLICATES ---")
print(df.duplicated().sum())

print("\n--- NUMERICAL SUMMARY ---")
print(df.describe().T)

print("\n--- ZONE LOOKUP ---")
zones = pd.read_csv(zone_file)
print(zones.shape)
print(zones.head())

print("\n--- DATE RANGE ---")
print("Pickup:", df["tpep_pickup_datetime"].min(), "→", df["tpep_pickup_datetime"].max())
print("Dropoff:", df["tpep_dropoff_datetime"].min(), "→", df["tpep_dropoff_datetime"].max())

print("\n--- PAYMENT TYPES ---")
print(df["payment_type"].value_counts(dropna=False))

print("\n--- DATA QUALITY ---")
print("Negative fares:", (df["fare_amount"] < 0).sum())
print("Zero distance:", (df["trip_distance"] == 0).sum())
print("Negative distance:", (df["trip_distance"] < 0).sum())
print("Zero passengers:", (df["passenger_count"] == 0).sum())

duration = (
    df["tpep_dropoff_datetime"] -
    df["tpep_pickup_datetime"]
).dt.total_seconds() / 60

print("Negative duration:", (duration < 0).sum())
print("Zero duration:", (duration == 0).sum())

print("\n--- LOCATION IDs ---")
print("Pickup IDs:", df["PULocationID"].nunique())
print("Dropoff IDs:", df["DOLocationID"].nunique())

print("\nProfiling complete.")