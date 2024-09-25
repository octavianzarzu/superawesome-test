/* 
 
**dc-data table**

    1. The name represents a concatenation of the character name and the universe/comic name (in parentheses). We can extract only the first part (before the parentheses) using `split_part`, but there may be cases where the character name contains parentheses as well. Let’s look at those cases:

    ```sql
    SELECT split_part(name, '(', 1) as character_name 
    FROM "dc-data"
    GROUP BY ALL 
    HAVING count(*) > 1;
    ```

    **17 rows returned, of which:**
    
    - 12 have the same alive status (either deceased or alive in both comics they appear in)
    - 5 have a different status (deceased in one comic, alive in another)

    The only noticeable entry is `Krypto`

    ```sql
    SELECT split_part(name, '(', 1) as character_name, name, alive, appearances 
    FROM "dc-data"
    WHERE name like 'Krypto %';
    ```

    | character_name       | name                             | alive              | appearances |
    |----------------------|----------------------------------|--------------------|-------------|
    | Krypto 	           | Krypto (New Earth)	              | Living Characters  | 109         |
    | Krypto the Earth Dog | Krypto the Earth Dog (New Earth) | Living Characters  | 24          |
    | Krypto 	           | Krypto (Clone) (New Earth)       |	Deceased Characters| 1           |

    Even though it’s a clone/duplicate entry, the status is different, so the additional appearance will count toward the total.

    ```sql
    SELECT split_part(name, '(', 1) as character_name, 
       sum(appearances) 
    FROM "marvel-data"
    GROUP BY character_name
    ```

**marvel-data table** 

    1. The same analysis can be done as for the `dc-data` file.

    2. Character names are lowercase in `marvel-data`, while in `dc-data` and `comic_characters_info` they are capitalized.


    ```sql union_dc_marvel_data
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
    ```

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