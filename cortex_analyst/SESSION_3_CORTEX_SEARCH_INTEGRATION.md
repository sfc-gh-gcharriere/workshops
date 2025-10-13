# Session 3: Cortex Search Integration with Cortex Analyst (15 minutes) - OPTIONAL

## Enhancing Analytics with Semantic Search

> **Note:** This is an optional session for participants interested in advanced integration patterns. You can proceed directly to [Session 4: Snowflake Intelligence](SESSION_4_SNOWFLAKE_INTELLIGENCE.md) if you prefer.

This session demonstrates how to integrate Snowflake Cortex Search with Cortex Analyst, enabling fuzzy matching that allows users to make mistakes with terminology and still get proper results.

---

## What is Cortex Search?

**Cortex Search** is Snowflake's fully managed search service that provides:
- **Semantic Search**: Find content by meaning, not just keywords
- **Vector Embeddings**: Automatically generated using Snowflake's AI models
- **Fuzzy Matching**: Match variations, typos, and abbreviations to actual values

---

## Part 1: Understanding the Problem (5 minutes)

### Step 1: Test a Question That Works

Let's start by asking a question about product lines using natural language:

**Question 1: Works ✅**
> "Sales revenue for product line having clothes"

In the Cortex Analyst Playground, enter this question and run it.

**Why This Works:**
- Your semantic model has sample values that include "Clothing"
- The AI can match "clothes" to "Clothing" from the discovered samples
- Query generates: `WHERE product_line = 'Clothing'`

---

### Step 2: Test a Question That Fails

Now let's try a similar question with different terminology:

**Question 2: Fails ❌**
> "Sales revenue in book product lines"

In the Cortex Analyst Playground, enter this question and run it.

**Why This Fails:**
- The semantic model samples don't include "Books" as a value
- The AI cannot match "book" to any known product line
- Result: Error or "No data found" message

**The Problem:**
Users need to know the exact terminology in your data. If they say "book" instead of "Books", or "elec" instead of "Electronics", queries may fail. This creates a poor user experience.

---

## Part 2: Cortex Search Solution (10 minutes)

### Step 3: Create Cortex Search Service for Product Lines

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

```sql
-- Check search service status
SHOW CORTEX SEARCH SERVICES;

-- Test the search service directly
SELECT * FROM TABLE(
  product_line_search_service!SEARCH(
    'book',
    LIMIT => 5
  )
);
```

**Expected Results:**
- `product_dimension`: "Books"
- `search_score`: Relevance score (e.g., 0.95)

The search service found "Books" even though we searched for "book"!

---

### Step 4: Integrate Search Service with Semantic Model

Now we need to tell Cortex Analyst to use this search service when users ask about product lines.

#### Option A: Update Semantic Model YAML (Manual)

If you're editing the YAML file directly, add this to your semantic model:

```yaml
# Add to your semantic model configuration
tables:
  - name: PRODUCT_DIM
    base_table:
      database: CORTEX_ANALYST_DEMO
      schema: REVENUE_TIMESERIES
      table: PRODUCT_DIM
    dimensions:
      - name: PRODUCT_LINE
        synonyms:
          - product category
          - product type
          - product line
        description: The product category (e.g., Books, Electronics, Clothing)
        expr: PRODUCT_LINE
        data_type: TEXT
        cortex_search_service: product_line_search_service  # Enable search!
```

#### Option B: Update via Snowsight UI (Recommended)

1. Navigate to your **REVENUE_TIMESERIES** semantic view in Snowsight
2. Click **Edit**
3. Select the **PRODUCT_DIM** table
4. Find the **PRODUCT_LINE** dimension
5. Enable **Cortex Search** and select `product_line_search_service`
6. Click **Save**

---

### Step 5: Test With Fuzzy Matching

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

## The Value of Cortex Search

### Without Cortex Search ❌
- Users must know exact values: "Books", "Electronics", "Clothing"
- Queries fail with variations: "book", "elec", "clothes"
- Poor user experience, frustrated users
- Requires data catalog knowledge

### With Cortex Search ✅
- Users can use natural language: "book", "electronics", "clothes"
- Handles typos and abbreviations: "elec", "cloths", "electornic"
- Semantic understanding: "apparel" → "Clothing"
- Forgiving and intuitive
- **Allows users to make mistakes and still get proper results!**

---

## Additional Use Cases

### Use Case 1: Location/Region Search

Create a search service for regions and states:

