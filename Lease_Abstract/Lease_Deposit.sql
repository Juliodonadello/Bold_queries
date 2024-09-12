WITH DEPOSITS AS (
  SELECT "public"."lease_deposits"."type" as "D_type",
  CASE WHEN "public"."lease_deposits"."refundable" IS TRUE THEN 'YES' ELSE 'NO' END as "D_refundable",
  "public"."lease_deposits"."interest_rate" as "D_interest_rate",
  "public"."lease_deposits"."interest_basis" as "D_interest_basis",
  "public"."lease_deposits"."liability_account" as "D_liability_account",
  --"public"."lease_deposits"."refunds" as "D_refunds",
  "public"."units"."name" as "D_unit_name",
  "public"."lease_deposits"."lease_id" as "D_lease_id"

  FROM "public"."lease_deposits"
  INNER JOIN "public"."units"
  		ON "public"."lease_deposits"."unit_id" =  "public"."units"."id"
 	INNER JOIN "public"."properties"
  		ON "public"."properties"."id" =  "public"."units"."property_id"
  
  WHERE
	"public"."properties"."name" IN (@Property_Name)
	AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
	AND "public"."lease_deposits"."created_at" <= @AsOfDate 
	AND (
	  "public"."lease_deposits"."deleted_at" >= @AsOfDate
	  OR
	  "public"."lease_deposits"."deleted_at" IS NULL
	)
)

SELECT DEPOSITS.*
FROM DEPOSITS
order by DEPOSITS."D_lease_id"
