SELECT "public"."tenants"."tenant_id",
"public"."leases"."name"

FROM "public"."tenants"
INNER JOIN "public"."leases_tenants_tenants"
	ON "public"."tenants"."id" = "public"."leases_tenants_tenants"."tenantsId"
INNER JOIN "public"."leases"
	ON "public"."leases"."id" = "public"."leases_tenants_tenants"."leasesId"
INNER JOIN "public"."properties"
	ON "public"."leases"."property_id" = "public"."properties"."id"

WHERE "public"."properties"."name" IN (@Property_Name)
AND "public"."tenants"."deleted_at" IS NULL
AND "public"."leases"."deleted_at" IS NULL

group by 1,2