```sql
-- Create search service for regions
CREATE OR REPLACE CORTEX SEARCH SERVICE region_search_service
  ON region_dimension
  WAREHOUSE = cortex_analyst_wh
  TARGET_LAG = '1 hour'
  AS (
    SELECT DISTINCT sales_region AS region_dimension 
    FROM location_dim
  );

-- Create search service for states
CREATE OR REPLACE CORTEX SEARCH SERVICE state_search_service
  ON state_dimension
  WAREHOUSE = cortex_analyst_wh
  TARGET_LAG = '1 hour'
  AS (
    SELECT DISTINCT state AS state_dimension 
    FROM location_dim
  );
```

**Benefits:**
- "Show revenue in the midwest" → Matches to actual region names
- "Sales in NY" → Matches "New York"
- "California or Texas" → Matches both states correctly

---

### Use Case 2: Customer Segment/Industry Search

If you have customer segments or industry classifications:

```sql
-- Example: Search service for customer segments
CREATE OR REPLACE CORTEX SEARCH SERVICE segment_search_service
  ON segment_dimension
  WAREHOUSE = cortex_analyst_wh
  TARGET_LAG = '1 hour'
  AS (
    SELECT DISTINCT customer_segment AS segment_dimension 
    FROM your_customer_table
  );
```

**Enables Questions Like:**
- "Revenue from enterprise clients" → Matches "Enterprise"
- "Sales to schools" → Matches "Education"
- "B2B revenue" → Matches "Business" or "Corporate"

---

## Best Practices

### 1. When to Use Cortex Search
✅ **Use for:**
- Categorical dimensions with many distinct values
- Fields where users might use variations/synonyms
- Industry-specific terminology
- Geographic locations
- Product catalogs

❌ **Don't use for:**
- Numeric values (use regular filters)
- Date ranges (use time dimensions)
- Boolean fields (true/false)
- Small, well-known value sets (e.g., Yes/No)

### 2. Search Service Configuration
- **TARGET_LAG**: 
  - Use `'1 minute'` for rapidly changing data
  - Use `'1 hour'` or `'1 day'` for stable dimensions
  - Shorter lag = more compute cost
  
- **Warehouse Sizing**:
  - Start with SMALL for < 1M rows
  - Scale up for larger datasets or faster refresh needs

### 3. Semantic Model Integration
- Enable Cortex Search on key dimensions users will query
- Don't over-index - focus on high-value fields
- Test with common variations and typos
- Monitor query performance

---

## Common Questions

**Q: Does Cortex Search slow down queries?**  
A: No! Search happens during query generation, not execution. The actual SQL uses exact matches (IN clause), so query performance is identical.

**Q: How much does Cortex Search cost?**  
A: Minimal cost - just the warehouse time to build/refresh the index. Query-time search is very fast and efficient.

**Q: Can I use multiple search services in one query?**  
A: Yes! Enable search on multiple dimensions (product lines, regions, states, etc.) and Cortex Analyst will use them appropriately.

**Q: What if the search can't find a match?**  
A: Cortex Analyst will either ask for clarification or return no results, just like without search. The difference is search has a much higher success rate.

**Q: Can I customize the matching algorithm?**  
A: The vector embeddings are automatic, but you can control results by adding synonyms to your semantic model dimensions.

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

## Hands-On Exercise

Try creating your own search scenarios:

1. **Test Different Variations:**
   - "ebook revenue" (should match "Books")
   - "gadgets sales" (should match "Electronics")
   - "fashion products" (should match "Clothing")

2. **Test Misspellings:**
   - "electronic devices" → "Electronics"
   - "cloths" → "Clothing"
   - "boks" → "Books"

3. **Test Abbreviations:**
   - "elec" → "Electronics"  
   - "cloth" → "Clothing"

4. **Create Your Own Search Service:**
   - Pick another dimension from your data
   - Create a search service for it
   - Test with various natural language queries

---

## Additional Resources

- [Cortex Search Documentation](https://docs.snowflake.com/en/user-guide/cortex-search)
- [Vector Embeddings Guide](https://docs.snowflake.com/en/user-guide/cortex-embeddings)
- [Semantic Model Search Integration](https://docs.snowflake.com/en/user-guide/cortex-analyst-semantic-models#search)
- [Search Service Best Practices](https://docs.snowflake.com/en/user-guide/cortex-search-best-practices)

---

**Previous**: [Session 2: Building with Cortex Analyst](SESSION_2_CORTEX_ANALYST.md)  
**Next**: [Session 4: Advanced Analytics with Snowflake Intelligence](SESSION_4_SNOWFLAKE_INTELLIGENCE.md)
