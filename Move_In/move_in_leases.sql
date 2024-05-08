select  "public"."leases"."id",
"public"."leases"."name" AS "LEASE_NAME",
"public"."leases"."status",
"public"."leases"."move_in",
--"public"."leases"."actual_move_out",
--"public"."leases"."intended_move_out",
--"public"."leases"."reason_for_termination",
"public"."leases"."company_relation_id",
"public"."leases"."property_id",
"public"."tenants"."name"  as "TENANT",
"public"."company_accounts"."company_id",
"public"."properties"."name" as "PROP_NAME",
"public"."units"."name" as "UNIT_NAME"

from "public"."leases"
INNER JOIN "public"."company_accounts"
	ON "public"."leases"."company_relation_id" = "public"."company_accounts"."id"
INNER JOIN "public"."properties"
	ON "public"."leases"."property_id" = "public"."properties"."id"
INNER JOIN "public"."tenants"
		ON "public"."leases"."primaryTenantId" = "public"."tenants"."id"
INNER JOIN "public"."leases_units_units"
		ON "public"."leases"."id" ="public"."leases_units_units"."leasesId"
INNER JOIN "public"."units"
ON "public"."leases_units_units"."unitsId" = "public"."units"."id"

where ("public"."leases"."deleted_at" is null or "public"."leases"."deleted_at"> @ToDate)
	AND "public"."company_accounts"."company_id" IN (@COMPANY_ID)
	--AND "public"."properties"."name" IN (@Property_Name)
	AND "public"."leases"."move_in" < @ToDate
	AND "public"."leases"."move_in" >= @FromDate

ORDER BY "public"."company_accounts"."company_id",
"public"."properties"."name",
"public"."units"."name",
"public"."tenants"."name"
	