SELECT 
"public"."units"."name" AS "unit_name",
"public"."units"."unit_class",
"public"."units"."address1",
"public"."units"."city",
"public"."units"."state",
"public"."units"."zip_code",
"public"."units"."market_rent",
"public"."units"."total_square_footage",
"public"."units"."unit_location_id",
"public"."units"."current_rent",
"public"."leases"."name" AS "lease_name",
"public"."leases"."status" AS "lease_status",
"public"."leases"."start",
"public"."leases"."end",
"public"."leases"."move_in",
"public"."leases"."reason_for_termination",
"public"."leases"."actual_move_out",
"public"."leases"."certificateOfOccupancy",
"public"."leases"."month_to_month",
"public"."tenants"."name" AS "tenant_name",
"public"."tenants"."email"  AS "tenant_email",
"public"."tenants"."phone"  AS "tenant_phone"

FROM "public"."leases" 
INNER JOIN "public"."lease_units" ON "public"."leases"."id"="public"."lease_units"."lease_id" 
INNER JOIN "public"."units" ON "public"."lease_units"."unit_id"="public"."units"."id"
INNER JOIN "public"."properties" ON "public"."properties"."id"="public"."leases"."property_id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"

WHERE "public"."properties"."name"  IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
	AND "public"."units"."deleted_at" IS NULL
	AND "public"."leases"."deleted_at" IS NULL

