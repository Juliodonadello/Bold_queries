SELECT 
    TO_CHAR(CAST("public"."lease_recovery_control"."recovery_from" AS DATE), 'YYYY-MM-DD') AS "recovery_from",
    TO_CHAR(CAST("public"."lease_recovery_control"."recovery_to" AS DATE), 'YYYY-MM-DD') AS "recovery_to"
FROM "public"."lease_recovery_control"
GROUP BY 1, 2
ORDER BY 1, 2
