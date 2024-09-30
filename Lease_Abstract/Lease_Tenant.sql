SELECT "public"."leases"."id",
"public"."leases"."name",
"public"."leases"."status",
"public"."leases"."start",
"public"."leases"."end",
"public"."leases"."move_in",
"public"."leases"."intended_move_out",
"public"."leases"."actual_move_out",
"public"."tenants"."name" AS "tenants_name",
"public"."tenants"."email" 

FROM "public"."leases" 
INNER JOIN "public"."tenants"
	ON "public"."leases"."primaryTenantId"="public"."tenants"."id"
INNER JOIN "public"."properties"
	ON "public"."leases"."property_id"="public"."properties"."id"
	
WHERE CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
	AND "public"."properties"."name" IN (@Property_Name)
	--AND "public"."leases"."start" <= @AsOfDate 
	AND (
		"public"."leases"."end" >= @AsOfDate
		OR
		"public"."leases"."end" IS NULL
		)
