# Session 1b: Advanced Fundamentals - Quick Reference (Optional)

## Part 1: Environment Setup

### Step 1: Create Database, Schema, and Warehouse

```sql
USE ROLE ACCOUNTADMIN;

-- Create database
CREATE DATABASE IF NOT EXISTS cortex_analyst_demo;

-- Create schema
CREATE SCHEMA IF NOT EXISTS cortex_analyst_demo.revenue_timeseries;

-- Create warehouse
CREATE OR REPLACE WAREHOUSE cortex_analyst_wh
    WAREHOUSE_SIZE = 'small'
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'Warehouse for Cortex Analyst demo';

-- Enable cross-region inference
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
```

---

### Step 2: Create Table Structures

```sql
-- Dimension table: product_dim
CREATE OR REPLACE TABLE cortex_analyst_demo.revenue_timeseries.product_dim (
    product_id INT PRIMARY KEY,
    product_line VARCHAR
);

-- Dimension table: location_dim
CREATE OR REPLACE TABLE cortex_analyst_demo.revenue_timeseries.location_dim (
    location_id INT PRIMARY KEY,
    sales_region VARCHAR,
    state VARCHAR
);

-- Fact table: daily_revenue
CREATE OR REPLACE TABLE cortex_analyst_demo.revenue_timeseries.daily_revenue (
    date DATE,
    revenue FLOAT,
    cogs FLOAT,
    forecasted_revenue FLOAT,
    product_id INT,
    location_id INT,
    FOREIGN KEY (product_id) REFERENCES cortex_analyst_demo.revenue_timeseries.product_dim(product_id),
    FOREIGN KEY (location_id) REFERENCES cortex_analyst_demo.revenue_timeseries.location_dim(location_id)
);
```

---

### Step 3: Load CSV Files via Snowsight UI

**Download CSV files from workshop data folder:**
- [`daily_revenue.csv`](data/daily_revenue.csv)
- [`product.csv`](data/product.csv)
- [`location.csv`](data/location.csv)

**Load Product Dimension:**
1. Navigate to **Database Explorer** > `CORTEX_ANALYST_DEMO` > `REVENUE_TIMESERIES` > `Tables`
2. Click on `PRODUCT_DIM` table
3. Click **Load Data** → Select `product.csv`
4. Click **Next** → Click **Load**

**Load Location Dimension:**
1. Click on `LOCATION_DIM` table
2. Click **Load Data** → Select `location.csv`
3. Click **Next**
4. **⚠️ Important**: Check **"First line contains header"**

   <img alt="first_line_header" src="img/cortex_analyst/first_line_header.png" />

5. Click **Load**

**Load Daily Revenue Fact:**
1. Click on `DAILY_REVENUE` table
2. Click **Load Data** → Select `daily_revenue.csv`
3. Click **Next** → Click **Load**

---

### Step 4: Verify Data Load

```sql
USE SCHEMA CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES;

-- Check row counts
SELECT 'DAILY_REVENUE' as table_name, COUNT(*) as row_count FROM daily_revenue
UNION ALL
SELECT 'PRODUCT_DIM', COUNT(*) FROM product_dim
UNION ALL
SELECT 'LOCATION_DIM', COUNT(*) FROM location_dim;
```

---

## Part 2: Create Streamlit Dashboard with Cortex Code

### Step 1: Create Streamlit App

1. Navigate to **Projects** > **Streamlit** in Snowsight
2. Click **+ Streamlit App**
3. Configure:
   - **App title**: `Dashboard`
   - **App location**: `CORTEX_ANALYST_DEMO`
   - **Schema**: `REVENUE_TIMESERIES`
   - **Python environment**: `Run on warehouse`
   - **App warehouse**: `COMPUTE_WH`
4. Click **Create**

---

### Step 2: Use Cortex Code to Generate Dashboard

1. Click on the **Cortex Code** icon (✨) in the **bottom right corner**
2. **Enter this prompt:**

```
Create a beautiful and dynamic Streamlit dashboard to display sales data from the revenue_timeseries schema.
```

3. Click **Generate**
4. **Review** and click **Accept**
5. Click **Run**

---

### Step 3: Explore Your Dashboard

Your dashboard should display:
- ✅ Interactive filters (date, region, product)
- ✅ KPI cards (revenue, profit, averages)
- ✅ Trend charts
- ✅ Comparison charts
- ✅ Data table

---

### Step 4: Customize (Optional)

Try additional Cortex Code prompts:
- `Add a line chart showing profit margin percentage over time`
- `Add a chart showing revenue by state within each region`
- `Make the dashboard more visually appealing with custom colors`

---

## Part 3: Dynamic Tables

### Step 1: Create Dynamic Table

```sql
USE SCHEMA CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES;
USE WAREHOUSE CORTEX_ANALYST_WH;

-- Create dynamic table for automatic aggregation
CREATE OR REPLACE DYNAMIC TABLE revenue_summary
    TARGET_LAG = '1 minute'
    WAREHOUSE = CORTEX_ANALYST_WH
AS
SELECT 
    DATE_TRUNC('MONTH', dr.date) AS month,
    p.product_line,
    l.sales_region,
    l.state,
    COUNT(*) AS transaction_count,
    SUM(dr.revenue) AS total_revenue,
    SUM(dr.cogs) AS total_cogs,
    SUM(dr.revenue - dr.cogs) AS total_profit,
    ROUND(SUM(dr.revenue - dr.cogs) / NULLIF(SUM(dr.revenue), 0) * 100, 2) AS profit_margin_pct
FROM daily_revenue dr
JOIN product_dim p ON dr.product_id = p.product_id
JOIN location_dim l ON dr.location_id = l.location_id
GROUP BY DATE_TRUNC('MONTH', dr.date), p.product_line, l.sales_region, l.state;

-- Verify
SELECT * FROM revenue_summary ORDER BY month DESC, total_revenue DESC LIMIT 20;
```

---

### Step 2: Test with New Data

**Check current state:**
```sql
SELECT SUM(total_revenue) as current_total, SUM(transaction_count) as current_transactions
FROM revenue_summary WHERE month = '2024-01-01';
```

**Insert new data:**
```sql
INSERT INTO daily_revenue (date, revenue, cogs, forecasted_revenue, product_id, location_id)
VALUES 
    ('2024-01-15', 5000.00, 2500.00, 4800.00, 1, 1),
    ('2024-01-16', 7500.00, 3750.00, 7000.00, 2, 2),
    ('2024-01-17', 3200.00, 1600.00, 3000.00, 3, 3);
```

**Observe automatic update (wait ~1 minute):**
```sql
SELECT SUM(total_revenue) as updated_total, SUM(transaction_count) as updated_transactions
FROM revenue_summary WHERE month = '2024-01-01';
```

**Clean up (optional):**
```sql
DELETE FROM daily_revenue 
WHERE date IN ('2024-01-15', '2024-01-16', '2024-01-17')
AND revenue IN (5000.00, 7500.00, 3200.00);
```

---

**Previous**: [Session 1: Snowflake Platform Fundamentals](SESSION_1_SNOWFLAKE_FUNDAMENTALS_LIGHT.md)  
**Next**: [Session 2: Building with Cortex Analyst](SESSION_2_CORTEX_ANALYST_LIGHT.md)

> **💡 Note**: If you completed this session, skip Part 1 of Session 2!
