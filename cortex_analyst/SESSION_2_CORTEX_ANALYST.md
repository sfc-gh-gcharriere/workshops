# Session 2: Building with Cortex Analyst (75 minutes)

## Hands-On Semantic Model Development

This session focuses on the practical implementation of Snowflake Cortex Analyst, from environment setup to building sophisticated semantic models that enable natural language analytics.
<img width="1805" height="643" alt="model" src="https://github.com/user-attachments/assets/957048cc-04c0-407b-ae25-8e66bc10527d" />

---

## Part 1: Environment Setup (15 minutes)

### Overview
Set up the complete Snowflake environment required for Cortex Analyst, including database objects, data loading, and permissions.

---

### Step 1: Create Database, Schema, Warehouse and Stage

Create the foundational objects for your Cortex Analyst demo:

```sql
USE ROLE ACCOUNTADMIN;

-- Create demo database
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

-- Create stage for raw data
CREATE OR REPLACE STAGE cortex_analyst_demo.revenue_timeseries.raw_data 
    DIRECTORY = (ENABLE = TRUE);
```

**Key Considerations:**
- **Warehouse Size**: Start with SMALL for this demo, can scale up for production
- **Auto-suspend**: Set to 60 seconds to minimize costs during development
- **Directory-enabled Stage**: Allows listing files and managing data efficiently

---

### Step 2: Create Table Structures

Define the fact and dimension tables for your revenue analytics model:

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

**Data Model Design:**
- **Star Schema**: Fact table (DAILY_REVENUE) with dimension tables (PRODUCT_DIM, LOCATION_DIM)
- **Primary Keys**: 
  - LOCATION_DIM: location_id (unique identifier for each region-state combination)
  - PRODUCT_DIM: product_id
  - DAILY_REVENUE: No primary key defined (fact table)
- **Foreign Keys**: 
  - DAILY_REVENUE.product_id → PRODUCT_DIM.product_id
  - DAILY_REVENUE.location_id → LOCATION_DIM.location_id
- **Location Hierarchy**: Each location_id represents a unique combination of region and state

---

### Step 3: Download and Load CSV Files

**Download CSV Files:**
1. Download the following CSV files from the workshop data folder:
   - `daily_revenue.csv` (contains location_id references)
   - `product.csv`
   - `location.csv` (contains location_id, sales_region, and state)

**Load Files Using Snowsight UI:**

For each table, we'll load data directly through the UI:

#### Load Product Dimension Data
1. Navigate to **Database Explorer** > `CORTEX_ANALYST_DEMO` > `REVENUE_TIMESERIES` > `Tables`
2. Click on the `PRODUCT_DIM` table
3. Click **Load Data** button
4. Select `product.csv` file from your downloads
5. Click **Next**
6. Click **Load** to import the data

#### Load Location Dimension Data
1. Click on the `LOCATION_DIM` table
2. Click **Load Data** button
3. Select `location.csv` file
4. Click **Next**
5. **⚠️ Important**: The file format may not automatically detect the header. Modify the file format settings:
   - Check the box for **"First line contains header"**
   
   <img width="376" height="385" alt="first_line_header" src="https://github.com/user-attachments/assets/c46a03cd-242e-4e66-86ce-b3283a742a0a" />

6. Verify the column mapping is correct:
   - `location_id` → `LOCATION_ID`
   - `sales_region` → `SALES_REGION`
   - `state` → `STATE`
7. Click **Load** to import the data

#### Load Daily Revenue Fact Data
1. Click on the `DAILY_REVENUE` table
2. Click **Load Data** button
3. Select `daily_revenue.csv` file
4. Click **Next**
5. The file should automatically detect the header and map columns correctly:
   - `DATE` → `DATE`
   - `REVENUE` → `REVENUE`
   - `COGS` → `COGS`
   - `FORECASTED_REVENUE` → `FORECASTED_REVENUE`
   - `Product_id` → `PRODUCT_ID`
   - `location_id` → `LOCATION_ID`
6. Click **Load** to import the data

---

### Step 4: Verify Data Load

Validate that data has been loaded correctly:

```sql
USE SCHEMA CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES;

-- Check row counts for all tables
SELECT 'DAILY_REVENUE' as table_name, COUNT(*) as row_count FROM daily_revenue
UNION ALL
SELECT 'PRODUCT_DIM', COUNT(*) FROM product_dim
UNION ALL
SELECT 'LOCATION_DIM', COUNT(*) FROM location_dim;

-- Preview data from each table
SELECT * FROM product_dim LIMIT 10;
SELECT * FROM location_dim ORDER BY location_id LIMIT 10;
SELECT * FROM daily_revenue LIMIT 10;

-- Verify location data shows region and state combinations
SELECT 
    location_id,
    sales_region,
    state
FROM location_dim
ORDER BY sales_region, state;

-- Check for data quality issues
SELECT COUNT(*) as null_revenue 
FROM daily_revenue 
WHERE revenue IS NULL;
```

