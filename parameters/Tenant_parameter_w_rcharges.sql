SELECT 
  	DISTINCT "public"."tenants"."name" AS "TENANT_NAME"
  
    FROM "public"."lease_recurring_charges"
  	INNER JOIN "public"."leases" 
  		ON "lease_recurring_charges"."lease_id" = "public"."leases"."id"
    INNER JOIN "public"."properties"
        ON "leases"."property_id" =  "properties"."id"
  	INNER  JOIN "public"."tenants" 
  		ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
  
    WHERE  ("lease_recurring_charges"."deleted_at" >= @To_Date OR "lease_recurring_charges"."deleted_at" IS NULL)
        AND ("lease_recurring_charges"."terminate_date" >= @To_Date OR "lease_recurring_charges"."terminate_date" IS NULL)
        AND "public"."properties"."name" IN (@Property_Name)
        AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)

