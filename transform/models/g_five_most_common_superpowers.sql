
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
)
SELECT 
    replace(superpower,'''','') as superpower,
    count(*) as count  
FROM superpowers_unnest
GROUP BY superpower
QUALIFY ROW_NUMBER() OVER (partition by '' order by count(*) desc) <= 5
ORDER BY count(*) DESC
