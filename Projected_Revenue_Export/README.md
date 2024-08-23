# SQL Query Summary

## Overview
The query calculates and aggregates lease charges over a three-month period, taking into account effective dates, lease end dates, and various filters.

## CTEs and Their Purpose

1. **`date_series`**:
   - Generates a series of monthly dates starting from `@AsOfDate` and continuing for three months.
   - **Filters**:
     - Limits the series to dates less than `@AsOfDate + INTERVAL '3 month'`.

2. **`CHARGES_TOT`**:
   - Retrieves recurring charges and their amounts along with lease details.
   - **Filters**:
     - Includes charges with effective dates up to `@AsOfDate + INTERVAL '3 month'`.
     - Excludes charges that have been deleted or are set to terminate before the end of the three-month period.
     - Considers charges with `order_entry_item_id` in `@Item_Id`.
     - Includes properties with names in `@Property_Name`.
     - Ensures properties belong to the company with ID `@REAL_COMPANY_ID`.
     - Considers charges whose effective dates are before the lease end date or if the lease end date is NULL.

3. **`charged_amounts`**:
   - Calculates the charge amounts for each month in the `date_series`.
   - **Filters**:
     - Includes rows where the date series month is greater than or equal to the charge effective date and the lease end date is greater than or equal to the date series month.
   - **Calculations**:
     - Adjusts amounts for charges that end partway through a month, calculating the prorated amount for the days of the month the charge is active.

4. **`FINAL_TO_PIVOT`**:
   - Prepares data for pivoting by aggregating amounts per month and organizing them by various attributes.
   - **Filters**:
     - Uses a left join to include all dates from the `date_series`, even if no charge amounts are available.

## Final Selection and Calculations

The final `SELECT` statement:
- Joins `FINAL_TO_PIVOT` with leases, tenants, and properties to retrieve comprehensive details.
- **Filters**:
  - Includes leases where the `month_to_month` status matches `@month_to_month`.
  - Includes leases with a status in `@Lease_Status`.

- **Calculations**:
  - **Monthly Amounts**: Sums the charges for each of the three months, rounding to two decimal places.
  - **Month Names**: Formats the months as `'Mon, YY'` for easier readability.

- **Grouping and Ordering**:
  - Groups results by property, lease, tenant, and item IDs.
  - Orders by property ID, lease ID, item ID, and timestamp.

## Example Output
- **Month 1**: Total charges for the first month.
- **Month 2**: Total charges for the second month.
- **Month 3**: Total charges for the third month.
- **Month Names**: Formatted names of the months corresponding to the charges.

This query is designed to aggregate and present lease charge data in a structured format for analysis, taking into account various temporal and property-related filters.
