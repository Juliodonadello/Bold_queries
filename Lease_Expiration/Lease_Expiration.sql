with SQ_FT_TEMP AS
(
	SELECT
		"public"."properties"."id" AS "PROP_ID",
		SUM("public"."units"."total_square_footage") AS "TOT_SQ_FT"
	 
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  
	 WHERE "public"."units"."deleted_at" IS NULL
  	and "public"."properties"."deleted_at" IS NULL
  
	GROUP BY  "public"."properties"."id" 
)

 SELECT "public"."leases"."id",
	"public"."leases"."name",
	"public"."leases"."status",
	"public"."leases"."end",
	"public"."leases_units_units"."leasesId",
	"public"."leases_units_units"."unitsId",
	"public"."units"."id" AS "units_id",
	"public"."units"."name" AS "units_name",
	"public"."units"."city",
	"public"."units"."total_square_footage",
	"public"."tenants"."id" AS "tenants_id",
	"public"."tenants"."name" AS "tenants_name",
	"public"."properties"."id" AS "properties_id",
	"public"."properties"."name" AS "properties_name",
	DATE_PART('year' , "end") AS "EndDate_YEAR",
	SQ_FT_TEMP."TOT_SQ_FT" as "TOT_SQ_FT"

FROM "public"."leases"
INNER  JOIN "public"."leases_units_units" ON "public"."leases"."id"="public"."leases_units_units"."leasesId"
INNER  JOIN "public"."units" ON "public"."units"."id"="public"."leases_units_units"."unitsId"
INNER  JOIN "public"."tenants" ON "public"."tenants"."id"="public"."leases"."primaryTenantId"
INNER  JOIN "public"."properties" ON "public"."units"."property_id"="public"."properties"."id"
INNER JOIN SQ_FT_TEMP ON "public"."properties"."id" = SQ_FT_TEMP."PROP_ID"

WHERE  "public"."leases"."end" IS NOT NULL
    AND CAST("public"."properties"."company_relation_id" AS INT) = CAST(@REAL_COMPANY_ID AS INT)
    --AND "public"."leases"."status" IN (@Lease_Status) --Reatrieving operator error. Fix: Implementing a filter over the table layout using the parameter values
	-- and "public"."leases"."end" between '2024-11-30' and '2024-11-30' -- Date is added as a parameter in the table
	AND "public"."properties"."name" IN (@Property_Name)