# Data Quality Report

This report summarizes data validation checks performed across core datasets.

---

# 1. Customers Dataset

## Null Checks
- No missing values detected.

## Duplicate Checks
- No full-row duplicates.
- customer_id verified as unique.

## Issues Found
- City and state formatting inconsistencies (standardized).

---

# 2. Orders Dataset

## Null Checks
- Some timestamps contain null values:
  - order_approved_at
  - order_delivered_carrier_date
  - order_delivered_customer_date

These are expected for:
- Cancelled orders
- Orders not yet delivered

## Duplicate Checks
- order_id verified as unique.

## Delivery Validation
Validated logical date order:

- order_purchase_timestamp <= order_approved_at
- order_approved_at <= order_delivered_carrier_date
- order_delivered_carrier_date <= order_delivered_customer_date

Inconsistencies should be investigated if found.

---

# 3. Order Items Dataset

## Null Checks
- No missing values detected.

## Duplicate Checks
- No full-row duplicates.
- Composite key (order_id + order_item_id) validated as unique.

## Revenue Validation
Checked:
- price >= 0
- freight_value >= 0

Created derived column:
- total_price = price + freight_value

No negative revenue detected.

---

# 4. Products Dataset

## Null Checks
Missing values detected in:
- product_category_name
- product_weight_g
- product_length_cm
- product_height_cm
- product_width_cm

Handling:
- Missing dimensions may affect shipping calculations.
- Missing category names may affect segmentation.

## Duplicate Checks
- product_id verified as unique.

---

# Overall Data Quality Summary

- Referential integrity validated across key relationships.
- Primary keys verified.
- Composite keys validated.
- Financial columns validated for non-negative values.
- Date sequences validated.
- Text fields standardized.

The dataset is now cleaned and suitable for analytical modeling and reporting.
