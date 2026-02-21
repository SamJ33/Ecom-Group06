# Data Cleaning & Preprocessing  Report

## Datasets Processed:
- olist_customers_dataset.csv
- olist_order_items_dataset.csv  
- olist_geolocation_dataset.csv

---

## 1. Customers Dataset

# Key Cleaning Actions
- Standardized city names to consistent format (e.g., "sao paulo", "são paulo", "Sao Paulo" unified to "São Paulo").
- Standardized state abbreviations to uppercase two-letter format.
- Applied text normalization to resolve formatting inconsistencies across geographic fields.

# Rationale
- Ensures accurate geographic grouping and regional analysis.
- Prevents the same city from being treated as multiple distinct locations due to case sensitivity or special character variations.
- Maintains referential integrity when joining with other geographic data.

# Validation Checks
-  No missing values detected.
-  Customer_id verified as unique primary key.
-  All city/state values now follow consistent formatting rules.

---

## 2. Order Items Dataset

# Key Cleaning Actions
- Removed timestamp/date columns to eliminate data redundancy.
- Validated price and freight values (all >= 0).
- Created derived metric: `total_order_value = price + freight_value`.

# Rationale
- Temporal fields removed because they are already stored and managed in the Orders dataset.
- Maintains "single source of truth" principle for time-based analysis.
- Reduces table size and eliminates duplication across datasets.
- Focuses order_items table on its core purpose: product-level order details.

# Validation Checks
-  No missing values detected.
-  Composite key (order_id + order_item_id) verified as unique.
-  No negative revenue values detected.
-  Data model streamlined by removing redundant temporal columns.

---

## 3. Geolocation Dataset

# Key Cleaning Actions
- Aggregated duplicate zip code prefixes by calculating mean latitude and longitude.
- Dropped original latitude, longitude, and city columns after aggregation.
- Retained first city and state values with standardized formatting.
- Reduced dataset from ~1M rows to ~20k unique zip-level records.

# Rationale
- Original data contained multiple coordinate variations for the same zip code prefix, making analysis unreliable.
- Aggregation creates a clean, reliable lookup table for zip codes.
- Removing redundant granularity optimizes the table for join operations.
- Transforms messy point data into a usable geographic reference.

# Validation Checks
-  No missing values after aggregation.
-  geolocation_zip_code_prefix confirmed as unique primary key.
-  Dataset size optimized without losing analytical value.

---

## Analytical Integrity Principles Applied

- Preserved raw data before applying transformations.
- Validated data consistency before removing original columns.
- Engineered reliable geographic references before dropping granular coordinates.
- Ensured all transformations serve clear analytical purposes.