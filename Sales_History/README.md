# Query Summary

## CTEs Overview

1. **SALES**

   **Purpose:** 
   - Retrieves and categorizes sales data from the `sales_entry` table, including details about the transaction date, type, volume, and associated entities like units, leases, tenants, and properties.

   **Filter:**
   - Company relation ID must match `@REAL_COMPANY_ID`.
   - Transaction date must be within the last 4 years.
   - Lease name must be in `@Lease_Name`.
   - Property name must be in `@Property_Name`.
   - Sales type must be in `@Sales_Type`.
   - Sales category must be in `@Sales_Category`.

2. **Lease_History**

   **Purpose:**
   - Aggregates sales volume by month and year for each lease, providing a monthly breakdown of sales amounts.

   **Filter:**
   - Groups by year, month, transaction type, and other relevant columns to calculate total sales for each combination.

3. **Annual_Lease_History**

   **Purpose:**
   - Sums up monthly sales amounts to calculate annual sales totals for each lease.

   **Filter:**
   - Groups by year, transaction type group, lease ID, lease name, and company relation ID.

4. **Lease_History_With_Variation**

   **Purpose:**
   - Computes the percentage variation in annual sales amounts compared to the previous year for each lease.

   **Filter:**
   - Uses window functions to calculate previous annual amounts and percentage variation.

5. **FINAL**

   **Purpose:**
   - Aggregates sales data with historical variations to provide a comprehensive view of sales performance.

   **Filter:**
   - Joins with `Lease_History_With_Variation` to include historical variation data.
   - Groups by all relevant columns from `SALES`.

6. **AUX**

   **Purpose:**
   - Provides a list of month names for reference and joining purposes.

   **Filter:**
   - No specific filter; simply generates a static list of month names.

7. **AUX_MANY_UNITS**

   **Purpose:**
   - Aggregates sales data by month and year, summarizing for multiple units and leases.

   **Filter:**
   - Joins with `FINAL` on month names to combine sales data with month information.
   - Groups by all relevant columns, including lease ID and lease dates.

8. **BREAKPOINT_TOT**

   **Purpose:**
   - Retrieves breakpoint data including sales base amounts and overage percentages from relevant tables.

   **Filter:**
   - Sales type must be in `@Sales_Type`.
   - Sales category must be in `@Sales_Category`.
   - Breakpoint items and entries must be effective and not deleted.

9. **BREAKPOINT_MAX**

   **Purpose:**
   - Determines the most recent effective date for breakpoints based on sales type, sales category, and lease ID.

   **Filter:**
   - Sales type and sales category must match the specified values.
   - Effective date of breakpoint items must be on or before the current date.

10. **BREAKPOINT**

    **Purpose:**
    - Selects the latest breakpoint information, including base amounts and percentages, by joining with `BREAKPOINT_MAX`.

    **Filter:**
    - Groups by sales category, sale type, lease ID, and effective date to get the latest breakpoint data.

## Final Query

The final `SELECT` statement combines the summarized sales data with breakpoint information to provide a complete view of sales performance and breakpoint details.

**Key Outputs:**
- Sales data for different years (2024, 2023, 2022) by month.
- Percentage variation from previous years.
- Breakpoint details including sales base amounts, breakpoint amounts, and overage percentages.
