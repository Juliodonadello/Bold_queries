WITH OPTIONS AS (
  SELECT "public"."lease_options"."lease_category",
"public"."lease_options"."notification_date",
"public"."lease_options"."expiration_date",
"public"."lease_options"."property_manager_email",
"public"."lease_options"."description",
"public"."lease_options"."leaseId" as "D_lease_id",
"public"."lease_options"."property_id",
"public"."units"."name" as "unit_name",
"public"."lease_options"."note" 

FROM "public"."lease_options"
INNER JOIN "public"."units"
    ON "public"."lease_options"."unit_id" =  "public"."units"."id"
INNER JOIN "public"."properties"
    ON "public"."properties"."id" =  "public"."units"."property_id"
  
  WHERE
	"public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
	--AND "public"."lease_options"."created_at" <= @AsOfDate 
	AND (
	  "public"."lease_options"."deleted_at" >= @AsOfDate
	  OR
	  "public"."lease_options"."deleted_at" IS NULL
	)
)

SELECT OPTIONS.*

FROM OPTIONS 
order by OPTIONS."D_lease_id"
