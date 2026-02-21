# Data Understanding

## Overview

The Olist e-commerce dataset contains transactional and dimensional data describing customers, orders, products, and order items.  
The dataset follows a relational structure with fact and dimension tables.

---

# 1. Customers Dataset
File: olist_customers_dataset.csv

## Description
Contains customer geographic information.

Columns:
- customer_id
- customer_unique_id
- customer_zip_code_prefix
- customer_city
- customer_state

## Primary Key
- customer_id (Unique per order)

## Relationships
- customer_id → links to Orders table
- customer_zip_code_prefix → links to Geolocation table

---

# 2. Geolocation Dataset
File: olist_geolocation_dataset.csv

## Description

Contains geographic coordinate information for zip code prefixes.

Columns:
- geolocation_zip_code_prefix
- geolocation_lat
- geolocation_lng
- geolocation_city
- geolocation_state

## Primary Key (After Cleaning)
- geolocation_zip_code_prefix

Originally, this dataset contained multiple rows per zip prefix.
We aggregated it to ensure uniqueness.

## Relationships
- geolocation_zip_code_prefix → connects to Customers via zip code

## Role in Model
Geographic dimension table used for spatial analysis.


---

# 3. Order Items Dataset
File: olist_order_items_dataset.csv

## Description
Contains item-level details for each order.

Columns:
- order_id
- order_item_id
- product_id
- seller_id
- shipping_limit_date
- price
- freight_value

## Primary Key
Composite Key:
- (order_id, order_item_id)

## Relationships
- order_id → Orders table
- product_id → Products table
- seller_id → Sellers table

---
