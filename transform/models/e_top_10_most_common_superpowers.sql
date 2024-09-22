
WITH superpowers AS 
(
  SELECT 
        name,
        superpowers
  FROM {{ ref('superpowers_character') }}
),
dc_marvel_data AS 
(
    SELECT 
        publisher, 
        character_name
    FROM {{ ref("union_dc_marvel_data")}}
),
publisher_superpowers_join AS
(
    SELECT 
        sp.name,
        dmd.publisher,
        sp.superpowers
    FROM superpowers sp
        INNER JOIN dc_marvel_data dmd ON lower(sp.name) = lower(dmd.character_name)
),
publisher_superpowers_join_unnest AS 
(
  SELECT 
    UNNEST(CAST(superpowers AS VARCHAR[])) as superpower, 
    publisher
  FROM publisher_superpowers_join
)
SELECT 
    replace(superpower,'''','') as superpower,
    publisher,
    count(*) as count  
FROM publisher_superpowers_join_unnest
GROUP BY superpower, publisher
QUALIFY ROW_NUMBER() OVER (partition by publisher order by count(*) desc) <= 10
ORDER BY publisher, count(*) DESC