---

## Part 2: Semantic Model Development (60 minutes)

### What is a Semantic Model?

A **Semantic Model** (also called a **Semantic View** in Snowflake) is a business-friendly layer that defines:
- **Business-friendly names** for tables and columns
- **Relationships** between tables
- **Measures and dimensions** for analysis
- **Verified queries** to guide the AI
- **Custom instructions** for query generation

The semantic model acts as a bridge between natural language questions and SQL queries, enabling Cortex Analyst to understand your data and generate accurate SQL.

---

### Step 1: Create a New Semantic View

Navigate to Snowsight and create a new semantic view:

1. Go to **AI & ML** > **Cortex Analyst**
2. Click **Create New** > **Create New Semantic View**
3. Name it `REVENUE_TIMESERIES`
4. Select the schema: `CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES`
5. Select the tables to include: 
   - `DAILY_REVENUE`
   - `PRODUCT_DIM`
   - `LOCATION_DIM`
6. Select columns: Include **all columns** from each of the selected tables
7. Click **Create** and **Save**

<img width="1261" height="820" alt="semantic_view_creation" src="https://github.com/user-attachments/assets/ba831c10-5b1f-4b62-a492-c767e53ec025" />

---

### Step 2: Configure Column Types (Dimensions vs Facts)

**⚠️ Important**: By default, the Semantic View builder may incorrectly classify foreign key columns as "facts" instead of "dimensions". You need to fix this manually.

In the Semantic View builder, update the column types for each table:

#### Fix DAILY_REVENUE Table
1. Select the `DAILY_REVENUE` table in the left panel
2. For the `PRODUCT_ID` column:
   - Change type from **"Fact"** to **"Dimension"**
3. For the `LOCATION_ID` column:
   - Change type from **"Fact"** to **"Dimension"**

#### Fix LOCATION_DIM Table
1. Select the `LOCATION_DIM` table in the left panel
2. For the `LOCATION_ID` column:
   - Change type from **"Fact"** to **"Dimension"**

#### Fix PRODUCT_DIM Table
1. Select the `PRODUCT_DIM` table in the left panel
2. For the `PRODUCT_ID` column:
   - Change type from **"Fact"** to **"Dimension"**

**Why this matters:**
- **Dimensions** are categorical attributes used for grouping and filtering (IDs, names, categories)
- **Facts** are numeric values that can be aggregated (revenue, costs, quantities)
- Correctly classifying columns ensures Cortex Analyst generates accurate queries

---

### Step 3: Define Table Relationships

Relationships define how tables connect to each other, enabling Cortex Analyst to automatically generate JOIN clauses when answering questions that span multiple tables.

**Why Relationships Matter:**
- Enable cross-table queries (e.g., "Show revenue by product line")
- Automatically generate correct SQL JOINs
- Maintain referential integrity in queries
- Support complex multi-table analytics

In the Semantic View builder, navigate to the **Relationships** section and define the following two relationships:

#### Relationship 1: Revenue to Product

This relationship connects daily revenue records to product information, allowing questions like "What is the revenue for Electronics?" or "Show me sales by product line."

<img width="624" height="438" alt="revenue_to_product" src="https://github.com/user-attachments/assets/17a77ce4-6c6b-483a-af95-d5ee1259c5fd" />

```yaml
relationships:
  - name: revenue_to_product
    left_table: DAILY_REVENUE
    relationship_columns:
      - left_column: PRODUCT_ID
        right_column: PRODUCT_ID
    right_table: PRODUCT_DIM
```

---

#### Relationship 2: Revenue to Location

This relationship connects daily revenue records to location details (region and state), enabling geographic analysis like "Show revenue by region" or "What are sales in California?"

<img width="610" height="436" alt="revenue_to_location" src="https://github.com/user-attachments/assets/02dd5a30-10bb-4ecd-b79e-63f1d0d9e120" />

```yaml
  - name: revenue_to_location
    left_table: DAILY_REVENUE
    relationship_columns:
      - left_column: LOCATION_ID
        right_column: LOCATION_ID
    right_table: LOCATION_DIM
```

---

### Step 4: Test Your First Join Query

