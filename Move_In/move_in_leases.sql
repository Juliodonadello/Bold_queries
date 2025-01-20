with LEASES_TOT AS (
  SELECT "public"."leases"."id" AS "LEASE_ID",
		  "public"."lease_units"."unit_id" AS "UNIT_ID",
		  "public"."leases"."start" AS "lease_start",
		  "public"."leases"."end" AS "lease_end",
		  "public"."leases"."name" AS "LEASE_NAME",
		  "public"."tenants"."name"  as "TENANT",
		  "public"."properties"."name" AS "PROP_NAME",
		  "public"."properties"."company_relation_id" AS "COMP_ID"

	FROM "public"."leases"
  INNER JOIN "public"."lease_units"
	  ON "public"."leases"."id" ="public"."lease_units"."lease_id"
  INNER JOIN "public"."tenants"
	  ON "public"."leases"."primaryTenantId" = "public"."tenants"."id" 
  INNER JOIN "public"."properties"
	  ON "public"."leases"."property_id" = "public"."properties"."id"

	  WHERE "public"."leases"."start" <= @FromDate
		  AND ("public"."leases"."end" > @FromDate OR "public"."leases"."end" IS NULL)
		  AND
		  ("public"."leases"."deleted_at" is null or "public"."leases"."deleted_at"> @ToDate)
		  AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)

  ORDER BY "public"."lease_units"."unit_id" 
),
LEASE_MAX_END AS (
  SELECT "UNIT_ID", 
  MAX("lease_end") "END",
  SUM(CASE WHEN "lease_end" IS NULL THEN 1 ELSE 0 END) AS "END_NULL"
  FROM LEASES_TOT
  GROUP BY "UNIT_ID"
),
LEASES AS (
	SELECT LEASES_TOT.*, 
		LEASE_MAX_END."END" AS "END",
		LEASE_MAX_END."END_NULL" AS "END_NULL"
	FROM LEASES_TOT
	INNER JOIN LEASE_MAX_END
		ON LEASES_TOT."UNIT_ID" = LEASE_MAX_END."UNIT_ID"
		AND LEASES_TOT."lease_end" = LEASE_MAX_END."END"
),
FINAL AS (
	select LEASES."UNIT_ID",
	  "END", --fecha de cuando se vacia la unidad
	  "END_NULL", -- flag si la unidad no se vacia nunca (lease_end = null)
	  CASE 
		WHEN "END_NULL" >= 1 THEN 'OCCUPIED'
		WHEN "END" > @FromDate THEN 'OCCUPIED'
	  	ELSE 'VACANT'
	  END AS "UNIT_STATUS"
	FROM LEASES
 )

 select  "public"."leases"."id",
"public"."leases"."name" AS "LEASE_NAME",
"public"."leases"."status" AS "LEASE_STATUS",
FINAL."END" AS "PREVIOUS_LEASE_END",
"public"."leases"."move_in",
--"public"."leases"."actual_move_out",
--"public"."leases"."intended_move_out",
--"public"."leases"."reason_for_termination",
"public"."leases"."company_relation_id",
"public"."leases"."property_id",
"public"."tenants"."name"  as "TENANT",
"public"."properties"."name" as "PROP_NAME",
"public"."units"."name" as "UNIT_NAME",
CASE WHEN FINAL."UNIT_STATUS" IS NULL THEN 'VACANT' ELSE FINAL."UNIT_STATUS" END AS "UNIT_STATUS",
CASE
	WHEN FINAL."END_NULL" >= 1 THEN '0' -- EL FLAG END_NULL INDICA UNIDAD OCUPADA
	WHEN FINAL."END_NULL"  is null AND FINAL."END_NULL" IS NULL THEN CAST(ROUND(("public"."leases"."move_in" - CAST(@FromDate AS DATE))/ 30.44,0) AS TEXT) -- VACIA POR EL JOIN A NIVEL UNIT, UNIDAD VACANTE. SIN LEASE PREVIO
	WHEN "public"."leases"."move_in" > FINAL."END" THEN CAST(ROUND(("public"."leases"."move_in" - FINAL."END")/ 30.44,0) AS TEXT) -- CASO DE INTERES, MESES CON LA UNIDAD VACIA
	WHEN "public"."leases"."move_in" < FINAL."END" THEN  '0' -- NO SE VACIA NUNCA, EL MOVE ES ANTERIOR AL PREVIOUS_LEASE_END
	ELSE ''
	END AS "Vacancy",
CASE
	WHEN FINAL."END_NULL" >= 1 THEN '0' -- EL FLAG END_NULL INDICA UNIDAD OCUPADA
	WHEN FINAL."END_NULL"  is null AND FINAL."END_NULL" IS NULL THEN CAST(ROUND(("public"."leases"."move_in" - CAST(@FromDate AS DATE))/ 30.44/12,2) AS TEXT) -- VACIA POR EL JOIN A NIVEL UNIT, UNIDAD VACANTE. SIN LEASE PREVIO
	WHEN "public"."leases"."move_in" > FINAL."END" THEN CAST(ROUND(("public"."leases"."move_in" - FINAL."END")/ 30.44/12,2) AS TEXT) -- CASO DE INTERES, MESES CON LA UNIDAD VACIA
	WHEN "public"."leases"."move_in" <= FINAL."END" THEN  '0' -- NO SE VACIA NUNCA, EL MOVE ES ANTERIOR AL PREVIOUS_LEASE_END
	ELSE ''
	END AS "Vacancy_years"
	
FROM "public"."leases"
INNER JOIN "public"."properties"
	ON "public"."leases"."property_id" = "public"."properties"."id"
INNER JOIN "public"."tenants"
		ON "public"."leases"."primaryTenantId" = "public"."tenants"."id"
INNER JOIN "public"."lease_units"
		ON "public"."leases"."id" ="public"."lease_units"."lease_id"
INNER JOIN "public"."units"
ON "public"."lease_units"."unit_id" = "public"."units"."id"
LEFT JOIN FINAL
	ON FINAL."UNIT_ID" = "public"."units"."id"

where ("public"."leases"."deleted_at" is null or "public"."leases"."deleted_at"> @ToDate)
	AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
	AND "public"."properties"."name" IN (@Property_Name)
	AND "public"."leases"."move_in" < @ToDate
	AND "public"."leases"."move_in" >= @FromDate

ORDER BY "public"."properties"."company_relation_id",
"public"."properties"."name",
"public"."units"."name",
"public"."tenants"."name"