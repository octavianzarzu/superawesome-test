WITH 
clean_dc_data AS 
(
    SELECT 
        split_part(name, ' (', 1) as character_name, 
        sum(appearances) as appearances
    FROM {{ ref('dc-data') }} 
    GROUP BY character_name
),
clean_marvel_data AS 
(
    SELECT 
        split_part(name, ' (', 1) as character_name, 
        sum(appearances) as appearances
    FROM {{ ref('marvel-data') }} 
    GROUP BY character_name
)
SELECT 'DC Comics' as publisher, character_name, appearances
FROM clean_dc_data
UNION 
SELECT 'Marvel Comics' as publisher, character_name, appearances
FROM clean_marvel_data