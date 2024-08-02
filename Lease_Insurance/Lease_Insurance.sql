SELECT "public"."insurances"."id",
"public"."insurances"."insurance_type",
"public"."insurances"."company",
"public"."insurances"."policy_number",
"public"."insurances"."email_to",
"public"."insurances"."effective_date",
"public"."insurances"."expiration_date",
"public"."insurances"."insurance_value",
"public"."insurances"."lease_id",
"public"."insurances"."property_id",
"public"."insurances"."notification_date",
"public"."insurances"."email_cc",
"public"."leases"."name",
"public"."leases"."status",
"public"."leases_units_units"."leasesId",
"public"."leases_units_units"."unitsId",
"public"."units"."name" AS "units_name",
"public"."properties"."name" AS "property_name",
"public"."tenants"."name" as "primary_tenant_name"

FROM "public"."insurances" 
INNER JOIN "public"."leases" ON "public"."insurances"."lease_id"="public"."leases"."id" 
INNER JOIN "public"."leases_units_units" ON "public"."leases"."id"="public"."leases_units_units"."leasesId"
INNER JOIN "public"."units" ON "public"."leases_units_units"."unitsId"="public"."units"."id"
INNER JOIN "public"."properties" ON "public"."leases"."property_id"="public"."properties"."id"
INNER JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"

WHERE
CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
AND "public"."insurances"."expiration_date" >= @FromDate
AND "public"."insurances"."expiration_date" <= @To_Date
AND CAST("public"."leases"."status" AS TEXT) IN (@Lease_Status)
AND "public"."properties"."name" IN (@Property_Name)
AND CAST("public"."insurances"."insurance_type" AS TEXT) IN (@Insurance_Type)
