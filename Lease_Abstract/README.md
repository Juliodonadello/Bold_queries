# Report Summary

## Overview
This report contains four SQL queries related to key aspects of leases in a property database. Each file focuses on a specific theme: Lease Abstract, Lease Clauses, Lease Deposits, and Late Charges. These queries are designed to provide a detailed view of lease contracts, their terms, amounts, and specific associated conditions.

## Queries Summary

### 1. Lease_Abstract.sql
**Description**: 
This query extracts general lease details, including property, unit, lease status, and duration. It joins various tables related to properties, units, and recurring charges to create a comprehensive view of current and future leases.

**Key Filters**:
- **Effective Date**: Filters based on charge effective dates and frequency.
- **Lease Status**: Filters for leases that are current, canceled, terminated, or future.
- **Property and Company Relation**: Includes only properties that match `@Property_Name` and `@REAL_COMPANY_ID`.

### 2. Lease_Clauses.sql
**Description**: 
This query focuses on specific clauses within each lease, extracting details on contractual terms and conditions. It includes information about associated properties and units, filtered by relevant dates and clause type.

**Key Filters**:
- **Clause Type**: Filters specific clauses like lease type or custom clauses.
- **Creation and Termination Date**: Includes only clauses that remain active up to the query date.

### 3. Lease_Deposit.sql
**Description**: 
This query details lease deposits associated with each contract, including deposit amount, type, and associated unit. It provides insight into the initial financial obligations a tenant must meet.

**Key Filters**:
- **Lease Status**: Includes only leases in `current` status.
- **Properties and Units**: Filters by property and company relation to retrieve relevant deposits.

### 4. Lease_Late_Charges.sql
**Description**: 
This query retrieves information about late charges applied to leases, displaying the amount, frequency, and application date. It allows reviewing additional charges applied to tenants who fail to make timely payments.

**Key Filters**:
- **Charge Status**: Excludes charges that have been deleted (`deleted_at`).
- **Charge Frequency**: Includes only recurring charges, excluding one-time charges.
- **Effective Date**: Considers charges active as of the specified date (`@AsOfDate`).

## General Notes
These queries are highly parameterized, allowing flexibility for generating specific reports. The date and lease status filters enable customized views based on the status of the contractual and financial relationship with the tenant.

The Lease Abstract report merge these four queries into a detailed list and the main query is the "Lease_Abstract.sql" file. The other queries are left joined from it.

