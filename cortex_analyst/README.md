# Cortex Analyst Workshop

## Workshop Structure

This workshop is organized into four session guides, available in **two formats**:

### 📖 Full Session Guides (Detailed)
Complete guides with explanations, best practices, and business context.

| Session | Duration | Focus | Materials |
|---------|----------|-------|-----------|
| [Session 1](SESSION_1_SNOWFLAKE_FUNDAMENTALS.md) | 45 min | Platform fundamentals and core capabilities | Demos and examples |
| [Session 2](SESSION_2_CORTEX_ANALYST.md) | 75 min | Hands-on semantic model development | CSV files, SQL scripts, Semantic Views |
| [Session 3](SESSION_3_CORTEX_SEARCH_INTEGRATION.md) ⭐ | 15 min | **OPTIONAL:** Cortex Search for fuzzy matching | Search service setup, integration demo |
| [Session 4](SESSION_4_SNOWFLAKE_INTELLIGENCE.md) | 30 min | Snowflake Intelligence and AI agents | Agent configuration |

### ⚡ Light Versions (Quick Reference)
Condensed versions with essential setup details, code blocks, and step-by-step instructions only.

| Session | Link |
|---------|------|
| Session 1 | [Quick Reference →](SESSION_1_SNOWFLAKE_FUNDAMENTALS_LIGHT.md) |
| Session 2 | [Quick Reference →](SESSION_2_CORTEX_ANALYST_LIGHT.md) |
| Session 3 | [Quick Reference →](SESSION_3_CORTEX_SEARCH_INTEGRATION_LIGHT.md) |
| Session 4 | [Quick Reference →](SESSION_4_SNOWFLAKE_INTELLIGENCE_LIGHT.md) |

**Core Duration**: 2 hours 30 minutes  
**With Optional Session 3**: 2 hours 45 minutes (approx. half-day with breaks)

📊 **[Download Workshop Slides (PDF)](Snowflake%20Workshop%20-%20Oct%202025.pdf)**

---

## Overview

Transform your data analytics with **Snowflake Cortex Analyst** - the AI-powered solution that enables business users to ask questions in natural language and receive instant, accurate insights from their data.

This hands-on workshop takes you from Snowflake fundamentals through building production-ready semantic models, with optional advanced topics on search integration and intelligent automation. In just 2.5 hours, you'll learn to democratize data access and empower your organization with conversational analytics.

**What Makes This Workshop Unique:**
- **100% Hands-On**: Build a complete semantic model from scratch using real revenue data
- **Production-Ready**: Learn best practices and patterns used by enterprises
- **Flexible Learning**: Core sessions plus optional advanced topics
- **Immediate Value**: Start querying your own data with natural language by end of day

## What You'll Build

By the end of this workshop, you will have created:

✅ A complete **semantic model** for revenue analytics that supports natural language queries  
✅ **Custom metrics** and **verified queries** tailored to business needs  
✅ **Integration with Cortex Search** for fuzzy matching on high cardinality data (optional)  
✅ Understanding of how to deploy and scale Cortex Analyst in production

**You'll be able to answer questions like:**
- "What is the total revenue for electronics in December?"
- "Show me profit trends by region"
- "Which products have the highest margins?"
- "Compare actual vs forecasted revenue by month"

All using plain English - no SQL required for end users!

---

## Prerequisites

### Technical Requirements
- Snowflake Trial account: <a href="https://signup.snowflake.com/" target="_blank">https://signup.snowflake.com/</a>
- Basic understanding of SQL
- Familiarity with data warehousing concepts

## Workshop Agenda (2.5 Hour Format)

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
- Create and scale virtual warehouses (Small to Large)
- Load Citibike data from external S3 stage
- Perform analytics queries with AI-generated SQL and chart visualization
- Drop and restore tables using Time Travel
- Clone tables with millions of rows instantly
- Create private data listings and share with neighbors

[📖 View Full Session Details →](SESSION_1_SNOWFLAKE_FUNDAMENTALS.md)

---

### 🛠️ Session 2: Building with Cortex Analyst (75 minutes)
**Hands-On Semantic Model Development**

Learn to build and configure Cortex Analyst from the ground up, creating semantic models that enable natural language analytics on your data.

**Part 1: Environment Setup (15 minutes)**
- Database, schema, and warehouse creation
- CSV data upload and loading
- Permission configuration

**Part 2: Semantic Model Development (60 minutes)**
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

### 🚀 Session 4: Snowflake Intelligence (30 minutes)
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

---

## Contact & Feedback

**Workshop Maintainer**: Gael Charriere - Snowflake Senior Solution Engineer
**Last Updated**: October 2025  

For questions, feedback, or contributions to this workshop, please reach out through your Snowflake account team.

---

**Ready to get started?** Begin with [Session 1: Snowflake Platform Fundamentals →](SESSION_1_SNOWFLAKE_FUNDAMENTALS.md)
