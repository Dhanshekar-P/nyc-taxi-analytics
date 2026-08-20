# NYC Taxi Operations & Revenue Analytics

An end-to-end data analytics project analyzing **3.47M real NYC Yellow Taxi trips from January 2025** to understand demand patterns, revenue concentration, payment behavior, airport economics, and operational efficiency.

The project follows a production-style workflow:

**Raw Data → Python Data Quality → Feature Engineering → PostgreSQL → SQL Analysis → Power BI**

---

## Business Problem

Taxi operators need to understand more than just how many trips occurred.

The key questions addressed in this project are:

- When is taxi demand highest?
- Which pickup locations generate the most trips and revenue?
- Is high demand concentrated in the same locations as high revenue?
- How significant are airport trips to overall revenue?
- How does customer payment behavior differ across payment methods?
- Which hours provide the strongest operational economics?
- Which pickup → drop-off corridors have the highest demand?
- What data-quality issues could distort operational reporting?

The objective is to turn millions of individual trip records into **actionable operational and revenue insights**.

---

## Dataset

**Source:** NYC Taxi & Limousine Commission (TLC)  
**Dataset:** Yellow Taxi Trip Records — January 2025

### Scale

| Metric                 |        Value |
| ---------------------- | -----------: |
| Raw records            |    3,475,226 |
| Records after cleaning |    3,473,153 |
| Taxi zones             |          265 |
| Analysis period        | January 2025 |
| Database               |   PostgreSQL |

The project uses the original publicly available dataset rather than simulated or generated business data.

---

## Key Findings

### Demand

- Demand increases substantially throughout the day, reaching its strongest levels during the evening commute period.
- Thursday recorded the highest daily trip volume.
- The 17:00–18:00 period represents one of the strongest demand windows.

### Revenue

- Non-negative transactions generated approximately **$90.29M** in total revenue.
- Average revenue per valid trip was approximately **$27.12**.
- Revenue is highly concentrated geographically, with major Manhattan and airport locations dominating the highest-revenue pickup zones.

### Airport Economics

Airport trips represent a relatively small share of total trip volume but have substantially higher economics per trip.

- Airport trips: approximately **$78.52 average revenue**
- Non-airport trips: approximately **$23.52 average revenue**

This makes airport demand an important component of overall revenue despite its lower trip volume.

### Payment Behavior

- Credit card transactions account for approximately **73% of trips**.
- Credit card transactions also dominate total revenue.
- Tip behavior varies significantly by payment method.

### Geographic Concentration

High-volume pickup locations are concentrated around major Manhattan commercial, residential, transportation, and airport areas.

This creates an opportunity to analyze **demand concentration separately from revenue concentration**, rather than assuming that the busiest locations are automatically the most profitable.

---

## Data Quality

Real-world datasets rarely arrive analysis-ready.

The raw dataset contained:

- 144K+ negative-fare transactions
- 90K+ zero-distance trips
- Missing passenger-count and rate-code values
- Zero-duration trips
- Negative-duration records
- Extreme fare and distance values

Instead of blindly deleting unusual observations, the project distinguishes between:

**Data-quality problems**  
and  
**legitimate operational edge cases.**

Negative transactions and zero-distance trips are retained as analytical flags and excluded selectively from business KPIs where appropriate.

This preserves traceability while preventing anomalous records from distorting operational metrics.

---

## Data Pipeline

### 1. Profiling

Python/Pandas is used to inspect:

- Schema and data types
- Missing values
- Duplicate records
- Date ranges
- Payment distribution
- Distance and fare distributions
- Invalid durations
- Location coverage

### 2. Cleaning & Feature Engineering

The pipeline creates analytical fields including:

- Trip duration
- Pickup hour
- Day of week
- Weekend indicator
- Time period
- Revenue per mile
- Tip percentage
- Average speed
- Negative transaction flag
- Zero-distance flag
- Zero-passenger flag

### 3. PostgreSQL

The cleaned dataset is loaded into PostgreSQL running inside Docker.

The database uses a dimensional structure consisting of:

- `fact_trips`
- `dim_location`
- `dim_datetime`
- `dim_payment`

Indexes are added to support analytical queries.

### 4. SQL Analytics

SQL is used to answer business questions involving:

- Demand by hour and day
- Revenue performance
- Geographic concentration
- Payment behavior
- Airport economics
- Revenue efficiency
- Pickup/drop-off corridors
- Revenue concentration

Analytical views are created specifically for the Power BI layer.

### 5. Power BI

The final dashboard contains three analytical sections:

#### Executive Overview

- Total trips
- Total revenue
- Average trip economics
- Demand by hour
- Revenue by hour
- Payment mix

#### Geography & Operations

- Top pickup zones by trip volume
- Top pickup zones by revenue
- Airport vs non-airport performance
- High-volume pickup/drop-off corridors

#### Payment & Efficiency

- Revenue by payment method
- Trips by payment method
- Average tip percentage
- Average trip duration by hour

---

## Technology

**Data Analysis**

- Python
- Pandas
- PyArrow

**Database**

- PostgreSQL 16
- SQL

**Infrastructure**

- Docker
- Docker Compose

**Visualization**

- Microsoft Power BI

**Version Control**

- Git
- GitHub

---

## Project Structure

```text
nyc-taxi-analytics/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── src/
│   ├── profiling.py
│   ├── cleaning.py
│   ├── database.py
│   ├── export_csv.py
│   ├── ingestion/
│   └── ...
│
├── sql/
│   ├── schema.sql
│   ├── analysis.sql
│   └── dashboard_views.sql
│
├── tests/
│
├── docker-compose.yml
├── requirements.txt
├── README.md
└── nyc-taxi-analytics.pbix
```
## Running the Project

### 1. Clone the repository

git clone git@github.com:Dhanshekar-P/nyc-taxi-analytics.git
cd nyc-taxi-analytics

### 2. Create the Python environment

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

### 3. Start PostgreSQL

docker compose up -d

### 4. Run the pipeline

python src/profiling.py
python src/cleaning.py

docker exec -i nyc-taxi-postgres \
psql -U analyst -d nyc_taxi < sql/schema.sql

python src/database.py

docker exec -i nyc-taxi-postgres \
psql -U analyst -d nyc_taxi < sql/analysis.sql

docker exec -i nyc-taxi-postgres \
psql -U analyst -d nyc_taxi < sql/dashboard_views.sql

### 5. Power BI

Open `nyc-taxi-analytics.pbix` in Power BI Desktop and connect to the local PostgreSQL database.