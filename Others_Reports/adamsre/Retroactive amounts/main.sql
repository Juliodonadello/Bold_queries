with CHARGES AS (
SELECT "public"."properties"."name" "PROP_NAME",
"public"."units"."name" "UNIT_NAME",
"public"."tenants"."name" "TENANT_NAME",
"public"."leases"."name" "LEASE_NAME",
"lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID",
"public"."lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
"public"."lease_recurring_charge_amounts"."amount" "AMOUNT",
 LAG("public"."lease_recurring_charge_amounts"."amount") OVER (
            PARTITION BY "public"."leases"."name", "lease_recurring_charges"."order_entry_item_id"
            ORDER BY "public"."lease_recurring_charge_amounts"."effective_date"
        ) AS "previous_amount"

FROM "public"."leases"
INNER JOIN "public"."lease_units" ON "public"."leases"."id"="public"."lease_units"."lease_id"
INNER JOIN "public"."units" ON "public"."units"."id"="public"."lease_units"."unit_id"
INNER JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
INNER JOIN "public"."lease_recurring_charges" ON "public"."lease_recurring_charges"."lease_id" = "public"."leases"."id"
INNER JOIN "public"."lease_recovery_control" ON "public"."lease_recurring_charges"."recovery_control_id" = "public"."lease_recovery_control"."id"
INNER JOIN "public"."lease_recurring_charge_amounts" ON "public"."lease_recurring_charge_amounts"."recurring_charge_id" = "public"."lease_recurring_charges"."id"


WHERE CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
	AND "public"."leases"."deleted_at" IS NULL
	AND "public"."units"."deleted_at" IS NULL
	AND "public"."properties"."deleted_at" IS NULL
	AND "public"."tenants"."deleted_at" IS NULL
	AND "public"."lease_recurring_charges"."deleted_at" IS NULL
	AND "public"."lease_recovery_control"."deleted_at" IS NULL
	AND "public"."lease_recurring_charge_amounts"."deleted_at" IS NULL
	AND ("lease_recurring_charges"."order_entry_item_id" = 'R. E. TAX' OR "lease_recurring_charges"."order_entry_item_id" = 'TAX BID')
	AND "public"."lease_recovery_control"."recovery_to" = '06-30-2025'
    --AND "public"."lease_recurring_charge_amounts"."amount" > 0
	AND "lease_recurring_charges"."order_entry_item_id" in (@Item_Id)

GROUP BY 1,2,3,4,5,6,7
)
SELECT CHARGES."PROP_NAME",
CHARGES."UNIT_NAME",
CHARGES."TENANT_NAME",
CHARGES."LEASE_NAME",
CHARGES."ITEM_ID",
--'01/04/2025' AS "EFFECTIVE_DATE",
(CHARGES."AMOUNT" - COALESCE(CHARGES."previous_amount", 0)) * 4 AS "NEW_AMOUNT"

FROM CHARGES

WHERE CAST(CHARGES."EFFECTIVE_DATE" AS DATE) = CAST('1/1/2025' AS DATE)
AND (CHARGES."AMOUNT"- COALESCE(CHARGES."previous_amount", 0)) >= 1