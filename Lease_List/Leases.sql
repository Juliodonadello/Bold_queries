SELECT "public"."leases"."id",
	"public"."leases"."name",
	"public"."leases"."status",
	"public"."leases"."start",
	"public"."leases"."end",
	"public"."units"."name" AS "units_name",
	"public"."units"."city",
	"public"."units"."total_square_footage",
	"public"."tenants"."name" AS "tenants_name",
	"public"."properties"."name" AS "properties_name"

FROM "public"."leases"
INNER  JOIN "public"."lease_units" ON "public"."leases"."id"="public"."lease_units"."lease_id"
INNER  JOIN "public"."units" ON "public"."units"."id"="public"."lease_units"."unit_id"
INNER  JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"
INNER  JOIN "public"."company_accounts" ON "public"."properties"."company_relation_id"="public"."company_accounts"."id"

WHERE  CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
	AND  CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)