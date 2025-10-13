# Session 3: Cortex Search Integration with Cortex Analyst (45 minutes)

## Enhancing Analytics with Semantic Search

This session demonstrates how to integrate Snowflake Cortex Search with Cortex Analyst, enabling hybrid analytics that combines structured data queries with unstructured text search capabilities.

---

## What is Cortex Search?

**Cortex Search** is Snowflake's fully managed search service that provides:
- **Semantic Search**: Find content by meaning, not just keywords
- **Vector Embeddings**: Automatically generated using Snowflake's AI models
- **Hybrid Search**: Combine keyword and semantic search
- **Native Integration**: Works directly with Snowflake tables

### Use Cases
- Product catalog search with analytics
- Customer feedback analysis with revenue correlation
- Document search combined with business metrics
- Support ticket analysis with operational data

---

## Part 1: Cortex Search Setup (20 minutes)

### Step 1: Create Sample Unstructured Data

Let's add product descriptions and customer reviews to complement our revenue data:

```sql
USE SCHEMA CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES;
USE WAREHOUSE cortex_analyst_wh;

-- Create product descriptions table
CREATE OR REPLACE TABLE product_descriptions (
    product_id INT,
    product_name STRING,
    description STRING,
    features STRING,
    target_audience STRING,
    FOREIGN KEY (product_id) REFERENCES product_dim(product_id)
);

-- Insert sample product descriptions
INSERT INTO product_descriptions VALUES
(1, 'Smartphone Pro', 'High-end smartphone with advanced camera system and 5G connectivity', 'AI-powered camera, 6.7" OLED display, 5G enabled, wireless charging', 'Tech enthusiasts and professionals'),
(2, 'Laptop Elite', 'Professional-grade laptop with powerful performance and long battery life', '16GB RAM, 512GB SSD, 15" 4K display, 12-hour battery', 'Business professionals and content creators'),
(3, 'Wireless Earbuds', 'Premium noise-canceling wireless earbuds with exceptional sound quality', 'Active noise cancellation, 8-hour battery, IPX4 water resistant', 'Music lovers and commuters'),
(4, 'Smart Watch', 'Fitness-focused smartwatch with health monitoring capabilities', 'Heart rate monitor, GPS tracking, sleep analysis, 7-day battery', 'Fitness enthusiasts and health-conscious users'),
(5, 'Tablet Ultra', 'Versatile tablet for work and entertainment', '12.9" display, Apple M2 chip, 5G support, stylus compatible', 'Creative professionals and students');

-- Create customer feedback table
CREATE OR REPLACE TABLE customer_feedback (
    feedback_id INT PRIMARY KEY,
    product_id INT,
    date DATE,
    customer_segment STRING,
    feedback_text STRING,
    sentiment STRING,
    rating INT,
    FOREIGN KEY (product_id) REFERENCES product_dim(product_id)
);

-- Insert sample customer feedback
INSERT INTO customer_feedback VALUES
(1, 1, '2023-12-15', 'Enterprise', 'Amazing camera quality for business presentations. The 5G speed is incredible for video calls.', 'positive', 5),
(2, 1, '2023-12-18', 'Consumer', 'Love the phone but battery life could be better when using 5G constantly.', 'mixed', 4),
(3, 2, '2023-12-10', 'Enterprise', 'Perfect laptop for our remote workforce. Performance is outstanding and battery lasts all day.', 'positive', 5),
(4, 2, '2023-12-20', 'Education', 'Great for students. The display quality makes it easy to work on projects for hours.', 'positive', 5),
(5, 3, '2023-11-25', 'Consumer', 'Noise cancellation works well on flights. Sound quality exceeds expectations.', 'positive', 5),
(6, 3, '2023-12-05', 'Consumer', 'Good earbuds but had connectivity issues with older devices.', 'mixed', 3),
(7, 4, '2023-12-01', 'Consumer', 'The health tracking features are accurate and motivating. Battery life is excellent.', 'positive', 5),
(8, 4, '2023-12-12', 'Consumer', 'Comfortable to wear all day. GPS tracking during runs is very accurate.', 'positive', 4),
(9, 5, '2023-11-30', 'Education', 'Perfect for note-taking in class. The stylus is responsive and feels natural.', 'positive', 5),
(10, 5, '2023-12-08', 'Enterprise', 'Great for presentations and field work. Screen is bright enough for outdoor use.', 'positive', 4);
```

---

### Step 2: Create Cortex Search Service

