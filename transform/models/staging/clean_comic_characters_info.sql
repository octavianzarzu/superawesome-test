/*  Assumptions

    1.  The `Alignment` column (good, bad, neutral, and 7 NA values) identifies a character as either a villain (bad) or a hero (good).
    2.  There is only one character that is identified as both a villain (bad) and a hero (good):
    
    ```sql
    SELECT name
    FROM comic_characters_info
    GROUP BY name
    HAVING count(distinct alignment) > 1;
    ```
    
    | Name  |
    |-------|
    | Atlas |
    
    However, this character is labeled differently by different publishers:
    
    | Name  | Alignment | Publisher         |
    |-------|-----------|-------------------|
    | Atlas | good      | Marvel Comics     |
    | Atlas | bad       | DC Comics         |
    
    Most questions focus on publisher-specific answers, so this doesn’t pose an issue.

3   .  There are duplicate character names, and some characters appear across multiple publishers (e.g., `Atlas` above). Since no question requires attributes from `comic_characters_info` beyond name, alignment, and publisher, we can safely ‘drop’ the remaining features and select only one entry per character, publisher, and alignment.

    ```sql
    SELECT 
        name, 
        alignment, 
        publisher
    FROM comic_characters_info
    QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
    ORDER BY name;
    ```

    **718 rows (734 without filtering)**

    Some characters lack publisher information, but this does not affect our analysis.
    
    This subset will act as the base for further analysis.


    ```sql clean_comic_characters_info
    SELECT 
        name, 
        alignment, 
        publisher
    FROM {{ ref('comic_characters_info') }} 
    QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
    ORDER BY name
    ```

*/

SELECT 
    name, 
    alignment, 
    publisher
FROM {{ ref('comic_characters_info') }} 
QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
ORDER BY name