## Overview
This query analyzes lease and unit occupancy status, providing insights into when units become vacant and calculating vacancy durations. It calculates the end dates for leases and determines the status of units based on these dates.

## Involved Tables
1. **leases**: Contains lease details including start and end dates.
2. **leases_units_units**: Links leases to units.
3. **tenants**: Provides tenant names associated with leases.
4. **properties**: Contains property details, including company relation IDs.
5. **units**: Details about the units.

## Key Filters
1. **Lease Dates**: Filters leases that start before `@FromDate` and either end after `@FromDate` or have no end date.
2. **Deleted Records**: Excludes leases marked as deleted.
3. **Company Relation ID**: Ensures data belongs to the specified company (`@REAL_COMPANY_ID`).
4. **Property Name**: Filters by specified property (`@Property_Name`).
5. **Move-In Date**: Considers leases with move-in dates within the range from `@FromDate` to `@ToDate`.

## Joins
1. **leases → leases_units_units**: Links leases to units.
2. **leases → tenants**: Retrieves tenant information.
3. **leases → properties**: Connects leases to properties.
4. **leases_units_units → units**: Fetches unit details.
5. **leases → FINAL**: Adds calculated lease end and unit status.

## Selected Fields
1. **Lease Details**: ID, name, status, move-in date, and property information.
2. **Unit Details**: Name, occupancy status, and vacancy durations in months and years.
3. **Calculated Fields**: `Vacancy` and `Vacancy_years` showing periods of vacancy based on move-in and end dates.
