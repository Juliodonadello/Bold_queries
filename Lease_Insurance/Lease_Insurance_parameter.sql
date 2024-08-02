SELECT 
"public"."insurances"."insurance_type"

FROM "public"."insurances" 
INNER JOIN "public"."leases" ON "public"."insurances"."lease_id"="public"."leases"."id" 
INNER JOIN "public"."leases_units_units" ON "public"."leases"."id"="public"."leases_units_units"."leasesId" 
INNER JOIN "public"."units" ON "public"."leases_units_units"."unitsId"="public"."units"."id"
INNER JOIN "public"."properties" ON "public"."leases"."property_id"="public"."properties"."id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"

WHERE
CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
-- AND "public"."leases"."status" = 'current' AND "public"."tenants"."deleted_at" IS NULL  -- no agrego este filtro porque no manejamos AsOfDate
AND "public"."insurances"."expiration_date" >= @FromDate
AND "public"."insurances"."expiration_date" <= @To_Date
AND CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
AND "public"."properties"."name" IN (@Property_Name)

group by "public"."insurances"."insurance_type"

order by "public"."insurances"."insurance_type" asc
