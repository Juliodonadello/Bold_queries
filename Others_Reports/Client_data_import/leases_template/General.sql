SELECT 
"public"."leases"."name",
"public"."properties"."property_location_id",
--"public"."leases"."primaryTenantId",
"public"."tenants"."tenant_id",
TO_CHAR("public"."leases"."start", 'MM/DD/YYYY') AS "start",
TO_CHAR("public"."leases"."end", 'MM/DD/YYYY') AS "end",
TO_CHAR("public"."leases"."move_in", 'MM/DD/YYYY') AS "move_in"
--"public"."leases"."start",
--"public"."leases"."end",
--"public"."leases"."move_in"

FROM "public"."leases" 
INNER JOIN "public"."properties" 
	ON "public"."properties"."id"="public"."leases"."property_id"
INNER JOIN "public"."leases_tenants_tenants"
	ON "public"."leases"."id" = "public"."leases_tenants_tenants"."leasesId"
INNER JOIN "public"."tenants"
	ON "public"."tenants"."id" = "public"."leases_tenants_tenants"."tenantsId"
	
WHERE "public"."properties"."name" IN (@Property_Name)
AND "public"."properties"."deleted_at" IS NULL
AND "public"."leases"."deleted_at" IS NULL
AND "public"."tenants"."deleted_at" IS NULL
	
GROUP BY 1,2,3,4,5,6