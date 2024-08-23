## Query Summary

### Overview

This query retrieves information related to lease options, including details about properties, tenants, units, and lease statuses. It joins multiple tables to produce a filtered and ordered result set.

### Involved Tables

- **`lease_options`**: Contains lease option details.
- **`leases`**: Contains lease details.
- **`properties`**: Contains property information.
- **`tenants`**: Contains tenant information.
- **`leases_units_units`**: Links leases to units.
- **`units`**: Contains unit information.

### Key Filters

1. **Company Relation**: Filters properties by `company_relation_id`, matching `@REAL_COMPANY_ID`.
2. **Property Name**: Filters by property name matching `@Property_Name`.
3. **Date Range**: Includes lease options with `expiration_date` between `@FromDate` and `@ToDate`.

### Grouping and Ordering

- **Grouping**: The query groups results by various key fields to ensure uniqueness.
- **Ordering**: Results are sorted by `lease_category`.

### Notes

Optional filters for lease status are commented out but can be activated. The query is parameterized for flexibility, making it suitable for generating specific reports or analyses.
