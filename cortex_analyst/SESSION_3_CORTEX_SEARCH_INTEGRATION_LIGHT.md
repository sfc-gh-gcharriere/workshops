# Session 3: Cortex Search Integration - Quick Reference (OPTIONAL)

## Part 1: Understanding the Problem

### Test Questions

**Question 1: Works ✅**
> "Sales revenue for product line having clothes"

**Question 2: Fails ❌**
> "Sales revenue in book product lines"

**Why it fails:** Exact terminology not matched in sample values.

**View Sample Values:**
1. Navigate to **REVENUE_TIMESERIES** semantic view
2. Select **PRODUCT_DIM** table
3. Find **PRODUCT_LINE** dimension
4. Click **Edit Dimension**
5. Scroll to **Sample Values** section

---

## Part 2: Cortex Search Solution

### Step 1: Create Cortex Search Service

```sql
USE SCHEMA CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES;
USE WAREHOUSE cortex_analyst_wh;

-- Create search service on product lines
CREATE OR REPLACE CORTEX SEARCH SERVICE product_line_search_service
  ON product_dimension
  WAREHOUSE = cortex_analyst_wh
  TARGET_LAG = '1 hour'
  AS (
    SELECT DISTINCT product_line AS product_dimension 
    FROM product_dim
  );
```

**Verify:**
1. Navigate to **AI & ML** > **Cortex Search** in Snowsight
2. Verify `PRODUCT_LINE_SEARCH_SERVICE` is listed
3. Check status

---

### Step 2: Integrate Search Service with Semantic Model

1. Navigate to **REVENUE_TIMESERIES** semantic view
2. Click **Edit**
3. Select **PRODUCT_DIM** table
4. Find **PRODUCT_LINE** dimension
5. Click **Edit Dimension**
6. Scroll to **Cortex Search Service** section
7. Click **Add Cortex Search** → Select `product_line_search_service`
8. Click **Connect**
9. Click **Save**

**YAML representation:**
```yaml
cortex_search_service:
  database: CORTEX_ANALYST_DEMO
  schema: REVENUE_TIMESERIES
  service: PRODUCT_LINE_SEARCH_SERVICE
```

---

### Step 3: Test Fuzzy Matching

**Question 3: Now Works! ✅**
> "Sales revenue in book product lines"

**Question 4: Advanced Test ✅**
> "Overall sales revenue in book and elec cat"

**Expected behavior:**
- "book" matches "Books"
- "elec cat" matches "Electronics"
- Uses `IN ('Books', 'Electronics')` (not LIKE)

---

**Previous**: [Session 2: Building with Cortex Analyst](SESSION_2_CORTEX_ANALYST_LIGHT.md)  
**Next**: [Session 4: Snowflake Intelligence](SESSION_4_SNOWFLAKE_INTELLIGENCE_LIGHT.md)

