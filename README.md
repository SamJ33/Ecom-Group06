# Online Marketplace Analytics Project (Ecom-Group06)

## Business Context

The company operates a multi-region online marketplace processing thousands of orders.  
Management lacks standardized KPIs, a centralized analytics database, clean reporting tables, and performance dashboards.

This project builds a structured analytics pipeline to solve these gaps.

---

## Project Scope

### 1. Data Transformations (Python – Pandas)

All transformations are implemented as reproducible scripts.

#### Customers Cleaning
- Trim whitespace  
- City → Title Case  
- State → Uppercase  
- Remove duplicate `customer_id`  
**Output:** `customers_clean.csv`

#### Products Cleaning
- Replace missing categories with `"unknown"`  
- Convert categories to lowercase with underscores  
**Output:** `products_clean.csv`

#### Orders Cleaning
- Parse datetime fields  
- Keep delivered orders  
- Create:
  - `order_date`
  - `delivery_date`
  - `delivery_days`
  - `is_delayed`  
**Output:** `orders_clean.csv`

#### Revenue Enrichment
- Join order items with orders  
- Compute item-level revenue  
- Aggregate to order level  
**Output:** `orders_revenue_enriched.csv`

---

### 2. Data Quality Validation

Validate:
- Row count consistency  
- No null primary keys  
- No duplicate keys  
- Revenue ≥ 0  
- Valid delivery durations  


---

### 3. SQL Analytics Modeling

Load processed CSVs into staging tables.

Build a Star Schema:

- **Fact Table:** `fact_orders`  
- **Dimension Tables:**  
  - `dim_customers`  
  - `dim_products`  
  - `dim_date`  

Revenue must originate from the enriched revenue dataset.

---

### 4. Power BI Dashboards

- **Sales Overview:** Revenue, Orders, AOV, Monthly Trend  
- **Product Performance:** Revenue by Category, Top Products  
- **Regional Performance:** Revenue by State/City  
- **Delivery Performance:** On-time vs Delayed %

