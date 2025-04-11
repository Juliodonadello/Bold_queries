with utilities as (
	SELECT "public"."unit_utilities"."unit_id" "UNIT_ID",
	MAX(CASE WHEN "public"."unit_utilities"."name" = 'Electric Rate:' THEN "public"."unit_utilities"."description" ELSE NULL END) AS "Electric Rate",
	MAX(CASE WHEN "public"."unit_utilities"."name" = 'Electric Meter #:' THEN "public"."unit_utilities"."description" ELSE NULL END) AS "Electric Meter",
  MAX(CASE WHEN "public"."unit_utilities"."name" = 'Frequency:' THEN "public"."unit_utilities"."description" ELSE NULL END) AS "Frequency",
	MAX(CASE WHEN "public"."unit_utilities"."name" = 'Water Meter #:' THEN "public"."unit_utilities"."description" ELSE NULL END) AS "Water Meter"

	FROM "public"."unit_utilities"

	where ("public"."unit_utilities"."name" = 'Electric Rate:'
		   or  "public"."unit_utilities"."name" = 'Electric Meter #:'
		   or  "public"."unit_utilities"."name" = 'Water Meter #:' )
	and ("public"."unit_utilities"."deleted_at" IS NULL or "public"."unit_utilities"."deleted_at"<= @AsOfDate)
  
  group by 1
  )
  
  select "public"."leases"."name" "Lease_name",
  "public"."tenants"."name" "tenant_name",
  "public"."units"."name" "unit_name",
  "public"."properties"."name" "property_name",
  utilities."Electric Rate",
  utilities."Electric Meter",
  utilities."Frequency",
  utilities."Water Meter"
  
FROM "public"."leases"
INNER  JOIN "public"."lease_units" ON "public"."leases"."id"="public"."lease_units"."lease_id"
INNER  JOIN "public"."units" ON "public"."units"."id"="public"."lease_units"."unit_id"
INNER  JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"
INNER JOIN utilities ON utilities."UNIT_ID" = "public"."units"."id"
  
  
  
  