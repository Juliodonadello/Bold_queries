WITH LEASE_RECOVERY AS (
SELECT "public"."leases"."id" "LEASE_ID",
"public"."recovery_control_expense_category"."expense_category" "EXPENSE_CATEGORY",
"public"."recovery_control_expense_category"."actual_expense"  "ACTUAL_EXPENSE"

FROM "public"."leases" 
INNER JOIN "public"."lease_recurring_charges" 
	ON "public"."leases"."id"="public"."lease_recurring_charges"."lease_id" 
INNER JOIN "public"."lease_recovery_control" 
	ON "public"."lease_recurring_charges"."recovery_control_id"="public"."lease_recovery_control"."id" 
INNER JOIN "public"."recovery_control_expense_category" 
	ON "public"."lease_recovery_control"."id"="public"."recovery_control_expense_category"."lease_recovery_control_id"
	
WHERE "public"."leases"."deleted_at" IS NULL
	AND "public"."lease_recurring_charges"."deleted_at" IS NULL
	AND "public"."lease_recovery_control"."deleted_at" IS NULL
	AND "public"."recovery_control_expense_category"."deleted_at" IS NULL
)
SELECT 
    LEASE_RECOVERY."LEASE_ID" AS "LEASE_ID",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Property Taxes' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Property_Tax",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Property Insurance' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Property_Insurance",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Security Lights - Electricity' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Electricity_Security_Lights",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Utilities' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Utilities",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'On-Site Manager' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "On_Site_Manager",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Replacements' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Replacements",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Repairs' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Repairs",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Parking Lot Repairs' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Parking_Lot_Repairs",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Supplies' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Supplies",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Pest Control' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Pest_Control",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Security' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Security",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Window Washing' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Window_Washing",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Trash Removal' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Trash_Removal",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Snow & Ice Removal' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Snow_Ice_Removal",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Landscaping' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Landscaping",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Landscaping - Additional' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Landscaping_Additional",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Janitorial' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Janitorial",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Miscellaneous' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Miscellaneous",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" = 'Management Fee' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "Management_Expense",
    SUM(CASE WHEN LEASE_RECOVERY."EXPENSE_CATEGORY" LIKE '%TICAM%' THEN LEASE_RECOVERY."ACTUAL_EXPENSE" ELSE 0 END) AS "TICAM",
    SUM(LEASE_RECOVERY."ACTUAL_EXPENSE") AS "Total_Expense"

FROM LEASE_RECOVERY 

GROUP BY LEASE_RECOVERY."LEASE_ID"
