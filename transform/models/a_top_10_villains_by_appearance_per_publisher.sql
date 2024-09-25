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


/* 

| Name              | Publisher      | Appearances |
|-------------------|----------------|-------------|
| Joker             | DC Comics      | 517         |
| Swamp Thing       | DC Comics      | 309         |
| Big Barda         | DC Comics      | 216         |
| Gorilla Grodd     | DC Comics      | 179         |
| Bane              | DC Comics      | 157         |
| Maxima            | DC Comics      | 124         |
| Granny Goodness   | DC Comics      | 115         |
| Black Manta       | DC Comics      | 95          |
| Amazo             | DC Comics      | 71          |
| Mister Mxyzptlk   | DC Comics      | 64          |
| Sabretooth        | Marvel Comics  | 382         |
| Venom             | Marvel Comics  | 371         |
| Mephisto          | Marvel Comics  | 317         |
| Thanos            | Marvel Comics  | 317         |
| Bullseye          | Marvel Comics  | 277         |
| Mandarin          | Marvel Comics  | 193         |
| Ultron            | Marvel Comics  | 187         |
| Sebastian Shaw    | Marvel Comics  | 174         |
| Hela              | Marvel Comics  | 170         |
| Dormammu          | Marvel Comics  | 132         |

*/