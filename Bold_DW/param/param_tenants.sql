SELECT 
  	DISTINCT "public"."tenants"."name" AS "TENANT_NAME"
  
    FROM "public"."tenants" 
  
    WHERE CAST("public"."tenants"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  		AND  "tenants"."deleted_at" IS NULL
