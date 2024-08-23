## Query Summary

### Overview

This query retrieves insurance information linked to leases, properties, units, and tenants. It pulls data from multiple related tables to provide a detailed overview of insurance policies, including their type, status, and associated lease information.

### Involved Tables

- **`insurances`**: Contains details about insurance policies.
- **`leases`**: Provides information on leases associated with the insurance policies.
- **`leases_units_units`**: Links leases to specific units.
- **`units`**: Contains unit information related to leases.
- **`properties`**: Provides property details linked to leases and insurance.
- **`tenants`**: Contains information about the primary tenant associated with the lease.

### Key Filters

1. **Company Relation**: Filters results based on the property’s `company_relation_id`, matching `@REAL_COMPANY_ID`.
2. **Insurance Expiration Date**: Filters insurance policies where the `expiration_date` is between `@FromDate` and `@To_Date`.
3. **Lease Status**: Filters leases based on their status, matching the `@Lease_Status` parameter.
4. **Property Name**: Filters by property name, matching `@Property_Name`.
5. **Insurance Type**: Filters insurance policies based on their type, matching `@Insurance_Type`.

### Joins

The query performs multiple `INNER JOIN` operations to link data from the `insurances`, `leases`, `leases_units_units`, `units`, `properties`, and `tenants` tables:

- **`insurances`** is joined with `leases` to associate insurance policies with leases.
- **`leases`** is linked to `leases_units_units` and then to `units` to provide unit-level details.
- **`properties`** is joined to include property information.
- **`tenants`** is joined to provide details on the primary tenant associated with the lease.

### Selected Fields

- **Insurance Details**: `id`, `insurance_type`, `company`, `policy_number`, `email_to`, `effective_date`, `expiration_date`, `insurance_value`, etc.
- **Lease Details**: `name`, `status`.
- **Unit Details**: `units_name`.
- **Property Details**: `property_name`.
- **Tenant Details**: `primary_tenant_name`.

### Notes

This query is designed to extract comprehensive insurance policy details, filtering the results based on specific criteria like company relation, lease status, and insurance type. It provides a robust overview that can be tailored further using the provided parameters.
