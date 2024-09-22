
WITH superpowers AS 
(
  SELECT 
        name,
        superpowers
  FROM {{ ref('superpowers_character') }}
),
superpowers_unnest AS
(
  SELECT 
    name,
    UNNEST(CAST(superpowers AS VARCHAR[])) as superpower
  FROM superpowers
), top_5_superpowers AS 
(
  SELECT
    superpower,
    count
  FROM {{ ref("g_five_most_common_superpowers")}}
)
SELECT su.name
FROM superpowers_unnest su 
  INNER JOIN top_5_superpowers t5s ON replace(su.superpower,'''','') = t5s.superpower
GROUP BY su.name
HAVING COUNT(*) = 5