Create a search service that indexes product descriptions and customer feedback:

```sql
-- Create search service for product descriptions
CREATE OR REPLACE CORTEX SEARCH SERVICE product_search_service
  ON description, features, target_audience
  ATTRIBUTES product_id, product_name
  WAREHOUSE = cortex_analyst_wh
  TARGET_LAG = '1 minute'
  AS (
    SELECT 
        product_id,
        product_name,
        description,
        features,
        target_audience
    FROM product_descriptions
  );

-- Create search service for customer feedback
CREATE OR REPLACE CORTEX SEARCH SERVICE feedback_search_service
  ON feedback_text
  ATTRIBUTES feedback_id, product_id, date, customer_segment, sentiment, rating
  WAREHOUSE = cortex_analyst_wh
  TARGET_LAG = '1 minute'
  AS (
    SELECT 
        feedback_id,
        product_id,
        date,
        customer_segment,
        feedback_text,
        sentiment,
        rating
    FROM customer_feedback
  );
```

**Search Service Parameters:**
- **ON**: Columns to search (automatically vectorized)
- **ATTRIBUTES**: Additional columns to return with results
- **WAREHOUSE**: Compute resources for indexing
- **TARGET_LAG**: How quickly new data appears in search

---

### Step 3: Test Basic Search Queries

Test the search services with sample queries:

```sql
-- Search for products related to "camera and photography"
SELECT * FROM TABLE(
  product_search_service!SEARCH(
    'camera photography professional quality',
    LIMIT => 5
  )
);

-- Search for feedback about "battery life"
SELECT * FROM TABLE(
  feedback_search_service!SEARCH(
    'battery life duration performance',
    LIMIT => 10
  )
);

-- Hybrid search: specific keywords + semantic meaning
SELECT * FROM TABLE(
  feedback_search_service!SEARCH(
    'connectivity issues bluetooth problems',
    LIMIT => 5
  )
);
```

**Expected Results:**
- Products ranked by semantic relevance
- Feedback mentioning battery-related topics
- Results include similarity scores

---

## Part 2: Integrating Search with Cortex Analyst (25 minutes)

### Step 4: Create Search-Enabled Views

Create views that combine search capabilities with your fact tables:

```sql
-- View combining product search with revenue data
CREATE OR REPLACE VIEW product_search_analytics AS
SELECT 
    pd.product_id,
    pd.product_name,
    pd.description,
    pd.features,
    pd.target_audience,
    pl.product_line,
    COUNT(DISTINCT dr.date) as days_with_sales,
    SUM(dr.revenue) as total_revenue,
    SUM(dr.cogs) as total_cogs,
    AVG(dr.revenue) as avg_daily_revenue
FROM product_descriptions pd
JOIN product_dim pl ON pd.product_id = pl.product_id
LEFT JOIN daily_revenue dr ON pd.product_id = dr.product_id
GROUP BY pd.product_id, pd.product_name, pd.description, pd.features, pd.target_audience, pl.product_line;

-- View combining customer feedback with product performance
CREATE OR REPLACE VIEW feedback_analytics AS
SELECT 
    cf.feedback_id,
    cf.product_id,
    cf.date,
    cf.customer_segment,
    cf.feedback_text,
    cf.sentiment,
    cf.rating,
    pd.product_name,
    pl.product_line,
    dr.revenue as daily_revenue,
    dr.cogs as daily_cogs
FROM customer_feedback cf
JOIN product_descriptions pd ON cf.product_id = pd.product_id
JOIN product_dim pl ON cf.product_id = pl.product_id
LEFT JOIN daily_revenue dr ON cf.product_id = dr.product_id AND cf.date = dr.date;
```

---

### Step 5: Create Search Function for Semantic Model

Create a user-defined function that Cortex Analyst can call for semantic search:

```sql
-- Function to search products by description
CREATE OR REPLACE FUNCTION search_products(search_query STRING)
RETURNS TABLE (
    product_id INT,
    product_name STRING,
    relevance_score FLOAT,
    description STRING,
    features STRING
)
AS
$$
    SELECT 
        product_id,
        product_name,
        ROUND(search_score, 3) as relevance_score,
        description,
        features
    FROM TABLE(
        product_search_service!SEARCH(:search_query, LIMIT => 5)
    )
$$;

-- Function to search customer feedback
CREATE OR REPLACE FUNCTION search_feedback(search_query STRING)
RETURNS TABLE (
    feedback_id INT,
    product_id INT,
    relevance_score FLOAT,
    feedback_text STRING,
    sentiment STRING,
    rating INT
)
AS
$$
    SELECT 
        feedback_id,
        product_id,
        ROUND(search_score, 3) as relevance_score,
        feedback_text,
        sentiment,
        rating
    FROM TABLE(
        feedback_search_service!SEARCH(:search_query, LIMIT => 10)
    )
$$;

-- Test the functions
SELECT * FROM TABLE(search_products('professional photography'));
SELECT * FROM TABLE(search_feedback('battery performance'));
```

