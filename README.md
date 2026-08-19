# NYC Taxi Operations & Revenue Analytics

A data analytics project that analyzes real NYC Yellow Taxi trip data
(NYC TLC Trip Record Data, Jan–Dec 2025) to identify demand patterns,
revenue drivers, and operational inefficiencies.

This is a data analytics project, not a machine learning project. The focus
is on clean ingestion, a well-structured PostgreSQL warehouse, SQL-based
transformation/analysis, and a Power BI reporting layer on top.

Data source: [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
(official, publicly available — no synthetic or fabricated data is used).

## Tech Stack

- **Python** (pandas, with Polars as a fallback only if pandas becomes a bottleneck)
- **PostgreSQL** for the analytical warehouse
- **SQL** for staging, transformation, and analysis
- **Power BI** for reporting/dashboards
- **Docker** for a reproducible Postgres instance
- **Git/GitHub** for version control

## Project Structure

```
nyc-taxi-analytics/
├── data/
│   ├── raw/              # raw downloaded TLC files (git-ignored)
│   └── processed/        # cleaned/processed data (git-ignored)
├── src/
│   ├── ingestion/        # download / load raw trip data
│   ├── cleaning/         # validation & cleaning logic
│   └── database/         # PostgreSQL connection & load utilities
├── sql/
│   ├── staging/          # raw -> staging SQL
│   ├── transformations/  # staging -> modeled tables
│   └── analysis/         # analysis queries
├── notebooks/            # exploratory analysis
├── tests/                # unit tests
├── powerbi/               # Power BI report files
├── .env                  # local DB credentials (git-ignored)
├── docker-compose.yml    # PostgreSQL service definition
└── requirements.txt
```

## Status

Project scaffolding only. Data has not been downloaded yet, no database
tables have been created, and no ETL pipeline exists yet — these come next.

## Setup (so far)

1. Copy/adjust `.env` with your desired local DB credentials.
2. Start PostgreSQL:
   ```bash
   docker compose up -d
   ```
3. Create a Python virtual environment and install dependencies:
   ```bash
   python -m venv venv
   source venv/bin/activate   # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```
