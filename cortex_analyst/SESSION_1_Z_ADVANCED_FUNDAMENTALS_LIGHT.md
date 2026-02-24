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
4. **Copy** the generated code
5. **Replace** all current Streamlit code with the generated code
6. Click **Run**

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

### Step 1: Use Cortex Code to Generate the Pipeline

1. Navigate to **Projects** > **Worksheets** in Snowsight
2. Click **+** to add a new SQL file
3. Click on the **Cortex Code** icon (✨) in the **bottom right corner**
4. **Enter this prompt:**

```
Create an automated incremental pipeline for transformation using dynamic tables in the CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES schema. 
Create two dynamic tables with incremental refresh:
1. First one will denormalize the data from DAILY_REVENUE, PRODUCT_DIM, and LOCATION_DIM tables
2. Second one will aggregate the revenue by month from the first dynamic table
Use COMPUTE_WH warehouse, 1 minute target lag, and INCREMENTAL refresh mode.
```

5. Click **Generate**
6. **Copy** the generated code and paste it into your SQL worksheet
7. **Run** the SQL

**Expected Output:**

```sql
-- Dynamic Table 1: Denormalized revenue data
CREATE OR REPLACE DYNAMIC TABLE CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.DAILY_REVENUE_DENORMALIZED
  TARGET_LAG = '1 minute'
  WAREHOUSE = COMPUTE_WH
  REFRESH_MODE = INCREMENTAL
  AS
    SELECT 
      dr.DATE, dr.REVENUE, dr.COGS, dr.FORECASTED_REVENUE,
      p.PRODUCT_ID, p.PRODUCT_LINE,
      l.LOCATION_ID, l.SALES_REGION, l.STATE
    FROM CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.DAILY_REVENUE dr
    INNER JOIN CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.PRODUCT_DIM p ON dr.PRODUCT_ID = p.PRODUCT_ID
    INNER JOIN CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.LOCATION_DIM l ON dr.LOCATION_ID = l.LOCATION_ID;

-- Dynamic Table 2: Monthly revenue aggregation
CREATE OR REPLACE DYNAMIC TABLE CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.MONTHLY_REVENUE_AGGREGATED
  TARGET_LAG = '1 minute'
  WAREHOUSE = COMPUTE_WH
  REFRESH_MODE = INCREMENTAL
  AS
    SELECT 
      DATE_TRUNC('MONTH', DATE) AS MONTH,
      PRODUCT_LINE, SALES_REGION, STATE,
      SUM(REVENUE) AS TOTAL_REVENUE,
      SUM(COGS) AS TOTAL_COGS,
      SUM(FORECASTED_REVENUE) AS TOTAL_FORECASTED_REVENUE,
      COUNT(*) AS TRANSACTION_COUNT
    FROM CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.DAILY_REVENUE_DENORMALIZED
    GROUP BY DATE_TRUNC('MONTH', DATE), PRODUCT_LINE, SALES_REGION, STATE;
```

---

### Step 2: Check the Lineage

1. Navigate to **Data** > **Databases** > `CORTEX_ANALYST_DEMO` > `REVENUE_TIMESERIES`
2. Click on `MONTHLY_REVENUE_AGGREGATED` dynamic table
3. Select the **Lineage** tab

You'll see: `DAILY_REVENUE`, `PRODUCT_DIM`, `LOCATION_DIM` → `DAILY_REVENUE_DENORMALIZED` → `MONTHLY_REVENUE_AGGREGATED`

<img alt="Dynamic Tables Pipeline Lineage" src="img/snowflake_fundamentals/pipeline.png" />

---

### Step 3: Test the Pipeline

**Insert new data:**
```sql
INSERT INTO CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.DAILY_REVENUE 
    (date, revenue, cogs, forecasted_revenue, product_id, location_id)
VALUES 
    ('2024-01-15', 5000.00, 2500.00, 4800.00, 1, 1),
    ('2024-01-16', 7500.00, 3750.00, 7000.00, 2, 2),
    ('2024-01-17', 3200.00, 1600.00, 3000.00, 3, 3);
```

**Manually refresh (or wait for automatic refresh):**
```sql
ALTER DYNAMIC TABLE CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.DAILY_REVENUE_DENORMALIZED REFRESH;
ALTER DYNAMIC TABLE CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.MONTHLY_REVENUE_AGGREGATED REFRESH;
```

**Verify updates:**
```sql
SELECT * FROM CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.MONTHLY_REVENUE_AGGREGATED
WHERE MONTH = '2024-01-01';
```

**Clean up (optional):**
```sql
DELETE FROM CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.DAILY_REVENUE 
WHERE date IN ('2024-01-15', '2024-01-16', '2024-01-17')
AND revenue IN (5000.00, 7500.00, 3200.00);
```

---

**Previous**: [Session 1: Snowflake Platform Fundamentals](SESSION_1_SNOWFLAKE_FUNDAMENTALS_LIGHT.md)  
**Next**: [Session 2: Building with Cortex Analyst](SESSION_2_CORTEX_ANALYST_LIGHT.md)

> **💡 Note**: If you completed this session, skip Part 1 of Session 2!