---

### Step 6: Update Semantic Model with Search Capabilities

Enhance your semantic model to include search functionality. In the Semantic View builder:

#### Add Product Descriptions Table

1. Navigate to your **REVENUE_TIMESERIES** semantic view
2. Click **Edit**
3. In the **Tables** section, click **Add Table**
4. Select **PRODUCT_DESCRIPTIONS**
5. Configure columns:
   - `PRODUCT_ID`: Dimension
   - `PRODUCT_NAME`: Dimension
   - `DESCRIPTION`: Dimension (text)
   - `FEATURES`: Dimension (text)
   - `TARGET_AUDIENCE`: Dimension (text)

#### Add Feedback Table

1. Click **Add Table** again
2. Select **CUSTOMER_FEEDBACK**
3. Configure columns:
   - `FEEDBACK_ID`: Dimension
   - `PRODUCT_ID`: Dimension
   - `DATE`: Time
   - `CUSTOMER_SEGMENT`: Dimension
   - `FEEDBACK_TEXT`: Dimension (text)
   - `SENTIMENT`: Dimension
   - `RATING`: Fact

#### Define New Relationships

Add relationships to connect the new tables:

```yaml
relationships:
  # Existing relationships
  - name: revenue_to_product
    left_table: DAILY_REVENUE
    relationship_columns:
      - left_column: PRODUCT_ID
        right_column: PRODUCT_ID
    right_table: PRODUCT_DIM

  - name: revenue_to_location
    left_table: DAILY_REVENUE
    relationship_columns:
      - left_column: LOCATION_ID
        right_column: LOCATION_ID
    right_table: LOCATION_DIM

  # New relationships for search integration
  - name: product_to_descriptions
    left_table: PRODUCT_DIM
    relationship_columns:
      - left_column: PRODUCT_ID
        right_column: PRODUCT_ID
    right_table: PRODUCT_DESCRIPTIONS

  - name: feedback_to_product
    left_table: CUSTOMER_FEEDBACK
    relationship_columns:
      - left_column: PRODUCT_ID
        right_column: PRODUCT_ID
    right_table: PRODUCT_DIM

  - name: feedback_to_revenue
    left_table: CUSTOMER_FEEDBACK
    relationship_columns:
      - left_column: PRODUCT_ID
        right_column: PRODUCT_ID
      - left_column: DATE
        right_column: DATE
    right_table: DAILY_REVENUE
```

---

### Step 7: Add Search-Specific Custom Instructions

Update the custom instructions in your semantic model to include search guidance:

```
When users ask about product features, descriptions, or capabilities, prioritize using the PRODUCT_DESCRIPTIONS table to provide detailed information.

When users ask about customer sentiment, feedback, or reviews, use the CUSTOMER_FEEDBACK table and consider filtering by sentiment or rating.

For questions combining search terms with analytics (e.g., "revenue for products with camera features"), join PRODUCT_DESCRIPTIONS with revenue tables.

When analyzing feedback, always include the sentiment and rating context in the results.
```

---

### Step 8: Create Verified Queries with Search

Add verified queries that demonstrate search + analytics patterns:

#### Query 1: Revenue by Product Features
```sql
-- Find revenue for products with specific features
SELECT 
    pd.product_name,
    pd.features,
    SUM(dr.revenue) as total_revenue,
    COUNT(DISTINCT dr.date) as sales_days
FROM product_descriptions pd
JOIN daily_revenue dr ON pd.product_id = dr.product_id
WHERE pd.features ILIKE '%camera%' OR pd.features ILIKE '%display%'
GROUP BY pd.product_name, pd.features
ORDER BY total_revenue DESC;
```

