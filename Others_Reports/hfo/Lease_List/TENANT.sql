SELECT 
	"public"."properties"."name" AS "properties_name",
	"public"."tenants"."name" AS "tenants_name",
	"public"."tenants"."phone" AS "tenants_phone",
	"public"."tenants"."mobile" AS "tenants_mobile",
	"public"."tenants"."email" AS "tenants_email",
	"public"."tenants"."business_as" AS "tenants_business_as",
	"public"."leases"."id",
	"public"."leases"."name",
	"public"."units"."name",
	"public"."leases"."status"


FROM "public"."tenants" 
LEFT JOIN "public"."leases" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
LEFT  JOIN "public"."lease_units" ON "public"."leases"."id"="public"."lease_units"."lease_id"
LEFT  JOIN "public"."units" ON "public"."units"."id"="public"."lease_units"."unit_id"
--INNER  JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
INNER  JOIN "public"."properties" ON "public"."leases"."property_id"="public"."properties"."id"

WHERE  CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    AND "public"."properties"."name" IN (@Property_Name)
	AND  CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)