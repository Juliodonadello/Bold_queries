select "public"."leases"."name"

FROM "public"."sales_entry"
INNER JOIN "public"."leases" 
    ON "public"."leases"."id"="public"."sales_entry"."lease_id"
	
WHERE "public"."sales_entry"."company_relation_id"  = @REAL_COMPANY_ID