#### Query 2: Feedback Analysis with Revenue
```sql
-- Analyze customer sentiment by product performance
SELECT 
    pl.product_line,
    cf.sentiment,
    COUNT(*) as feedback_count,
    AVG(cf.rating) as avg_rating,
    SUM(dr.revenue) as total_revenue
FROM customer_feedback cf
JOIN product_dim pl ON cf.product_id = pl.product_id
LEFT JOIN daily_revenue dr ON cf.product_id = dr.product_id AND cf.date = dr.date
GROUP BY pl.product_line, cf.sentiment
ORDER BY pl.product_line, cf.sentiment;
```

#### Query 3: Top Products by Target Audience
```sql
-- Revenue breakdown by target audience
SELECT 
    pd.target_audience,
    COUNT(DISTINCT pd.product_id) as product_count,
    SUM(dr.revenue) as total_revenue,
    AVG(dr.revenue) as avg_revenue
FROM product_descriptions pd
JOIN daily_revenue dr ON pd.product_id = dr.product_id
GROUP BY pd.target_audience
ORDER BY total_revenue DESC;
```

Add these as verified queries in the Semantic View builder.

---

### Step 9: Test Hybrid Analytics Queries

Test your enhanced semantic model with questions that combine search and analytics:

#### Test Question 1: Feature-Based Revenue Analysis
**Question:** 
> "What is the total revenue for products with camera features?"

**Expected Behavior:**
- Cortex Analyst searches PRODUCT_DESCRIPTIONS for "camera" mentions
- Joins with DAILY_REVENUE to calculate total revenue
- Returns products and their revenue

#### Test Question 2: Sentiment-Revenue Correlation
**Question:**
> "Show me average revenue and customer ratings by product line"

**Expected Behavior:**
- Joins CUSTOMER_FEEDBACK with PRODUCT_DIM and DAILY_REVENUE
- Calculates average rating and revenue per product line
- Reveals correlation between ratings and performance

#### Test Question 3: Target Audience Analysis
**Question:**
> "Which target audience generates the most revenue?"

**Expected Behavior:**
- Uses PRODUCT_DESCRIPTIONS.TARGET_AUDIENCE
- Aggregates revenue by audience segment
- Ranks audiences by revenue

#### Test Question 4: Feedback-Driven Insights
**Question:**
> "What are customers saying about battery life, and how does it impact sales?"

**Expected Behavior:**
- Searches CUSTOMER_FEEDBACK for "battery life" mentions
- Shows sentiment distribution
- Correlates with revenue trends

---

## Part 3: Advanced Search Patterns (Optional)

### Pattern 1: Multi-Table Search with Aggregation

Create a view that enables complex search + analytics:

```sql
CREATE OR REPLACE VIEW product_intelligence AS
SELECT 
    pd.product_id,
    pd.product_name,
    pd.description,
    pd.features,
    pl.product_line,
    SUM(dr.revenue) as total_revenue,
    AVG(cf.rating) as avg_rating,
    COUNT(DISTINCT cf.feedback_id) as feedback_count,
    ARRAY_AGG(DISTINCT cf.sentiment) as sentiments,
    LISTAGG(DISTINCT lr.sales_region, ', ') as regions_sold
FROM product_descriptions pd
JOIN product_dim pl ON pd.product_id = pl.product_id
LEFT JOIN daily_revenue dr ON pd.product_id = dr.product_id
LEFT JOIN customer_feedback cf ON pd.product_id = cf.product_id
LEFT JOIN location_dim lr ON dr.location_id = lr.location_id
GROUP BY pd.product_id, pd.product_name, pd.description, pd.features, pl.product_line;
```

---

### Pattern 2: Time-Based Search Analytics

Analyze how feedback sentiment changes over time:

```sql
CREATE OR REPLACE VIEW feedback_trends AS
SELECT 
    DATE_TRUNC('month', cf.date) as month,
    pl.product_line,
    cf.sentiment,
    COUNT(*) as feedback_count,
    AVG(cf.rating) as avg_rating,
    SUM(dr.revenue) as monthly_revenue
FROM customer_feedback cf
JOIN product_dim pl ON cf.product_id = pl.product_id
LEFT JOIN daily_revenue dr ON cf.product_id = dr.product_id AND cf.date = dr.date
GROUP BY month, pl.product_line, cf.sentiment
ORDER BY month DESC, pl.product_line, cf.sentiment;
```

---

### Pattern 3: Search-Based Alerts

Create a view that identifies products with negative feedback requiring attention:

