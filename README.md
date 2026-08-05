# Retail-Data-Cleaning-SQL# Retail Data Cleaning with SQL Server

## Overview

This project demonstrates a complete SQL data cleaning workflow using a messy retail sales dataset.

The objective is to transform raw data into a clean, structured dataset by applying data validation, standardization, and type conversion using SQL Server.

---

## Dataset

- Dataset: Indian Retail Sales Dataset (Raw / Uncleaned)
- Records: ~4,300
- Source: Kaggle
- Format: CSV

The raw dataset intentionally contains:

- Missing values
- Mixed date formats
- Inconsistent text formatting
- Invalid numeric values
- Blank strings
- Duplicate rows

---

## Project Workflow

```text
CSV
   ↓
Bronze (Raw Data)
   ↓
Silver (Cleaned Data)
```

---

## Data Cleaning Performed

### Date Cleaning

- Converted multiple date formats into SQL DATE format
- Handled invalid dates using TRY_CONVERT() and TRY_CAST()

### Missing Values

- Converted blank strings into NULL using NULLIF()
- Removed records with missing Order IDs

### Data Type Conversion

Converted raw text into appropriate SQL data types:

- DATE
- INT
- DECIMAL

### Data Validation

Validated:

- Age (0–100)
- Quantity (>0)
- Discount (0–1)
- Customer Satisfaction (0–5)
- Shipping Days (>=0)

### Standardization

Standardized:

- Gender values
- Order Status
- Return Flag

### Duplicate Handling

Removed fully identical duplicate rows using DISTINCT.

---

## SQL Concepts Used

- CASE
- TRY_CAST()
- TRY_CONVERT()
- NULLIF()
- TRIM()
- COALESCE()
- CAST()
- Data Validation
- Data Type Conversion

---

## Files

Retail_Data_Cleaning.sql

Contains:

- Database creation
- Bronze table creation
- Silver table creation
- Cleaning logic
- Data validation queries

---

## Skills Demonstrated

- SQL Data Cleaning
- ETL Workflow
- Data Validation
- Data Quality Assessment
- SQL Server
- Bronze → Silver Architecture

---

## Author

Ricardo