Now that the relationships are defined, let's test them with a natural language question that requires joining tables.

**Test Question:**
> "What is the total cost of goods sold for the Electronics product line?"

**Why This Tests Your Setup:**
- Uses the `revenue_to_product` relationship to join DAILY_REVENUE with PRODUCT_DIM
- Requires filtering by `PRODUCT_LINE` (from PRODUCT_DIM)
- Aggregates `COGS` (from DAILY_REVENUE)
- Validates that Cortex Analyst can automatically generate the JOIN

**How to Test:**
1. In the Semantic View builder, navigate to the **Playground** tab
2. Enter the question: "What is the total cost of goods sold for the Electronics product line?"
3. Click the **Run** button
4. Review the generated SQL query and check the results

**Expected SQL (generated automatically):**
```sql
WITH __daily_revenue AS (
  SELECT product_id, cogs
  FROM cortex_analyst_demo.revenue_timeseries.daily_revenue
),
__product_dim AS (
  SELECT product_id, product_line
  FROM cortex_analyst_demo.revenue_timeseries.product_dim
)
SELECT SUM(dr.cogs) AS total_cogs
FROM __daily_revenue AS dr
LEFT OUTER JOIN __product_dim AS pd 
  ON dr.product_id = pd.product_id
WHERE pd.product_line = 'Electronics'
```

**Expected Result:**
- Total COGS for Electronics: **212,458.25**
- This represents the sum of cost of goods sold across 148 revenue records for the Electronics product line

**What Success Looks Like:**
- ✅ Query executes without errors
- ✅ JOIN clause is automatically generated using PRODUCT_ID
- ✅ Correct table relationships are applied (`revenue_to_product`)
- ✅ Results show **212,458.25** (or similar numeric total)

---

### Step 5: Add Verified Queries

Verified queries help train Cortex Analyst on your specific query patterns and improve accuracy for similar questions.

**How to Add a Verified Query:**

1. In the Semantic View builder, navigate to the **Playground** tab
2. Enter the question: "daily cumulative expenses in december 2023"
3. Click the **Run** button to generate and execute the query
4. Review the generated SQL and results
5. Click the **+ Verified Query** button
6. **Test** the query to ensure it runs correctly
7. **Edit** the query if needed (optional)
8. Click **Save and Continue**

**Expected Generated SQL:**

```yaml
verified_queries:
  - name: daily cumulative expenses in december 2023
    question: daily cumulative expenses in december 2023
    sql: |
      WITH __daily_revenue AS (
        SELECT
          date,
          cogs
        FROM
          cortex_analyst_demo.revenue_timeseries.daily_revenue
      )
      SELECT
        date,
        SUM(cogs) OVER (
          ORDER BY date
        ) AS cumulative_cogs
      FROM
        __daily_revenue
      WHERE
        DATE_PART('YEAR', date) = 2023
        AND DATE_PART('MONTH', date) = 12
      ORDER BY
        date DESC NULLS LAST;
    verified_at: '1734766812'
    verified_by: ADMIN
```

**Verified Queries Purpose:**
- Handle complex queries (window functions, CTEs, etc.)
- Improve accuracy for similar questions
- Document expected behaviors

**Best Practices:**
- Add 5-10 verified queries covering different complexity levels
- Include temporal queries, aggregations, and filtering
- Update regularly based on user questions

---

### Step 6: Add a New Metric (Profit)

Metrics define how numeric values should be calculated and aggregated. Let's add a custom "profit" metric that reflects your organization's specific business logic.

**Why Add Custom Metrics:**
- Define business-specific calculations once
- Ensure consistent metric definitions across all queries
- Include complex formulas (e.g., profit with discount factor)

#### Step 6.1: Test Without the Metric

First, let's see how Cortex Analyst calculates profit without a custom definition.

1. In the **Playground** tab, ask: "Monthly profit in Europe per category"
2. Click **Run**
3. Review the generated SQL

**Without a custom metric, Cortex Analyst might calculate profit as:**
```sql
-- Simple profit calculation (revenue - cogs)
SELECT 
  DATE_TRUNC('MONTH', date) AS month,
  product_line,
  SUM(revenue - cogs) AS profit
FROM ...
```

This simple calculation doesn't account for your organization's 1% processing fee on all revenue.

#### Step 6.2: Add the Profit Metric

Now let's define profit with your organization's specific formula: **Revenue - (1% of Revenue) - COGS**

