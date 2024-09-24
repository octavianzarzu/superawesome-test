/* 

** dc-data table **

1. The name represents a concatenation of Character (Universe/Comic name). We can extract only the first part (before '(') using split_part, however there might be cases where the name of the character contains '(' also. Let's look at those: 

    SELECT split_part(name, '(', 1) as character_name 
    FROM "dc-data"
    GROUP BY ALL 
    HAVING count(*) > 1;

    # 17 rows returned, of which: 
    
    12 have the same alive status (deceased or alive in both comics they appear in) and 
    5 have a different status (deceased in one comic, alive in another comic).

    The only noticeable entry is of Krypto

    SELECT split_part(name, '(', 1) as character_name, name, alive, appearances 
    FROM "dc-data"
    WHERE name like 'Krypto %';

    # Krypto 	            Krypto (New Earth)	                Living Characters	109
    # Krypto the Earth Dog 	Krypto the Earth Dog (New Earth)	Living Characters	24
    # Krypto 	            Krypto (Clone) (New Earth)      	Deceased Characters	1

    Even if it's a clone/duplicate entry, the status is different and the additional appearance will be counted towards the total. 

    SELECT split_part(name, '(', 1) as character_name, 
       sum(appearances) 
    FROM "marvel-data"
    GROUP BY character_name

** marvel-data table ** 

1. The same analysis can be done as in the case of the dc-data table above. 

2. Character names are lowercase, whereas in dc-data and comic_characters_info are capitalized. 

*/

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