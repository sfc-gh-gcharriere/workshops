# Session 3: Cortex Search Integration with Cortex Analyst (15 minutes) - OPTIONAL

## Enhancing Analytics with Semantic Search

> **Note:** This is an optional session for participants interested in advanced integration patterns. You can proceed directly to [Session 4: Snowflake Intelligence](SESSION_4_SNOWFLAKE_INTELLIGENCE.md) if you prefer.
---

## What is Cortex Search?

**Cortex Search** is a standalone, fully managed search service in Snowflake that can be integrated with Cortex Analyst to handle **high cardinality columns** such as product lines, customer names, or geographic locations.

**Key Capabilities:**
- **Semantic Search**: Find content by meaning, not just exact keywords
- **Vector Embeddings**: Automatically generated using Snowflake's AI models
- **Fuzzy Matching**: Match variations, typos, and abbreviations to actual values

**Why Integrate with Cortex Analyst?**
When users ask questions, they often use informal language or partial terms (e.g., "book" instead of "Books", "elec" instead of "Electronics"). Cortex Search enables fuzzy matching that allows users to make mistakes with terminology and still get proper results.
<img width="1804" height="662" alt="cortex_search" src="https://github.com/user-attachments/assets/02ef91b8-a6c7-4c16-9e81-e97921a55f3d" />

---

## Part 1: Understanding the Problem (5 minutes)

### Step 1: Test a Question That Works

Let's start by asking a question about product lines using natural language:

**Question 1: Works ✅**
> "Sales revenue for product line having clothes"

In the Cortex Analyst Playground, enter this question and run it.

**Why This Works:**
- Your semantic model has sample values that include "Clothing"
- Cortex Analyst can match "clothes" to "Clothing" from the discovered samples
- Query generates: `WHERE product_line = 'Clothing'`

**💡 Where to Find Sample Values:**
To see what sample values Cortex Analyst has discovered:
1. Navigate to your **REVENUE_TIMESERIES** semantic view
2. Select the **PRODUCT_DIM** table
3. Find the **PRODUCT_LINE** dimension
4. Click **Edit Dimension**
5. Scroll to the **Sample Values** section

You'll see values like "Clothing", "Electronics", "Books" that Cortex Analyst uses for matching.

<img width="441" height="151" alt="sample_values" src="https://github.com/user-attachments/assets/84da910c-b394-4ca6-be7e-ce464ddaeca1" />

---

### Step 2: Test a Question That Fails

Now let's try a similar question with different terminology:

**Question 2: Fails ❌**
> "Sales revenue in book product lines"

In the Cortex Analyst Playground, enter this question and run it.

**Why This Fails:**
- The semantic model samples don't include "Books" as a value
- Cortex Analyst cannot match "book" to any known product line
- Result: Error or "No data found" message

**The Problem:**
Users need to know the exact terminology in your data. If they say "book" instead of "Books", or "elec" instead of "Electronics", queries may fail. This creates a poor user experience.

---

## Part 2: Cortex Search Solution (10 minutes)

### Step 1: Create Cortex Search Service for Product Lines

Now let's create a Cortex Search service to enable fuzzy/semantic matching on product lines:

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

**What This Does:**
- **Indexes all unique product lines** from your `PRODUCT_DIM` table
- **Creates vector embeddings** that understand semantic similarity
- **Enables fuzzy matching** so "book" matches "Books", "elec" matches "Electronics"
- **Updates automatically** within 1 hour when new product lines are added

**Search Service Parameters:**
- **ON product_dimension**: The column to vectorize and search
- **WAREHOUSE**: Compute resources for indexing and search
- **TARGET_LAG**: Maximum time before new data appears in search (1 hour)
- **AS (SELECT ...)**: The data source query

**Verify the Search Service:**

To verify your search service was created successfully:
1. Navigate to **AI & ML** > **Cortex Search** in Snowsight
2. You should see `PRODUCT_LINE_SEARCH_SERVICE` listed
3. Click on the service to view its details and status

