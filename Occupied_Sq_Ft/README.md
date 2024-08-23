# SQL Query Summary

## Overview
The query calculates and retrieves various metrics related to lease and unit charges, including square footage and charge details, for properties matching specific criteria.

## CTEs and Their Purpose

1. **`CHARGE_CONTROL`**:
   - Retrieves charge controls for properties based on property name and company relation ID.
   - Determines whether each charge control is for base rent.
   - **Filters**:
     - Only includes properties whose names match `@Property_Name`.
     - Ensures the property belongs to the company with ID `@REAL_COMPANY_ID`.

2. **`CHARGES_TOT`**:
   - Collects recurring charges and their amounts, distinguishing between rent and other charges.
   - Joins with `CHARGE_CONTROL` to filter based on whether the charge is base rent.
   - **Filters**:
     - Includes charges with effective dates on or before `@AsOfDate`.
     - Considers charges not marked as deleted or deleted in the past.
     - Excludes one-time charges or includes them only if the difference between the effective date and `@AsOfDate` is less than a month.
     - Includes charges with termination dates on or after `@AsOfDate` or with no termination date.

3. **`MAX_CHARGES`**:
   - Finds the maximum effective date for each recurring charge.

4. **`CHARGES`**:
   - Joins `CHARGES_TOT` with `MAX_CHARGES` to get the most recent charge details.

5. **`LEASES`**:
   - Retrieves lease details including lease status, deposit information, and tenant names.
   - **Filters**:
     - Includes leases where the start date is on or before `@AsOfDate` and the end date is after `@AsOfDate`, or where the end date is NULL.
     - Only includes leases with a status of 'current'.
     - Excludes leases that are marked as deleted or deleted in the past.

6. **`LEASES_CHARGES`**:
   - Aggregates charges and lease details, ensuring proper grouping and summation.

7. **`SQ_FT_TEMP`**:
   - Calculates total square footage for each property.
   - **Filters**:
     - Considers only units that are not deleted and belong to properties that are not deleted.
     - Includes only properties belonging to the company with ID `@REAL_COMPANY_ID`.

8. **`UNITS`**:
   - Retrieves unit details including square footage and unit class.
   - **Filters**:
     - Includes units from properties that are not deleted.
     - Considers only units that are not deleted and belong to properties with the company ID `@REAL_COMPANY_ID`.

9. **`FINAL`**:
   - Combines and finalizes lease and charge details.

10. **`FINAL_AUX`**:
    - Calculates the count of distinct leases per unit.

## Final Selection and Calculations

The final `SELECT` statement:
- Joins `UNITS`, `SQ_FT_TEMP`, `FINAL`, and `FINAL_AUX` to aggregate data.
- **Filters**:
  - Only includes units from properties that match `@Property_Name`.
  - Considers only units with square footage types listed in `@Sqft_Type`.
  - Includes units with classes listed in `@Unit_Class`.
  - Ensures properties belong to the company with ID `@REAL_COMPANY_ID`.

- **Calculations**:
  - **Unit Square Footage**: Calculates the square footage of each unit and adjusts for occupancy.
  - **Occupied and Vacant Unit Square Footage**: Determines the square footage based on lease status.
  - **Percentage of Property**: Computes the proportion of the property covered by each unit.
  - **Annual Charges/Sq Ft**: Calculates the annual rent and other charges per square foot.

- **Ordering**:
  - Results are ordered by property name and unit name.