```sql
CREATE OR REPLACE VIEW products_needing_attention AS
SELECT 
    pd.product_name,
    pl.product_line,
    COUNT(*) as negative_feedback_count,
    AVG(cf.rating) as avg_rating,
    LISTAGG(cf.feedback_text, ' | ') WITHIN GROUP (ORDER BY cf.date DESC) as recent_feedback,
    SUM(dr.revenue) as recent_revenue
FROM customer_feedback cf
JOIN product_descriptions pd ON cf.product_id = pd.product_id
JOIN product_dim pl ON cf.product_id = pl.product_id
LEFT JOIN daily_revenue dr ON cf.product_id = dr.product_id AND cf.date = dr.date
WHERE cf.sentiment = 'negative' OR cf.rating <= 2
GROUP BY pd.product_name, pl.product_line
HAVING COUNT(*) >= 2  -- At least 2 negative feedbacks
ORDER BY negative_feedback_count DESC, avg_rating ASC;
```

---

## Real-World Use Cases

### E-Commerce Platform
**Challenge:** Product discovery + sales analytics  
**Solution:** Search product catalog by features, correlate with conversion rates and revenue
```
"What are the best-selling products with wireless charging?"
"Show revenue trends for products targeting professionals"
```

### Customer Support
**Challenge:** Identify product issues impacting satisfaction  
**Solution:** Search support tickets, analyze sentiment, correlate with sales impact
```
"What issues are customers reporting about smartphones?"
"Show products with declining ratings and their revenue impact"
```

### Marketing Analytics
**Challenge:** Content effectiveness measurement  
**Solution:** Search campaign content, measure engagement and conversion
```
"Which product features resonate most with enterprise customers?"
"Revenue performance for products marketed to students"
```

### Product Development
**Challenge:** Feature prioritization based on feedback  
**Solution:** Search feature requests, prioritize by revenue impact
```
"What features do customers want most in high-revenue products?"
"Show feature requests from our most valuable customer segments"
```

---

## Best Practices

### 1. Search Service Design
- **Index Strategy**: Only index columns users will search
- **Update Frequency**: Set TARGET_LAG based on data freshness needs
- **Warehouse Sizing**: Right-size for indexing workload

### 2. Query Performance
- **Limit Results**: Use LIMIT to control search result count
- **Filter Early**: Apply filters before search when possible
- **Cache Strategy**: Leverage query result caching for common searches

### 3. Semantic Model Integration
- **Clear Descriptions**: Document search-enabled tables clearly
- **Verified Queries**: Include search + analytics patterns
- **Custom Instructions**: Guide when to use search vs. regular queries

### 4. User Experience
- **Natural Language**: Design for how users actually ask questions
- **Result Ranking**: Understand relevance scoring
- **Fallback Patterns**: Handle cases when search returns no results

---

## Session Summary

In this session, you've learned:

✅ **Cortex Search Basics**: Creating and configuring search services  
✅ **Semantic Search**: Understanding vector-based search capabilities  
✅ **Hybrid Analytics**: Combining search with structured data queries  
✅ **Semantic Model Integration**: Adding search to Cortex Analyst  
✅ **Advanced Patterns**: Multi-table search, sentiment analysis, alerts  
✅ **Real-World Applications**: E-commerce, support, marketing use cases  

You can now build analytics solutions that combine the power of semantic search with structured data analysis!

---

## Hands-On Exercises

Try these exercises to reinforce your learning:

### Exercise 1: Product Catalog Search
Build queries that find products by features and show their revenue performance.

### Exercise 2: Customer Sentiment Dashboard
Create a view that tracks sentiment trends and correlates with sales.

### Exercise 3: Market Segment Analysis
Use target audience search to analyze which segments drive the most revenue.

### Exercise 4: Feedback Alert System
Set up queries that identify products requiring immediate attention based on feedback.

---

## Additional Resources

- [Cortex Search Documentation](https://docs.snowflake.com/en/user-guide/cortex-search)
- [Vector Embeddings Guide](https://docs.snowflake.com/en/user-guide/cortex-embeddings)
- [Hybrid Search Patterns](https://docs.snowflake.com/en/user-guide/cortex-search-hybrid)
- [Search Performance Optimization](https://docs.snowflake.com/en/user-guide/cortex-search-optimization)

---

**Previous**: [Session 2: Building with Cortex Analyst](SESSION_2_CORTEX_ANALYST.md)  
**Next**: [Session 4: Advanced Analytics with Snowflake Intelligence](SESSION_4_SNOWFLAKE_INTELLIGENCE.md)

