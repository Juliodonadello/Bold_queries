WITH CHARGE_CONTROL AS (
  	SELECT 
  			"public"."properties"."id" AS "PROP_ID",
  			"public"."property_charge_controls"."item_id" as "ITEM_ID",
  			CASE WHEN "public"."property_charge_controls"."base_rent" then 1 else 0 end as "BASE_RENT"
  		
  	FROM "public"."properties"
  	INNER JOIN "public"."property_charge_controls"
  		ON "public"."property_charge_controls"."property_id" = "public"."properties"."id"
  	
  	WHERE "public"."properties"."name" IN (@Property_Name)
	AND "public"."properties"."company_relation_id" = @REAL_COMPANY_ID
	),
RENT_CHARGES AS (
  SELECT
"public"."units"."property_id" "PROP_ID",
"public"."lease_recurring_charges"."lease_id" "LEASE_ID",
"public"."lease_recurring_charges"."unit_id" "UNIT_ID",
CHARGE_CONTROL."ITEM_ID",
DATE_PART('year' , "public"."lease_recurring_charge_amounts"."effective_date") AS "YEAR",
DATE_PART('month' , "public"."lease_recurring_charge_amounts"."effective_date") AS "MONTH",
TO_CHAR("public"."lease_recurring_charge_amounts"."effective_date", 'Month') AS "MONTH_NAME",
"public"."lease_recurring_charge_amounts"."frequency",
MAX("public"."lease_recurring_charge_amounts"."amount") AS "RENT_CHARGE"

FROM "public"."lease_recurring_charges"
INNER JOIN "public"."lease_recurring_charge_amounts"
	ON "public"."lease_recurring_charges"."id" = "public"."lease_recurring_charge_amounts"."recurring_charge_id"
INNER JOIN "public"."units"
	ON "public"."lease_recurring_charges"."unit_id" =  "public"."units"."id"
INNER JOIN "public"."properties"
	ON "public"."properties"."id" =  "public"."units"."property_id"
INNER JOIN CHARGE_CONTROL
	ON CHARGE_CONTROL. "PROP_ID" = "public"."units"."property_id"
	AND CHARGE_CONTROL. "ITEM_ID" = "public"."lease_recurring_charges"."order_entry_item_id"
  
WHERE CHARGE_CONTROL."BASE_RENT" = 1
	AND "public"."properties"."name" IN (@Property_Name)
	AND "public"."properties"."company_relation_id" = @REAL_COMPANY_ID
  
GROUP BY 1,2,3,4,5,6,7,8
),
SALES AS (
  SELECT
"public"."sales_entry"."id",
DATE_PART('year' , "public"."sales_entry"."transaction_date") AS "YEAR",
DATE_PART('month' , "public"."sales_entry"."transaction_date") AS "MONTH",
TO_CHAR("public"."sales_entry"."transaction_date", 'Month') AS "MONTH_NAME",
"public"."sales_entry"."transaction_date",
"public"."sales_entry"."transaction_type",
 CASE WHEN "public"."sales_entry"."transaction_type" LIKE '%Month%' THEN 'Monthly'
  			WHEN "public"."sales_entry"."transaction_type" LIKE '%Year%' THEN 'Annual'
			ELSE '-'
			END AS "transaction_type_group",
"public"."sales_entry"."sales_type",
--"public"."sales_entry"."sales_date",
"public"."sales_entry"."sales_category",
--"public"."sales_entry"."report_date",
"public"."sales_entry"."sales_volume",
"public"."sales_entry"."unit_id",
"public"."units"."name" "UNIT_NAME",
"public"."sales_entry"."lease_id",
"public"."leases"."name" "LEASE_NAME",
"public"."sales_entry"."tenant_id",
"public"."tenants"."name" "TENANT_NAME",
"public"."properties"."name" "PROP_NAME",
"public"."properties"."id" "PROP_ID",
"public"."sales_entry"."company_relation_id" 

FROM "public"."sales_entry"
INNER JOIN "public"."units" 
    ON "public"."units"."id"="public"."sales_entry"."unit_id"
    AND "public"."units"."company_relation_id"="public"."sales_entry"."company_relation_id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id"="public"."sales_entry"."tenant_id"
INNER JOIN "public"."properties" 
    ON "public"."properties"."id"="public"."units"."property_id"
    AND "public"."properties"."company_relation_id"="public"."units"."company_relation_id"
INNER JOIN "public"."leases" ON "public"."leases"."id"="public"."sales_entry"."lease_id"
	
WHERE --CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  --AND 
  "public"."sales_entry"."transaction_date" >= CURRENT_DATE - INTERVAL '5 years'
  AND "public"."sales_entry"."transaction_date" <= CURRENT_DATE
  AND "public"."leases"."name" IN (@Lease_Name)
)
select SALES."transaction_type",
SALES."transaction_type_group"

from SALES

group by 1,2