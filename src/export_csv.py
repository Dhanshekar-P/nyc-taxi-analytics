from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]

df = pd.read_parquet(
    ROOT / "data/processed/yellow_tripdata_2025-01-cleaned.parquet"
)

df.to_csv(
    ROOT / "data/processed/trips.csv",
    index=False
)

zones = pd.read_csv(ROOT / "data/raw/taxi_zone_lookup.csv")
zones.to_csv(ROOT / "data/processed/zones.csv", index=False)

print(f"Exported {len(df):,} trips")