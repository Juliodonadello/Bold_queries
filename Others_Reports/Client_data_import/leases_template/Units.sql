SELECT 
"public"."units"."unit_location_id",
"public"."leases"."name"

FROM "public"."units"
INNER JOIN "public"."lease_units"
	ON "public"."units"."id" = "public"."lease_units"."unit_id"
INNER JOIN "public"."leases"
	ON "public"."leases"."id" = "public"."lease_units"."lease_id"
INNER JOIN "public"."properties"
	ON "public"."leases"."property_id" = "public"."properties"."id"

WHERE "public"."properties"."name" IN (@Property_Name)
AND "public"."units"."deleted_at" IS NULL
AND "public"."leases"."deleted_at" IS NULL

group by 1,2