with CHARGES_TOT AS (
    SELECT 
        "lease_recurring_charges"."lease_id" AS "LEASE_ID",
        "lease_recurring_charge_amounts"."effective_date" AS "EFFECTIVE_DATE",
        "lease_recurring_charge_amounts"."amount" AS "AMOUNT",
        "lease_recurring_charges"."order_entry_item_id" AS "ITEM_ID",
  		"public"."properties"."name" AS "PROP_NAME",
  		"public"."leases"."name" AS "LEASE_NAME",
  		"public"."tenants"."name" AS "TENANT_NAME"
  
    FROM "public"."lease_recurring_charges"
    INNER JOIN "public"."lease_recurring_charge_amounts"
        ON "lease_recurring_charges"."id" = "lease_recurring_charge_amounts"."recurring_charge_id"
  	INNER JOIN "public"."leases" 
  		ON "lease_recurring_charges"."lease_id" = "public"."leases"."id"
    INNER JOIN "public"."properties"
        ON "leases"."property_id" =  "properties"."id"
  	INNER  JOIN "public"."tenants" 
  		ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
  
    WHERE "lease_recurring_charge_amounts"."effective_date" <= @To_Date
  		AND "lease_recurring_charge_amounts"."effective_date" >= @From_Date
        AND ("lease_recurring_charge_amounts"."deleted_at" >= @To_Date OR "lease_recurring_charge_amounts"."deleted_at" IS NULL)
        AND ("lease_recurring_charges"."deleted_at" >= @To_Date OR "lease_recurring_charges"."deleted_at" IS NULL)
        AND ("lease_recurring_charges"."terminate_date" >= @To_Date OR "lease_recurring_charges"."terminate_date" IS NULL)
        AND "lease_recurring_charges"."order_entry_item_id" in (@Item_Id)
        AND "public"."properties"."name" IN (@Property_Name)
        AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  		AND ("lease_recurring_charge_amounts"."effective_date" <= "public"."leases"."end"
			 	OR "public"."leases"."end" is NULL)
)
SELECT * FROM CHARGES_TOT