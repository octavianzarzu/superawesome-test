/* 


1. Let’s start with the result from Questions 1 and 2 and remove the `alignment = 'good'` condition to retrieve both villains and heroes.

    ```sql
    WITH top_10_villains_and_heroes AS 
    (
        SELECT 
            ccci.name,
            ccci.publisher,
            dmd.appearances
        FROM {{ ref('clean_comic_characters_info') }} ccci
            INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
        QUALIFY ROW_NUMBER() OVER (partition by '' order by dmd.appearances desc) <= 10
        ORDER BY appearances desc
    ),
    ```

2. Now, let’s join the `hero-abilities` table to get the `overall_score`. As we can see, there are duplicate entries for character names since a character may appear in multiple comics. We will calculate the average `overall_score` for each character. 

> But, we encounter an error! Strings `∞` and `-` are part of the data. Let's use a CASE statement to replace these values: ∞ as 10000 (max value in the dataset is less than 1000) and - as 0. 

    ```sql
    SELECT 
        split_part(name, ' (', 1) as name, 
        AVG(CASE WHEN overall_score = '∞' THEN 10000 WHEN overall_score = '-' THEN 0 ELSE overall_score::INTEGER END) as overall_score
    FROM "hero-abilities"
    GROUP BY ALL;
    ``` 

3. Let's join the two datasets and order by the `overall_score`:

    ```sql
    WITH top_10_villains_and_heroes AS 
    (
        SELECT 
            ccci.name,
            ccci.publisher,
            dmd.appearances
        FROM {{ ref('clean_comic_characters_info') }} ccci
            INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
        QUALIFY ROW_NUMBER() OVER (partition by '' order by dmd.appearances desc) <= 10
        ORDER BY appearances desc
    ),
    overall_score_by_character AS 
    (
    SELECT 
        split_part(name, ' (', 1) as name, 
        AVG(CASE WHEN overall_score = '∞' THEN 10000 WHEN overall_score = '-' THEN 0 ELSE overall_score::INTEGER END) as overall_score
    FROM {{ ref('hero-abilities')}}
    GROUP BY ALL
    )
    SELECT 
    t10.name,
    t10.publisher,
    t10.appearances,
    osc.overall_score
    FROM top_10_villains_and_heroes t10 
    LEFT JOIN overall_score_by_character osc ON t10.name = osc.name
    ORDER BY overall_score DESC
    ```

    ! We have used a `LEFT JOIN` given tha hero-abilities dataset doesn't contain an entry for Thor (only Thor Girl).

*/

WITH top_10_villains_and_heroes AS 
(
    SELECT 
        ccci.name,
        ccci.publisher,
        dmd.appearances
    FROM {{ ref('clean_comic_characters_info') }} ccci
        INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
    QUALIFY ROW_NUMBER() OVER (partition by '' order by dmd.appearances desc) <= 10
    ORDER BY appearances desc
),
overall_score_by_character AS 
(
  SELECT 
    split_part(name, ' (', 1) as name, 
    AVG(CASE WHEN overall_score = '∞' THEN 10000 WHEN overall_score = '-' THEN 0 ELSE overall_score::INTEGER END) as overall_score
  FROM {{ ref('hero-abilities')}}
  GROUP BY ALL
)
SELECT 
  t10.name,
  t10.publisher,
  t10.appearances,
  osc.overall_score
FROM top_10_villains_and_heroes t10 
  LEFT JOIN overall_score_by_character osc ON t10.name = osc.name
ORDER BY overall_score DESC

/* 

    | Name            | Publisher      | Appearances | Overall_score        |
    |-----------------|----------------|-------------|----------------------|
    | Hulk            | Marvel Comics  | 2019        | 32                   |
    | Iron Man        | Marvel Comics  | 2966        | 22.8                 |
    | Wonder Woman    | DC Comics      | 1231        | 19.66666666666668    |
    | Superman        | DC Comics      | 2496        | 17                   |
    | Vision          | Marvel Comics  | 1137        | 13                   |
    | Captain America | Marvel Comics  | 3362        | 9.66666666666666     |
    | Wolverine       | Marvel Comics  | 3062        | 8.5                  |
    | Batman          | DC Comics      | 3093        | 8                    |
    | Spider-Man      | Marvel Comics  | 4043        | 7.66666666666667     |
    | Thor            | Marvel Comics  | 2259        |                      |


*/