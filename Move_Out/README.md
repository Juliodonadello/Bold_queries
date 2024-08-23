## Overview
This query retrieves lease details along with associated tenant, property, and unit information, focusing on leases within a specified date range and for a given company.

## Involved Tables
1. **leases**: Contains information about leases including move-out dates and termination reasons.
2. **properties**: Contains property details, including company relation IDs.
3. **tenants**: Provides tenant names associated with leases.
4. **leases_units_units**: Links leases to units.
5. **units**: Details about the units.

## Key Filters
1. **Deleted Records**: Excludes leases marked as deleted.
2. **Company Relation ID**: Filters by the specified company (`@REAL_COMPANY_ID`).
3. **Property Name**: Filters by specified property name (`@Property_Name`).
4. **Move-In Date**: Considers leases with move-in dates between `@FromDate` and `@ToDate`.

## Joins
1. **leases → properties**: Links leases to properties.
2. **leases → tenants**: Retrieves tenant information.
3. **leases → leases_units_units**: Connects leases to units.
4. **leases_units_units → units**: Fetches unit details.

## Selected Fields
1. **Lease Details**: ID, name, status, actual and intended move-out dates, reason for termination, company relation ID, and property ID.
2. **Tenant Details**: Tenant's name.
3. **Property Details**: Property name.
4. **Unit Details**: Unit name.
