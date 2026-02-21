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

# 2. Orders Dataset
File: olist_orders_dataset.csv

## Description
Contains order-level transactional information.

Columns:
- order_id
- customer_id
- order_status
- order_purchase_timestamp
- order_approved_at
- order_delivered_carrier_date
- order_delivered_customer_date
- order_estimated_delivery_date

## Primary Key
- order_id

## Relationships
- customer_id → Customers table
- order_id → Order Items table
- order_id → Payments table
- order_id → Reviews table

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

# 4. Products Dataset
File: olist_products_dataset.csv

## Description
Contains product catalog information.

Columns:
- product_id
- product_category_name
- product_name_length
- product_description_length
- product_photos_qty
- product_weight_g
- product_length_cm
- product_height_cm
- product_width_cm

## Primary Key
- product_id

## Relationships
- product_id → Order Items table

---

# Data Model Structure

Fact Tables:
- Orders
- Order Items

Dimension Tables:
- Customers
- Products
- Sellers
- Geolocation

The data model resembles a star-schema structure with Order Items as the central transactional fact.
