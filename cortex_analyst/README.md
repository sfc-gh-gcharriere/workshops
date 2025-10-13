# Cortex Analyst Workshop

## Overview

This half-day workshop introduces students to **Snowflake Cortex Analyst**, a powerful AI-powered analytics tool that enables natural language interaction with data. Participants will learn how to leverage Cortex Analyst to ask questions in plain English and receive intelligent insights from their data.

## Workshop Objectives

By the end of this workshop, participants will be able to:

- Understand the core concepts of the Snowflake Platform
- Understand the core concepts and capabilities of Snowflake Cortex Analyst
- Set up and configure a Cortex Analyst environment
- Create semantic models for their data
- Interact with data using natural language queries
- Generate insights and visualizations through Snowflake Intelligence

## Prerequisites

### Technical Requirements
- Snowflake Trial account: https://signup.snowflake.com/
- Basic understanding of SQL
- Familiarity with data warehousing concepts

## Workshop Agenda (2.5-3 Hour Format)

### 📚 Session 1: Snowflake Platform Fundamentals (45 minutes)
**Introduction to Core Snowflake Capabilities**

Explore the foundational features of the Snowflake Data Cloud platform through hands-on demonstrations using real Citibike trip data.

**Topics Covered:**
- **Virtual Warehouses**: Create and resize warehouses, demonstrate auto-suspend/resume
- **Data Ingestion**: Load millions of rows from S3, compare performance across warehouse sizes
- **Time Travel**: Restore dropped tables and query historical data states
- **Zero-Copy Cloning**: Instant table cloning with full read/write capabilities
- **Secure Data Sharing**: Create private listings and share data with other accounts via Provider Studio
- **Streamlit Apps**: Overview of building interactive data applications

**Hands-On Activities:**
- Create and scale virtual warehouses (MEDIUM → SMALL → LARGE)
- Load Citibike data from external S3 stage
- Perform analytics queries with AI-generated SQL and chart visualization
- Drop and restore tables using Time Travel
- Clone tables with millions of rows instantly
- Create private data listings and share with neighbors

[📖 View Full Session Details →](SESSION_1_SNOWFLAKE_FUNDAMENTALS.md)

---

### 🛠️ Session 2: Building with Cortex Analyst (90 minutes)
**Hands-On Semantic Model Development**

Learn to build and configure Cortex Analyst from the ground up, creating semantic models that enable natural language analytics on your data.

**Part 1: Environment Setup (15 minutes)**
- Database, schema, warehouse, and stage creation
- CSV data upload and loading
- Permission configuration

**Part 2: Semantic Model Development (75 minutes)**
- Understanding semantic models
- Defining tables, dimensions, and measures
- Establishing table relationships
- Creating verified queries and custom instructions
- Testing with natural language questions

[📖 View Full Session Details →](SESSION_2_CORTEX_ANALYST.md)

---

### 🔍 Session 3: Cortex Search Integration with Cortex Analyst (15 minutes) - OPTIONAL
**Enhancing Analytics with Fuzzy Matching**

> **Optional Session:** This advanced topic demonstrates how to handle high cardinality columns with Cortex Search. Skip to Session 4 if you prefer to focus on core Cortex Analyst capabilities.

Cortex Search is a standalone service that can be integrated with Cortex Analyst to handle high cardinality columns such as product lines. Learn how this integration enables fuzzy matching that allows users to make mistakes with terminology and still get proper results.

**What You'll Learn:**
1. **The Problem**: Test queries that fail without exact terminology ("book" vs "Books")
2. **The Solution**: Create a Cortex Search service for product lines
3. **Integration**: Link the search service to your semantic model via Snowsight UI
4. **The Results**: Test fuzzy matching - "book and elec cat" → `IN ('Books', 'Electronics')`

**Key Takeaway:** Users no longer need to know exact values - Cortex Search handles variations, typos, and abbreviations automatically.

[📖 View Full Session Details →](SESSION_3_CORTEX_SEARCH_INTEGRATION.md)

---

### 🚀 Session 4: Advanced Analytics with Snowflake Intelligence (30 minutes)
**AI-Powered Insights and Automation**

Discover how to orchestrate AI tools using Snowflake Agents and leverage Snowflake Intelligence for conversational analytics and automated workflows.

**Topics Covered:**
- Creating and configuring AI agents
- Integrating Cortex Analyst with agents
- Building custom tools (email, notifications, APIs)
- Intelligent tool orchestration
- Conversational analytics
- Automatic visualization generation

[📖 View Full Session Details →](SESSION_4_SNOWFLAKE_INTELLIGENCE.md)

## Hands-On Lab Materials

### Sample Dataset
The workshop uses a comprehensive revenue analytics dataset including:

