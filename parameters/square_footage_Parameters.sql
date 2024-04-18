WITH UNITS AS 
(
  SELECT 
		"public"."properties"."id" AS "PROP_ID",
		"public"."properties"."name" AS "PROP_NAME",
		"public"."units"."id" AS "UNIT_ID",
  		"public"."units"."name" AS "UNIT_NAME",
  		"public"."unit_square_footage_items"."square_footage_type" AS "SQ_FT_TYPE",
  		"public"."units"."unit_class" AS "UNIT_CLASS"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
  	LEFT JOIN "public"."unit_square_footage_items"
		ON "public"."unit_square_footage_items"."unit_id" = "public"."units"."id"
	
  	WHERE "public"."units"."deleted_at" IS NULL
  	and "public"."properties"."deleted_at" IS NULL
  
	GROUP BY 
		"public"."properties"."id",
		"public"."properties"."name",
		"public"."units"."id",
  		"public"."units"."name",
  		"public"."unit_square_footage_items"."square_footage_type" 
)
select UNITS."SQ_FT_TYPE",
	UNITS."UNIT_CLASS"
	
from UNITS

where  UNITS."PROP_NAME" IN (@Property_Name)

GROUP BY UNITS."SQ_FT_TYPE",
	UNITS."UNIT_CLASS"
