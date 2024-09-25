/* 

1. Starting from the [clean_comic_characters_info](./transform/models/staging/clean_comic_characters_info.sql) model, and joining with the appearance data from the [dc-data and marvel-data union](./transform/models/staging/union_dc_marvel_data.sql).

2. Filter only the top 10 villains by appearances per publisher using the `QUALIFY` clause.

Note: Many rows are filtered out when joining with `clean_comics_character_info` (this can be observed by changing from an INNER JOIN to a FULL OUTER JOIN).
While one might perform the analysis based on dc-data and marvel-data only, we cannot determine if a character is good or bad without performing this join.

*/

SELECT 
    ccci.name,
    ccci.publisher,
    dmd.appearances
FROM {{ ref('clean_comic_characters_info') }} ccci
    INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
WHERE ccci.alignment = 'bad'
QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances desc) <= 10
ORDER BY publisher asc, appearances desc