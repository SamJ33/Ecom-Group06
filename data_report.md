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


## Datasets Processed:
- olist_orders_dataset.csv  
- olist_order_payments_dataset.csv  
- olist_order_reviews_dataset.csv   

---

## 1. Orders Dataset

### Key Cleaning Actions
- Converted all lifecycle timestamp columns to `datetime` format.
- Filtered dataset to final outcome statuses: **delivered** and **canceled**.
- Removed logically inconsistent records (e.g., delivered orders with missing delivery timestamp).

### Rationale
- Ensures accurate analysis of order outcomes.
- Eliminates lifecycle contradictions that distort insights.
- Focuses analysis on meaningful, valid customer interactions.

### Validation Checks
- Verified timestamp conversion (`datetime64[ns]`).
- Confirmed no negative or invalid delivery durations.
- Confirmed delivered orders contain valid customer delivery dates.
- Preserved raw dataset prior to filtering.

---

## 2. Order Payments Dataset

### Key Cleaning Actions
- Standardized payment type categories.
- Remapped payment types to compact encoding (C, D, V, B).
- Removed redundant column: `payment_sequential`.

### Rationale
- Improves categorical clarity for visualization and modeling.
- Reduces dimensional noise without losing analytical meaning.
- Simplifies aggregation by payment method.

### Validation Checks
- Verified only four valid payment categories remain.
- Confirmed no unintended NaN values introduced during remapping.

---

## 3. Order Reviews Dataset

### Key Cleaning Actions
- Identified and quantified missing values in `review_comment_title`.
- Replaced null values with “no title”.

### Rationale
- Prevents loss of records due to missing optional text.
- Maintains dataset completeness for review analysis.
- Ensures consistent categorical behavior in dashboards.

### Validation Checks
- Confirmed no remaining null values in `review_comment_title`.
- Verified replacement did not alter existing non-null entries.

---
# Data Quality Report: Products & Logistics

## 1. Row Count Consistency

* **Products Dataset:** Verified at **32,951 rows**. No records were removed during cleaning, ensuring the complete product catalog is preserved.
* **Sellers Dataset:** Verified at **3,095 rows**. The dataset size remains consistent after geographic standardization.



## 2. Primary Key & Duplicate Validation

* **Null Values in Primary Keys:** A full audit of `product_id` and `seller_id` confirmed **zero null values**. Every record is properly identified.
* **Duplicate Keys:** Uniqueness tests were performed on both primary keys. There are **zero duplicate IDs**, ensuring 100% referential integrity for future SQL joins.



## 3. Quality Findings

* **Product Categories:** We identified and resolved **610 missing category names**. These were filled with the value **"unknown"** to maintain data density.
* **Logistics Dimensions:** We identified **2 products** with null weight and dimensions. These were handled (set to 0 or flagged) to prevent calculation failures in shipping KPIs.
* **Translation Coverage:** Cross-referencing revealed missing English names for `pc_gamer` and `portateis_cozinha`. These were **manually mapped** to ensure no "blank" categories appear in the final dashboard.

* **Revenue Non-negativity:** An audit of product attributes confirmed that all weights and dimensions are **non-negative**. This prevents "negative freight" errors that could corrupt total revenue calculations.
* **Delivery Duration Consistency:** We standardized all seller city and state names (e.g., converting "sp" to "SP" and "sao paulo" to "Sao Paulo"). This ensures that **Delivery Performance** metrics are correctly aggregated by region without duplication caused by inconsistent spelling or casing.



## 4. Data Optimization

To optimize the database for performance, the following **three columns** were dropped as they were deemed useless for business analysis:

* **`product_name_lenght`**: Metadata regarding character count; provides no business insight.
* **`product_description_lenght`**: Redundant metadata that does not impact revenue or logistics.
* **`seller_zip_code_prefix`**: Redundant since geographic analysis is performed at the City and State levels.


### Summary of Actions Taken:

1. **Fixed** 610 null categories by labeling them "unknown".
2. **Resolved** the UTF-8 BOM encoding issue in the translation file.
3. **Corrected** translation gaps for niche categories like `pc_gamer`.
4. **Standardized** seller geography for accurate regional reporting.
5. **Cleaned** the schema by removing 3 unnecessary columns.