- **DAILY_REVENUE Table**: Daily revenue, COGS, and forecasted revenue data
- **PRODUCT_DIM Table**: Product information and product lines
- **REGION_DIM Table**: Sales regions and geographic information

<img width="1602" height="732" alt="Model" src="https://github.com/user-attachments/assets/14df9ae6-538e-4e5a-a232-89fba72345a7" />


### Key Data Elements
- **Time Dimension**: Date-based analysis capabilities
- **Measures**: Revenue, COGS, Forecasted Revenue, Profit calculations
- **Dimensions**: Product lines, sales regions, geographic states
- **Filters**: Large orders, DAPS region (Germany, Austria, Poland, Switzerland)

### Sample Questions for Practice
1. "What is the total revenue by product line for the last quarter?"
2. "Show me the daily cumulative cost of goods sold for December 2023"
3. "Which regions have the highest profit margins?"
4. "Compare actual revenue vs forecasted revenue by month"
5. "What are the top performing products in the DAPS region?"

## Quick Start Guide

### For Instructors
1. Review all four session files for detailed content and timing
2. Ensure all participants have Snowflake trial accounts created
3. Prepare the sample CSV files for distribution
4. Test the semantic model before the workshop
5. Familiarize yourself with common troubleshooting scenarios

### For Participants
1. **Pre-Workshop**: Sign up for a Snowflake trial account at https://signup.snowflake.com/
2. **Session 1**: Follow along with platform demonstrations
3. **Session 2**: Hands-on setup and semantic model creation (detailed steps in [Session 2](SESSION_2_CORTEX_ANALYST.md))
4. **Session 3** (Optional): Integrate Cortex Search for fuzzy matching on high cardinality columns
5. **Session 4**: Explore Snowflake Intelligence and agents

### Workshop Materials Checklist

**Session 1 (Citibike Data):**
- ✅ Snowflake account access
- ✅ Access to public S3 bucket: `s3://snowflake-workshop-lab/demo98/trips/`
- ✅ Partner account for data sharing exercises

**Session 2, 3 & 4 (Revenue Analytics):**
- ✅ Sample CSV files (`daily_revenue.csv`, `product.csv`, `location.csv`)
- ✅ Semantic model YAML file (`revenue_timeseries.yaml`)
- ✅ Session guides (4 detailed markdown files)
- ✅ Access to Snowsight web interface

## Workshop Structure

This workshop is organized into four detailed session guides:

| Session | Duration | Focus | Materials |
|---------|----------|-------|-----------|
| [Session 1](SESSION_1_SNOWFLAKE_FUNDAMENTALS.md) | 45 min | Platform fundamentals and core capabilities | Demos and examples |
| [Session 2](SESSION_2_CORTEX_ANALYST.md) | 90 min | Hands-on semantic model development | CSV files, SQL scripts, YAML |
| [Session 3](SESSION_3_CORTEX_SEARCH_INTEGRATION.md) ⭐ | 15 min | **OPTIONAL:** Cortex Search for fuzzy matching | Search service setup, integration demo |
| [Session 4](SESSION_4_SNOWFLAKE_INTELLIGENCE.md) | 30 min | AI agents and intelligence features | Agent configuration |

**Core Duration**: 2 hours 45 minutes  
**With Optional Session 3**: 3 hours (approx. half-day with breaks)

---

## Resources and Next Steps

### Documentation
- [Snowflake Cortex Analyst Documentation](https://docs.snowflake.com/en/user-guide/cortex-analyst)
- [Semantic Model Configuration Guide](https://docs.snowflake.com/en/user-guide/cortex-analyst-semantic-models)
- [Snowflake Intelligence Guide](https://docs.snowflake.com/en/user-guide/intelligence)
- [Streamlit Integration Examples](https://docs.snowflake.com/en/developer-guide/streamlit)

### Community & Support
- [Snowflake Community Forums](https://community.snowflake.com)
- [Cortex AI Resources](https://www.snowflake.com/cortex)
- [Quickstarts Library](https://quickstarts.snowflake.com)

### Additional Learning
- Explore the Snowflake Data Marketplace for sample datasets
- Try building semantic models for your own data
- Join Snowflake user groups and webinars
- Complete Snowflake certification programs

---

## Contact & Feedback

**Workshop Maintainer**: Gael Charriere - Snowflake Senior Solution Engineer
**Last Updated**: October 2025  

For questions, feedback, or contributions to this workshop, please reach out through your Snowflake account team.

---

**Ready to get started?** Begin with [Session 1: Snowflake Platform Fundamentals →](SESSION_1_SNOWFLAKE_FUNDAMENTALS.md)
