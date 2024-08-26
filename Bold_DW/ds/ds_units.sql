WITH UNITS AS (
  SELECT 
		"public"."properties"."id" AS "prop_id",
		"public"."properties"."name" AS "prop_name",
		"public"."units"."id" AS "unit_id",
  		"public"."units"."name" AS "unit_name",
		"public"."units"."unit_class",
		"public"."units"."address1",
		"public"."units"."city",
		"public"."units"."state",
		"public"."units"."zip_code",
		--"public"."units"."building",
		--"public"."units"."wing",
		--"public"."units"."floor",
		"public"."units"."market_rent",
		--"public"."units"."rooms",
		--"public"."units"."bedrooms",
		--"public"."units"."bathrooms",
		--"public"."units"."actual_move_in_date",
		"public"."units"."total_square_footage",
		--"public"."units"."available",
		--"public"."units"."property_id",
		"public"."units"."country",
		"public"."units"."unit_location_id",
		"public"."units"."current_rent"
  		
	FROM   "public"."units"
	INNER JOIN "public"."properties"
		ON "public"."units"."property_id" = "public"."properties"."id"
	
  	WHERE "public"."properties"."deleted_at" IS NULL
		AND CAST("public"."properties"."company_relation_id" AS INT)  = CAST(@REAL_COMPANY_ID AS INT)
		AND ("public"."units"."deleted_at" IS NULL)
	
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14--,15,16,17,18,19,20,21,22,23
	)
select * from UNITS