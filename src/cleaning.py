from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw" / "yellow_tripdata_2025-01.parquet"
OUT = ROOT / "data" / "processed"
OUT.mkdir(exist_ok=True)

df = pd.read_parquet(RAW)

# Quality flags
df["is_negative_transaction"] = df["fare_amount"] < 0
df["is_zero_distance"] = df["trip_distance"] == 0
df["is_zero_passenger"] = df["passenger_count"] == 0

df["trip_duration_minutes"] = (
    df["tpep_dropoff_datetime"] - df["tpep_pickup_datetime"]
).dt.total_seconds() / 60

df["is_invalid_duration"] = df["trip_duration_minutes"] <= 0

# Keep only trips belonging to January 2025.
# We retain negative transactions and zero-distance trips.
df = df[
    (df["tpep_pickup_datetime"] >= "2025-01-01") &
    (df["tpep_pickup_datetime"] < "2025-02-01")
].copy()

# Remove genuinely invalid temporal records
df = df[~df["is_invalid_duration"]].copy()

# Feature engineering
df["pickup_date"] = df["tpep_pickup_datetime"].dt.date
df["pickup_hour"] = df["tpep_pickup_datetime"].dt.hour
df["day_of_week"] = df["tpep_pickup_datetime"].dt.day_name()
df["is_weekend"] = df["tpep_pickup_datetime"].dt.dayofweek >= 5

df["time_period"] = pd.cut(
    df["pickup_hour"],
    bins=[-1, 5, 11, 16, 20, 23],
    labels=["Night", "Morning", "Afternoon", "Evening", "Late Night"]
)

df["revenue_per_mile"] = (
    df["total_amount"] / df["trip_distance"].where(df["trip_distance"] > 0)
)

df["tip_percentage"] = (
    df["tip_amount"] / df["fare_amount"].where(df["fare_amount"] > 0) * 100
)

df["average_speed_mph"] = (
    df["trip_distance"] / (df["trip_duration_minutes"] / 60)
).where(df["trip_duration_minutes"] > 0)

# Save
output = OUT / "yellow_tripdata_2025-01-cleaned.parquet"
df.to_parquet(output, index=False)

print(f"Original rows: {len(pd.read_parquet(RAW)):,}")
print(f"Cleaned rows:  {len(df):,}")
print(f"Removed rows:  {len(pd.read_parquet(RAW)) - len(df):,}")
print(f"Saved to: {output}")