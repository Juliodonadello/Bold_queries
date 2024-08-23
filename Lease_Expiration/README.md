## Query Summary

### Overview

This query retrieves lease details, including information about properties, units, tenants, and total square footage. It uses a Common Table Expression (CTE) named `SQ_FT_TEMP` to calculate the total square footage for each property before joining this data with other relevant tables.

### CTE: `SQ_FT_TEMP`

- **Purpose**: The CTE calculates the total square footage (`TOT_SQ_FT`) for each property.
- **Tables Used**:
  - **`units`**: Provides square footage information for each unit.
  - **`properties`**: Links units to properties.
- **Conditions**:
  - Excludes deleted units and properties by checking that `deleted_at` is `NULL`.
- **Grouping**: The results are grouped by the property ID (`PROP_ID`).

### Main Query

The main query retrieves lease information, including:

- **Lease Details**: `id`, `name`, `status`, `end` date, etc.
- **Unit Details**: `units_id`, `units_name`, `city`, `total_square_footage`.
- **Tenant Details**: `tenants_id`, `tenants_name`.
- **Property Details**: `properties_id`, `properties_name`.
- **Additional Calculations**: Extracts the year from the lease end date (`EndDate_YEAR`) and includes the total square footage from the CTE (`TOT_SQ_FT`).

### Key Filters

1. **Lease End Date**: Filters out leases where the `end` date is `NULL`.
2. **Company Relation**: Filters properties by `company_relation_id`, matching `@REAL_COMPANY_ID`.
3. **Property Name**: Filters by property name, matching `@Property_Name`.

### Optional Filters

- **Lease Status**: A commented-out filter that can limit results to leases with specific statuses (`@Lease_Status`).
- **Lease End Date Range**: Another commented-out filter to select leases ending within a specified date range.

### Joins

The main query performs several `INNER JOIN` operations to combine data from the `leases`, `leases_units_units`, `units`, `tenants`, `properties` tables, and the CTE `SQ_FT_TEMP`.

### Notes

This query is designed to provide a comprehensive overview of lease information, enriched with calculated square footage data. The use of parameters and optional filters allows for flexibility in generating reports tailored to specific needs.
