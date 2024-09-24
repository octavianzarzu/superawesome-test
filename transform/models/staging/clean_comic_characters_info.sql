/*  Assumptions

1.  The `Alignment` column (good, bad, neutral, and 7 NA values) identifies a character as a villain (bad) or hero (good)
2.  There is only one Character that is identified as both villain (bad) and hero (good): 

    SELECT name
    FROM comic_characters_info
    GROUP BY name
    HAVING count(distinct alignment) > 1;

    # Atlas

    However, this Character is labeled differently for different Publishers 

    # Atlas | good | Marvel Comics
    # Atlas | bad  | DC Comics

    The majority of the questions focus specifically on a per publisher answer, so this doesn't represent an issue.

3.  There are duplicate character names. There are also Characters across multiple publishers (3), such as Atlas above. Given that in no question we are interested
    in other attributes from comic_characters_info other than name, alignment, and publisher we can safely 'drop' the remaining features in our analysis and only pick
    one entry per character, publisher, and alignment. 

    SELECT 
        name, 
        alignment, 
        publisher
    FROM comic_characters_info
    QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
    ORDER BY name;

    # 718 rows (734 without filtering)

    Some of the Characters have no publisher information but this doesn't affect our analysis. 

    This subset will act as the base for any further analysis. - clean_comic_characters_info

*/

SELECT 
    name, 
    alignment, 
    publisher
FROM {{ ref('comic_characters_info') }} 
QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
ORDER BY name