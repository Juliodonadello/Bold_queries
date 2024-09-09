WITH LEATE_CHARGES AS (
  SELECT "public"."lease_late_charges"."id",
  "public"."lease_late_charges"."description",
  "public"."lease_late_charges"."minimum_lease_balance",
  "public"."lease_late_charges"."suppress_charge_under",
  "public"."lease_late_charges"."lease_id",
  "public"."lease_late_charges"."process_by"

  FROM "public"."lease_late_charges"
	INNER JOIN "public"."leases"
	  ON "public"."lease_late_charges"."lease_id" = "public"."leases"."id"
	 INNER JOIN "public"."properties"
	  ON "public"."properties"."id" = "public"."leases"."property_id"

  where  CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
	  AND "public"."properties"."name" IN (@Property_Name)
	  AND "public"."lease_late_charges"."created_at" <= @AsOfDate
	  AND
	  (
		"public"."lease_late_charges"."deleted_at" >= @AsOfDate
		OR
		"public"."lease_late_charges"."deleted_at" IS NULL
	  )
),
LEATE_CHARGES_STEPS AS (
  SELECT 
  "public"."lease_late_charge_steps"."id" AS "lease_late_charge_steps_id",
  "public"."lease_late_charge_steps"."late_charge_type",
  "public"."lease_late_charge_steps"."grace_days",
  "public"."lease_late_charge_steps"."frequency" || ': ' || "public"."lease_late_charge_steps"."repeat_factor" as "Frecuency",
  "public"."lease_late_charge_steps"."calculation_type",
  COALESCE("public"."lease_late_charge_steps"."flat_amount","public"."lease_late_charge_steps"."percentage") as "Amount",
  "public"."lease_late_charge_steps"."lease_late_charge_id" 

  FROM "public"."lease_late_charge_steps" 

  WHERE "public"."lease_late_charge_steps"."created_at" <= @AsOfDate
	  AND
	  (
		"public"."lease_late_charge_steps"."deleted_at" >= @AsOfDate
		OR
		"public"."lease_late_charge_steps"."deleted_at" IS NULL
	  )
   ORDER BY "public"."lease_late_charge_steps"."lease_late_charge_id",
	"public"."lease_late_charge_steps"."id", 
	"public"."lease_late_charge_steps"."grace_days"
)
SELECT LEATE_CHARGES."id",
  LEATE_CHARGES."description",
  LEATE_CHARGES."minimum_lease_balance",
  LEATE_CHARGES."suppress_charge_under",
  LEATE_CHARGES."lease_id",
  LEATE_CHARGES."process_by",
  LEATE_CHARGES_STEPS."lease_late_charge_steps_id" as "steps_id",
  LEATE_CHARGES_STEPS."late_charge_type",
  LEATE_CHARGES_STEPS."grace_days",
  LEATE_CHARGES_STEPS."Frecuency",
  LEATE_CHARGES_STEPS."calculation_type",
  LEATE_CHARGES_STEPS."Amount"

FROM LEATE_CHARGES
LEFT JOIN LEATE_CHARGES_STEPS
	ON LEATE_CHARGES."id" = LEATE_CHARGES_STEPS."lease_late_charge_id"

ORDER BY LEATE_CHARGES."lease_id", LEATE_CHARGES."id", LEATE_CHARGES_STEPS."grace_days"

VER FILE TODO.TXT