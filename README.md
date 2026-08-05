# Retail Data Cleaning using SQL Server

## Overview

This project focuses on cleaning a messy retail sales dataset using SQL Server.

The raw dataset contains inconsistent date formats, missing values, invalid numeric values, and inconsistent categorical values. The data is cleaned and loaded from the Bronze layer into the Silver layer.

---

## Dataset

- Source: Kaggle
- Records: ~4,300
- Format: CSV

---

## Workflow

```
CSV
   ↓
Bronze (Raw Data)
   ↓
Silver (Cleaned Data)
```

---

## Cleaning Performed

- Converted mixed date formats to DATE
- Converted text columns to appropriate data types
- Removed blank values using `NULLIF()`
- Standardized gender values
- Standardized order status values
- Validated age, quantity, discount, shipping days and customer satisfaction
- Preserved valid negative profit values
- Removed identical duplicate rows

---

## SQL Concepts Used

- CASE
- TRY_CAST()
- TRY_CONVERT()
- CAST()
- NULLIF()
- TRIM()
- DISTINCT

---

## Files

- `Retail_Data_Cleaning.sql` – Complete SQL script for creating Bronze and Silver tables, cleaning the data, and loading the cleaned dataset.

