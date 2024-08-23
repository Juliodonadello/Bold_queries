## Overview
This query extracts and analyzes sales data related to leases, focusing on specific properties. It retrieves sales data for the last 13 months, applies filters related to overage periods, and calculates monthly sales performance. The results categorize each month's sales data to determine the reporting status.

## Involved Tables
1. **leases**: Contains lease agreement details.
2. **rent_percentages**: Provides overage period and sales reporting frequency information.
3. **sales_entry**: Stores sales data, including transaction dates.
4. **leases_units_units**: Links leases to property units.
5. **units**: Details about the units, such as square footage.
6. **properties**: Information about the properties where leases are located.
7. **tenants**: Tenant information linked to leases.

## Key Filters
1. **Overage Period Validity**: Includes leases with a valid overage period.
2. **Property Name**: Filters data by the specified property (`@Property_Name`).
3. **Company Relation ID**: Ensures leases belong to the specified company (`@REAL_COMPANY_ID`).
4. **Date Range**: Includes sales data from the last 13 months.
5. **Deleted Records**: Excludes records marked as deleted.

## Joins
1. **leases_units_units → leases**: Connects leases to their corresponding units.
2. **units → leases_units_units**: Retrieves unit details.
3. **properties → leases**: Links leases to specific properties.
4. **rent_percentages → leases**: Adds overage details to leases.
5. **sales_entry → leases**: Connects sales data with leases.
6. **tenants → leases**: Adds tenant information to leases.

## Selected Fields
The query selects fields related to lease identifiers, property and unit details, tenant information, and sales data for the current and previous months, as well as the reporting status for each month.

1. **LEASE_ID**: Unique identifier for each lease.
2. **LEASE_NAME**: Name of the lease.
3. **start**: Start date of the lease.
4. **lease_end**: End date of the lease.
5. **overage_start_date**: Start date of the overage period.
6. **overage_end_date**: End date of the overage period.
7. **MONTHS_FRECUENCY**: Frequency at which sales reports are required.
8. **ITEM_ID**: Identifier for the item being reported.
9. **TYPE_REQUIRED**: Type of sales data required.
10. **PROP_NAME**: Name of the property.
11. **UNIT_NAME**: Name of the unit(s) associated with the lease.
12. **UNIT_SQ_FT**: Total square footage of the unit.
13. **TENANT**: Name(s) of the tenant(s).
14. **current_month**: Sales volume for the current month.
15. **previous_month_1**: Sales volume for the previous month (and so on for up to 12 months).
16. **status_current_month**: Status of sales reporting for the current month (e.g., "CER", "*", " ").
17. **status_previous_month_1**: Status of sales reporting for the previous month (and so on for up to 12 months).