<img width="1258" height="204" alt="cortex_search_ui" src="https://github.com/user-attachments/assets/0b742c73-00a3-403d-98db-943f082153be" />

---

### Step 2: Integrate Search Service with Semantic Model

Now we need to tell Cortex Analyst to use this search service when users ask about product lines.

**Integrate via Snowsight UI:**

1. Navigate to your **REVENUE_TIMESERIES** semantic view in Snowsight
2. Click **Edit**
3. Select the **PRODUCT_DIM** table in the left panel
4. Find the **PRODUCT_LINE** dimension
5. Click **Edit Dimension**
6. Scroll to the **Cortex Search Service** section
7. Click **Add Cortex Search** and select `product_line_search_service` from the dropdown

   <img width="690" height="272" alt="add_cortex_search" src="https://github.com/user-attachments/assets/457f4b95-0f20-400e-a911-d5b3eb59f480" />

8. Click **Connect** to link the search service to this dimension

   <img width="583" height="512" alt="connect_search" src="https://github.com/user-attachments/assets/4c04d4c6-2833-4abe-b5cd-7bc796440892" />

9. Click **Save** to save your semantic model changes

**How it looks in the Semantic Model:**

Behind the scenes, this integration adds the `cortex_search_service` configuration to your PRODUCT_LINE dimension:

```yaml
- name: PRODUCT_LINE
  description: The category or classification of the product, such as electronics, clothing, or home appliances, that helps to group similar products together for analysis and reporting purposes.
  expr: PRODUCT_LINE
  data_type: VARCHAR(16777216)
  sample_values:
    - Electronics
    - Clothing
    - Home Appliances
  cortex_search_service:
    database: CORTEX_ANALYST_DEMO
    schema: REVENUE_TIMESERIES
    service: PRODUCT_LINE_SEARCH_SERVICE
```

Note that Cortex Search is now linked to this dimension, enabling fuzzy matching on product line queries!

---

### Step 3: Test With Fuzzy Matching

Now let's test the same question that failed before, plus a more complex one:

**Question 3: Now Works! ✅**
> "Sales revenue in book product lines"

**Expected Behavior:**
- Cortex Search matches "book" → "Books" using vector similarity
- Query generates: `WHERE product_line = 'Books'`
- Returns revenue data successfully!

**Question 4: Advanced Test ✅**
> "Overall sales revenue in book and elec cat"

**Expected SQL Generated:**
```sql
SELECT 
    SUM(revenue) AS total_revenue
FROM cortex_analyst_demo.revenue_timeseries.daily_revenue dr
JOIN cortex_analyst_demo.revenue_timeseries.product_dim pd 
    ON dr.product_id = pd.product_id
WHERE pd.product_line IN ('Books', 'Electronics')
```

**Key Observations:**
- ✅ "book" was matched to "Books"
- ✅ "elec cat" was matched to "Electronics"
- ✅ Uses `IN ('Books', 'Electronics')` - **NOT** `LIKE '%book%'`
- ✅ Vector search finds the actual product line names!
- ✅ No need for wildcards or partial matching

---

## Session Summary

In this optional session, you've learned:

✅ **The Problem**: Users must know exact terminology, leading to failed queries  
✅ **The Solution**: Cortex Search enables fuzzy/semantic matching  
✅ **Implementation**: Create search services on key dimensions  
✅ **Integration**: Link search services to semantic model dimensions  
✅ **The Value**: Users can make mistakes and still get proper results  
✅ **Best Practices**: When and how to use Cortex Search effectively  

**Key Takeaway:** Cortex Search transforms your semantic model from requiring precise terminology to understanding natural, flexible language - dramatically improving user experience!

---

**Previous**: [Session 2: Building with Cortex Analyst](SESSION_2_CORTEX_ANALYST.md)  
**Next**: [Session 4: Advanced Analytics with Snowflake Intelligence](SESSION_4_SNOWFLAKE_INTELLIGENCE.md)
