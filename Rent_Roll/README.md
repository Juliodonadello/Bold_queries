# Query Summary

## CTEs Overview

1. **CHARGE_CONTROL**

   **Purpose:** 
   - Retrieves properties along with their associated charge controls to determine whether a charge is for base rent or other types.

   **Filter:**
   - Property names must match `@Property_Name`.
   - Company relation ID must match `@REAL_COMPANY_ID`.

2. **CHARGES_TOT**

   **Purpose:**
   - Calculates and categorizes charges for each lease, distinguishing between base rent and other charges. Handles effective dates and frequencies.

   **Filter:**
   - Effective date of charge amounts must be on or before `@AsOfDate`.
   - Charge amounts must not be deleted before `@AsOfDate`.
   - Charges must not be deleted before `@AsOfDate`.
   - Frequency should not be 'One Time', or if it is, it should have an effective date within the last 30 days.
   - Termination date of charges must be on or after `@AsOfDate` or be NULL.

3. **MAX_CHARGES**

   **Purpose:**
   - Selects the most recent effective date for each recurring charge.

   **Filter:**
   - Groups by `RCHARGE_ID` to find the maximum effective date for each charge.

4. **CHARGES**

   **Purpose:**
   - Filters charges based on the most recent effective date and aggregates them by lease and unit.

   **Filter:**
   - Joins with `MAX_CHARGES` to ensure only the latest charges are included.
   - Groups by all relevant columns to summarize charges.

5. **LEASES**

   **Purpose:**
   - Gathers detailed lease information, including status, deposit information, and tenant details. Determines if a lease is occupied or vacant.

   **Filter:**
   - Lease start date must be on or before `@AsOfDate`.
   - Lease end date must be after `@AsOfDate` or be NULL.
   - Lease status must be 'current'.
   - Lease must not be deleted before `@AsOfDate`.

6. **LEASES_CHARGES**

   **Purpose:**
   - Combines lease information with charge details to provide a summary of rent and other charges, including counts of charge frequencies.

   **Filter:**
   - Joins `LEASES` and `CHARGES` to match lease and charge details.

7. **SQ_FT_TEMP**

   **Purpose:**
   - Computes the total square footage for each property.

   **Filter:**
   - Units and properties must not be deleted.
   - Company relation ID must match `@REAL_COMPANY_ID`.

8. **UNITS**

   **Purpose:**
   - Retrieves details and square footage of units, filtering for active units.

   **Filter:**
   - Properties must not be deleted.
   - Units must be active (not deleted before `@AsOfDate`).
   - Company relation ID must match `@REAL_COMPANY_ID`.

9. **FINAL**

   **Purpose:**
   - Aggregates and summarizes lease and charge data, ensuring correct grouping and calculation.

   **Filter:**
   - Groups by all relevant columns from `LEASES_CHARGES`.

10. **FINAL_AUX**

    **Purpose:**
    - Counts the number of leases per unit to adjust square footage calculations.

    **Filter:**
    - Groups by `UNIT_ID` to count distinct leases.

## Final Query

The final `SELECT` statement joins all previous CTEs and performs calculations to determine:
- Proportion of property square footage.
- Annualized charges.
- Charges per square foot.

**Key Outputs:**
- Property ID and Name
- Unit ID and Name
- Lease ID and Status
- Tenant Name
- Lease Dates and Square Footage
- Charges and Annualized Amounts 

**Notes**:
- If a lease only have Annualy charges, the annualized Amount is equal to the monthly charge amount diplayed. If there is at least one Monthly amount, then a x12 calculation is diplayed in the annualized amount.