1. In the Semantic View builder, navigate to the **DAILY_REVENUE** table
2. Scroll to the **Metrics** section
3. Click **+ Add Metric**
4. Configure the metric:
   - **Expression**: `SUM(REVENUE - (0.01 * REVENUE) - COGS)`
   - **Metric Name**: `Profit`
   - **Metric Description**: `The profit generated from sales after deducting 1% processing fee and cost of goods sold`
   - **Synonyms** (optional): `earnings`, `margin`, `net income`
<img width="732" height="584" alt="profit_metric" src="https://github.com/user-attachments/assets/e6274738-17e2-4fb9-b24d-9bf10854ed5c" />

**YAML representation:**
```yaml
metrics:
      - name: Profit
        synonyms:
          - earnings
          - margin
          - net income
        description: The profit generated from sales after deducting 1% processing fee and cost of goods sold
        expr: SUM(REVENUE - (0.01 * REVENUE) - COGS)
```

5. Click **Save**

#### Step 6.3: Test With the Metric

1. Go back to the **Playground** tab
2. Ask the same question again: "Monthly profit in Europe per category"
3. Click **Run**
4. Review the updated SQL

**With the custom metric, Cortex Analyst will now use your formula:**
```sql
-- Profit with 1% processing fee
SELECT 
  DATE_TRUNC('MONTH', date) AS month,
  product_line,
  SUM(revenue - (0.01 * revenue) - cogs) AS profit
FROM ...
WHERE sales_region = 'Europe'
GROUP BY month, product_line
ORDER BY month, product_line
```

**Impact:**
- ✅ Consistent profit calculation across all queries
- ✅ Business logic is centralized in the semantic model
- ✅ Users can simply ask for "profit" without knowing the formula
- ✅ No need to remember the 1% processing fee in every query
- ✅ Custom metrics enable organization-specific business definitions

---

### Step 7: Add a Named Filter (Large Orders)

Named filters allow you to define reusable business logic that users can reference by name, making queries more intuitive and consistent.

**Why Add Named Filters:**
- Define business rules once (e.g., what qualifies as a "large order")
- Enable users to reference filters by name without knowing the underlying logic
- Ensure consistent criteria across all queries

#### Step 7.1: Test Without the Filter

First, let's see what happens when users ask about concepts that aren't defined in the semantic model.

1. In the **Playground** tab, ask: "list large orders"
2. Click **Run**

**Without a named filter, Cortex Analyst cannot understand the request:**
```
Sorry, I didn't understand what you mean by 'large orders'. 
Could you please specify what you mean?
```

Cortex Analyst doesn't know what threshold defines a "large" order in your business context.

#### Step 7.2: Add the Large Orders Filter

Now let's define what "large orders" means for your organization, for example: orders with revenue >= 1150.

1. In the Semantic View builder, navigate to the **DAILY_REVENUE** table
2. Scroll to the **Filters** section
3. Click **+ Add Filter**
4. Configure the filter:
   - **Expression**: `REVENUE >= 1150`
   - **Filter Name**: `large_order`
   - **Filter Description** (optional): `Orders with revenue equal to or greater than 1150`
   - **Synonyms** (optional): `large orders`, `big orders`, `high value orders`
<img width="754" height="637" alt="large_orders" src="https://github.com/user-attachments/assets/18c0d1e5-c366-4399-a975-6e6748f51e7b" />

5. Click **Add**

**YAML representation:**
```yaml
filters:
  - name: large_order
    synonyms:
      - large orders
      - big orders
      - high value orders
    description: Orders with revenue equal to or greater than 1150
    expr: REVENUE >= 1150
```

#### Step 7.3: Test With the Filter

1. Go back to the **Playground** tab
2. Ask the same question again: "list large orders"
3. Click **Run**
4. Review the generated SQL

**With the named filter, Cortex Analyst now understands the request:**
```sql
WITH __daily_revenue AS (
  SELECT
    date,
    revenue,
    cogs,
    product_id,
    location_id
  FROM
    cortex_analyst_demo.revenue_timeseries.daily_revenue
)
SELECT
  date,
  revenue,
  product_id,
  location_id
FROM
  __daily_revenue
WHERE
  revenue >= 1150
ORDER BY
  date DESC NULLS LAST;
```

**Impact:**
- ✅ Users can reference business concepts by name ("large orders")
- ✅ Consistent definition across all queries
- ✅ No need to remember specific thresholds
- ✅ Easier for non-technical users to ask business questions

**Other Use Cases for Named Filters:**

Named filters are not limited to numeric thresholds. You can also use them to define:

