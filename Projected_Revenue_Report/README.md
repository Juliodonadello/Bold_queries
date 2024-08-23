# SQL Query Summary

## Overview
This query aggregates lease charges across multiple months and years based on a specified date range. It generates a report that includes monthly and yearly totals for each lease, tenant, and property.

## CTEs and Their Purpose

1. **`date_series`**:
   - Generates a series of monthly dates starting from `@From_Date` up to `@To_Date`.
   - **Filters**:
     - The series includes dates up to `@To_Date`.

2. **`CHARGES_TOT`**:
   - Retrieves lease charge details including amounts, effective dates, and lease end dates.
   - **Filters**:
     - Includes charges with effective dates up to `@To_Date`.
     - Excludes deleted or terminated charges that end before `@To_Date`.
     - Filters charges based on `order_entry_item_id` in `@Item_Id`.
     - Includes properties matching `@Property_Name`.
     - Ensures properties belong to the company with ID `@REAL_COMPANY_ID`.
     - Considers charges where the effective date is before the lease end date or if the lease end date is NULL.

3. **`charged_amounts`**:
   - Calculates the charge amounts for each month in the `date_series`.
   - **Filters**:
     - Includes rows where the date series month is on or after the charge's effective date and before or on the lease end date.
   - **Calculations**:
     - Adjusts amounts for charges that end partway through a month, calculating prorated amounts for those days.

4. **`FINAL_TO_PIVOT`**:
   - Aggregates data for pivoting, preparing it for final output.
   - **Filters**:
     - Uses a left join to include all dates from the `date_series`, even if no charge amounts are present.

## Final Selection and Calculations

The final `SELECT` statement:
- Joins `FINAL_TO_PIVOT` with leases, tenants, and properties for comprehensive data.
- **Filters**:
  - Includes leases where the `month_to_month` status matches `@month_to_month`.
  - Includes leases with a status in `@Lease_Status`.

- **Calculations**:
  - **Monthly Amounts**: Sums charges for each of the first 12 months, rounding to two decimal places.
  - **Month Names**: Formats the month names as `'Mon, YY'`.
  - **Yearly Amounts**: Sums charges for the first three years starting from `@From_Date`, with the year names formatted as four digits.

- **Grouping and Ordering**:
  - Groups results by item ID, lease name, start and end dates, tenant name, and property name.
  - Orders by item ID, lease name, and end date.

## Example Output
- **Month 1 to Month 12**: Total charges for each of the first 12 months.
- **Year 1 to Year 3**: Total charges for the first three years.
- **Month Names**: Formatted names of the months corresponding to the charges.

This query is designed to provide a detailed breakdown of lease charges over time, with monthly and yearly summaries for each lease, tenant, and property, facilitating comprehensive financial analysis.
