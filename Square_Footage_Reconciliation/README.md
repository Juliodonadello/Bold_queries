# Query Summary

## CTEs Overview

1. **SQ_FT_TEMP**

   **Purpose:** 
   - Calculates total square footage for properties and retrieves relevant square footage types from related tables.

   **Filter:**
   - Units and properties must not be deleted.
   - Deleted date of units should be on or after `@AsOfDate` or be NULL.
   - Property name must be in `@Property_Name`.
   - Company relation ID must match `@REAL_COMPANY_ID`.
   - Square footage type must be in `@Sqft_Type`.
   - Effective date of property square footage items must be on or before `@AsOfDate`.

2. **UNITS**

   **Purpose:**
   - Retrieves detailed information about units, including total square footage and associated property details.

   **Filter:**
   - Units and properties must not be deleted.
   - Deleted date of units should be on or after `@AsOfDate` or be NULL.
   - Property name must be in `@Property_Name`.
   - Company relation ID must match `@REAL_COMPANY_ID`.
   - Square footage type must be in `@Sqft_Type`.
   - Effective date of unit square footage items must be on or before `@AsOfDate`.

## Final Query

The final `SELECT` statement joins the `UNITS` and `SQ_FT_TEMP` CTEs to provide a comprehensive view of unit square footage compared to property square footage.

**Key Outputs:**
- Property ID and Name
- Unit ID and Name
- Unit Square Footage
- Square Footage Type
- Unit Class
- Company ID
- Total Property Square Footage
- Property Square Footage