- **Regional groupings**: For example, create a filter named `DAPS` (Germany, Austria, Poland, Switzerland) with expression: `STATE IN ('Germany', 'Austria', 'Poland', 'Switzerland')`
  - Users can ask: "Show revenue in DAPS region"
  - Without the filter, they would need to remember and list all countries each time

- **Time periods**: Define fiscal quarters, seasons, or custom date ranges
- **Product categories**: Group multiple product lines under a business term
- **Customer segments**: Define VIP customers, high-risk accounts, etc.

This makes business terminology directly queryable without requiring users to know the underlying data structure or values.

---

### Step 8: Add Custom Instructions

Custom Instructions provide global guidance to Cortex Analyst on how to handle queries, apply formatting, and enforce business rules across all interactions.

**Why Add Custom Instructions:**
- Set default behaviors (e.g., date ranges, decimal precision)
- Enforce business rules consistently
- Improve output formatting automatically
- Reduce ambiguity in query interpretation

**How to Add Custom Instructions:**

1. In the Semantic View builder, scroll to the **Custom Instructions** section
2. In the **SQL generation** field, add all instructions at once:

```
Ensure that all numeric columns are rounded to 1 decimal point in the output.
For any percentage or rate calculation, multiply the result by 100.
If no date filter is provided, apply a filter for the last year.
```

**What Each Instruction Does:**

- **Instruction 1 (Numeric Formatting)**: Provides consistent, readable numeric output across all queries
- **Instruction 2 (Percentage Calculations)**: Displays percentages in familiar format (e.g., 25% instead of 0.25)
- **Instruction 3 (Default Date Filter)**: Prevents accidentally querying entire dataset; focuses on recent data by default

**YAML representation:**
```yaml
module_custom_instructions:
  sql_generation: |-
    Ensure that all numeric columns are rounded to 1 decimal point in the output.
    For any percentage or rate calculation, multiply the result by 100.
    If no date filter is provided, apply a filter for the last year.
```

**Impact:**
- ✅ Consistent formatting across all query results
- ✅ Business-friendly output (percentages, decimals)
- ✅ Automatic date filtering prevents accidental full-dataset queries
- ✅ Reduces need for users to specify formatting preferences

#### Step 8.1: Test Custom Instructions

Now let's verify that the custom instructions are working correctly.

1. Go to the **Playground** tab
2. Ask: "Percentage of Revenue per Region"
3. Click **Run**
4. Review the generated SQL and results

**What You Should Observe:**

1. **Rounded decimals**: Revenue percentages are rounded to 1 decimal point (e.g., 23.4% instead of 23.4567%)
2. **Percentage format**: Values are multiplied by 100 (e.g., 23.4 instead of 0.234)
3. **Automatic date filter**: Query only includes data from the last year, even though you didn't specify a date range

**Best Practices:**
- Keep instructions clear and specific
- Focus on formatting, defaults, and business rules
- Test instructions with various queries to ensure they work as intended
- Document any complex or non-obvious instructions for future reference

---

### Step 9: Save Your Semantic Model

Now that you've configured your semantic model with relationships, verified queries, metrics, filters, and custom instructions, it's time to save it.

1. In the Semantic View builder, click the **Save** button at the top right
2. Your semantic model is now ready to use!

**What Gets Saved:**
- ✅ All table definitions and relationships
- ✅ Verified queries
- ✅ Custom metrics (Profit)
- ✅ Named filters (large_order)
- ✅ Custom instructions (formatting, percentages, date filters)

Your semantic model is now available for natural language queries through Cortex Analyst and **Snowflake Intelligence**!

---

## Session Summary

In this session, you've learned:

✅ **Environment Setup**: Created database, schema, warehouse, stage, and tables  
✅ **Data Loading**: Uploaded CSV files and loaded data into Snowflake  
✅ **Semantic Model Basics**: Understanding structure and components  
✅ **Table Configuration**: Defined fact and dimension tables  
✅ **Dimensions & Measures**: Created business-friendly data definitions  
✅ **Relationships**: Established table joins  
✅ **Advanced Features**: Filters, verified queries, custom instructions  
✅ **Testing**: Validated model with natural language questions  

You now have a fully functional Cortex Analyst semantic model ready for production use!

---

**Previous**: [Session 1: Snowflake Platform Fundamentals](SESSION_1_SNOWFLAKE_FUNDAMENTALS.md)  
**Next**: [Session 4: Snowflake Intelligence](SESSION_4_SNOWFLAKE_INTELLIGENCE.md) | [Session 3: Cortex Search Integration (Optional)](SESSION_3_CORTEX_SEARCH_INTEGRATION.md)

