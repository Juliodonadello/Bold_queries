SELECT "public"."properties"."deleted_at",
"public"."properties"."name",
"public"."properties"."company_relation_id",
"public"."units"."name" AS "units_name",
"public"."units"."total_square_footage",
"public"."units"."current_rent",
"public"."leases"."name" AS "leases_name",
"public"."leases"."start",
"public"."leases"."end",
"public"."leases"."primaryTenantId",
"public"."leases"."certificateOfOccupancy",
"public"."tenants"."name" AS "tenants_name",
"public"."tenants"."phone",
"public"."tenants"."email"

FROM "public"."properties" 
INNER JOIN "public"."units" 
ON "public"."properties"."id"="public"."units"."property_id" 
LEFT OUTER JOIN "public"."leases_units_units" ON "public"."units"."id"="public"."leases_units_units"."unitsId" 
LEFT OUTER JOIN "public"."leases" ON "public"."leases_units_units"."leasesId"="public"."leases"."id" 
LEFT OUTER JOIN "public"."tenants" ON "public"."leases"."primaryTenantId"="public"."tenants"."id" 

WHERE  CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
AND CAST("public"."properties"."name" AS TEXT) IN (@Property_Name)
AND  CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
AND ("public"."properties"."deleted_at" >= @AsOfDate OR "public"."properties"."deleted_at" IS NULL)
AND ("public"."units"."deleted_at" >= @AsOfDate OR "public"."units"."deleted_at" IS NULL)
AND ("public"."leases"."deleted_at" >= @AsOfDate OR "public"."leases"."deleted_at" IS NULL)
AND ("public"."tenants"."deleted_at" >= @AsOfDate OR "public"."tenants"."deleted_at" IS NULL)




