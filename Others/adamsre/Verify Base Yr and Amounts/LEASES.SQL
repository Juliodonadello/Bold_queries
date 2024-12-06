with RECOVERY as (
  SELECT "public"."lease_recurring_charges"."id" "RCHARGE_ID",
"public"."lease_recurring_charges"."lease_id" "LEASE_ID",
"public"."lease_recovery_control"."name" AS "ITEM_ID_NAME",
"public"."lease_recovery_control"."process_recovery_month_frequency" AS "freq",
"public"."lease_recovery_control"."calculation_control_base_year"  AS "base_year",
"public"."lease_recovery_control"."calculation_control_base_amount"  AS "base_amount",
"public"."recovery_control_expense_category"."manual_percent",
"public"."lease_recurring_charges"."billToTenant" "billToTenant",
"public"."lease_recurring_charges"."next_date" "next_date",
"public"."lease_recurring_charge_amounts"."effective_date" "effective_date",
"public"."lease_recurring_charge_amounts"."amount" "RCHARGE_AMOUNT"
  
FROM "public"."lease_recovery_control" 
LEFT JOIN "public"."recovery_control_expense_category" 
	ON "public"."lease_recovery_control"."id"="public"."recovery_control_expense_category"."lease_recovery_control_id"
INNER JOIN "public"."lease_recurring_charges" 
	ON "public"."lease_recurring_charges"."recovery_control_id"="public"."lease_recovery_control"."id"
INNER JOIN "public"."lease_recurring_charge_amounts"
		ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
  
where "public"."lease_recovery_control"."name" = 'R. E. TAX'
AND ("public"."lease_recovery_control"."deleted_at" >= @AsOfDate OR "public"."lease_recovery_control"."deleted_at" IS NULL)
AND ("public"."recovery_control_expense_category"."deleted_at" >= @AsOfDate OR "public"."recovery_control_expense_category"."deleted_at" IS NULL)
AND ("public"."lease_recovery_control"."deleted_at" >= @AsOfDate OR "public"."lease_recovery_control"."deleted_at" IS NULL)
AND ("public"."lease_recurring_charges"."deleted_at" >= @AsOfDate OR "public"."lease_recurring_charges"."deleted_at" IS NULL)
AND ("public"."lease_recurring_charge_amounts"."deleted_at" >= @AsOfDate OR "public"."lease_recurring_charge_amounts"."deleted_at" IS NULL)
AND "public"."lease_recurring_charge_amounts"."effective_date" <= @AsOfDate
),
MAX_RECOVERY AS (
  select "LEASE_ID", 
  MAX("effective_date") as "effective_date"
  from RECOVERY
  group by "LEASE_ID"
),
RECOVERY_FINAL AS (
  select RECOVERY.*
FROM RECOVERY
INNER JOIN MAX_RECOVERY 
  	ON MAX_RECOVERY."LEASE_ID"= RECOVERY."LEASE_ID"
  	AND MAX_RECOVERY."effective_date"= RECOVERY."effective_date"
)

SELECT 
"public"."properties"."name",
"public"."units"."name" AS "units_name",
"public"."leases"."name" AS "leases_name",
"public"."tenants"."name" AS "tenants_name",
--"public"."tenants"."id" AS "tenants_id",
--RECOVERY_FINAL."billToTenant",
"public"."leases"."end" AS "LEASE_END",
RECOVERY_FINAL."ITEM_ID_NAME",
RECOVERY_FINAL."base_year",
RECOVERY_FINAL."base_amount",
RECOVERY_FINAL."freq",
RECOVERY_FINAL."next_date",
RECOVERY_FINAL."effective_date",
RECOVERY_FINAL."RCHARGE_AMOUNT" as "CURRENT_AMOUNT"

FROM "public"."properties" 
INNER JOIN "public"."units" 					ON "public"."properties"."id"="public"."units"."property_id" 
INNER JOIN "public"."leases_units_units" ON "public"."units"."id"="public"."leases_units_units"."unitsId" 
INNER JOIN "public"."leases" 					ON "public"."leases_units_units"."leasesId"="public"."leases"."id" 
INNER JOIN "public"."tenants" 				   ON "public"."leases"."primaryTenantId"="public"."tenants"."id" 
INNER JOIN RECOVERY_FINAL					ON RECOVERY_FINAL."LEASE_ID" = "public"."leases"."id"

WHERE  CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
AND CAST("public"."properties"."name" AS TEXT) IN (@Property_Name)
AND  CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
AND ("public"."properties"."deleted_at" >= @AsOfDate OR "public"."properties"."deleted_at" IS NULL)
AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
AND ("public"."leases"."deleted_at" >= @AsOfDate OR "public"."leases"."deleted_at" IS NULL)
AND ("public"."tenants"."deleted_at" >= @AsOfDate OR "public"."tenants"."deleted_at" IS NULL)

AND ("public"."leases"."end" >= @AsOfDate OR "public"."leases"."end" IS NULL)