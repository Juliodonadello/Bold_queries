select  "public"."leases"."id",
"public"."leases"."name" AS "LEASE_NAME",
"public"."leases"."status" AS "LEASE_STATUS",
"public"."leases"."actual_move_out" as "ACTUAL_MOVE_OUT",
"public"."leases"."intended_move_out" as "INTENDED_MOVE_OUT",
"public"."leases"."reason_for_termination" as "REASON_FOR_TERMINATION",
"public"."leases"."company_relation_id",
"public"."leases"."property_id",
"public"."tenants"."name"  as "TENANT",
"public"."properties"."name" as "PROP_NAME",
"public"."units"."name" as "UNIT_NAME"
	
FROM "public"."leases"
INNER JOIN "public"."properties"
	ON "public"."leases"."property_id" = "public"."properties"."id"
INNER JOIN "public"."tenants"
		ON "public"."leases"."primaryTenantId" = "public"."tenants"."id"
INNER JOIN "public"."leases_units_units"
		ON "public"."leases"."id" ="public"."leases_units_units"."leasesId"
INNER JOIN "public"."units"
ON "public"."leases_units_units"."unitsId" = "public"."units"."id"

where ("public"."leases"."deleted_at" is null or "public"."leases"."deleted_at"> @ToDate)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
	AND "public"."properties"."name" IN (@Property_Name)
	AND "public"."leases"."move_in" < @ToDate
	AND "public"."leases"."move_in" >= @FromDate

ORDER BY "public"."properties"."company_relation_id",
"public"."properties"."name",
"public"."units"."name",
"public"."tenants"."name"
	
