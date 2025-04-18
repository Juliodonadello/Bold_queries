SELECT distinct "public"."leases"."name" as "LEASE_NAME"
  
	FROM "public"."properties"
  		ON "public"."properties"."id" =  "public"."units"."property_id"
  	INNER JOIN "public"."leases"
  		ON "public"."leases"."id"  = "public"."lease_recurring_charges"."lease_id" 
  
  	WHERE "public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
  	AND  CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
	AND (
		"public"."leases"."deleted_at" >= @AsOfDate
		OR
		"public"."leases"."deleted_at" IS NULL
		)
	AND (
		"public"."leases"."end" >= @AsOfDate
		OR
		"public"."leases"."end" IS NULL
		)

order by 1 desc