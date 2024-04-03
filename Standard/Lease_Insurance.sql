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
--"public"."company_entities"."name" AS "company_entities_name",
"public"."company_accounts"."company_id",
"public"."units"."name" AS "units_name",
"public"."properties"."name" AS "property_name",
"public"."leases"."primaryTenantId"

FROM "public"."insurances" 
INNER JOIN "public"."leases" ON "public"."insurances"."lease_id"="public"."leases"."id" 
INNER JOIN "public"."leases_units_units" ON "public"."leases"."id"="public"."leases_units_units"."leasesId" 
--LEFT OUTER JOIN "public"."company_entities" ON "public"."leases"."company_relation_id"="public"."company_entities"."company_relation_id" 
INNER JOIN "public"."company_accounts" ON "public"."leases"."company_relation_id"="public"."company_accounts"."id" 
INNER JOIN "public"."units" ON "public"."leases_units_units"."unitsId"="public"."units"."id"
INNER JOIN "public"."properties" ON "public"."leases"."property_id"="public"."properties"."id"
WHERE
"public"."leases"."status" = 'current'
AND 
"public"."company_accounts"."company_id" = @COMPANY_ID
AND 
"public"."properties"."name" IN (@Property_Name)
