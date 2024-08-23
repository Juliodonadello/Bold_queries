## Query Summary

### Overview

This query retrieves detailed information about leases, including associated units, tenants, properties, and company accounts. It joins multiple tables to compile a comprehensive dataset based on specific filtering criteria.

### Involved Tables

- **`leases`**: Contains lease details.
- **`leases_units_units`**: Links leases to their respective units.
- **`units`**: Contains information about individual units.
- **`tenants`**: Contains information about tenants.
- **`properties`**: Contains property details.
- **`company_accounts`**: Contains company account information related to properties.

### Key Filters

1. **Company Relation**:
   - **Purpose**: Ensures that only leases associated with a specific company are retrieved.
   - **Condition**: The `company_relation_id` of properties must match the parameter `@REAL_COMPANY_ID`.
   
2. **Property Name**:
   - **Purpose**: Filters leases based on the names of properties.
   - **Condition**: The `properties.name` must be within the list provided by `@Property_Name`.
   
3. **Lease Status**:
   - **Purpose**: Filters leases based on their current status.
   - **Condition**: The `leases.status` must be within the list provided by `@Lease_Status`.

### Joins

The query performs several `INNER JOIN` operations to combine data from different tables:

- **`leases`** is joined with **`leases_units_units`** on `leases.id = leases_units_units.leasesId` to associate leases with their units.
- **`leases_units_units`** is joined with **`units`** on `units.id = leases_units_units.unitsId` to include unit details.
- **`leases`** is joined with **`tenants`** on `tenants.id = leases.primaryTenantId` to include tenant information.
- **`units`** is joined with **`properties`** on `units.property_id = properties.id` to include property details.
- **`properties`** is joined with **`company_accounts`** on `properties.company_relation_id = company_accounts.id` to include company account information.

### Selected Fields

The query selects the following fields:

- **Lease Details**:
  - `leases.id`
  - `leases.name`
  - `leases.status`
  - `leases.start`
  - `leases.end`

- **Unit Details**:
  - `units.name` AS `units_name`
  - `units.city`
  - `units.total_square_footage`

- **Tenant Details**:
  - `tenants.name` AS `tenants_name`

- **Property Details**:
  - `properties.name` AS `properties_name`

### Notes

This query is designed to extract comprehensive lease information by joining relevant tables and applying specific filters based on company relation, property name, and lease status. The use of parameters (`@REAL_COMPANY_ID`, `@Property_Name`, `@Lease_Status`) allows for flexibility and adaptability in generating reports tailored to specific business needs.
