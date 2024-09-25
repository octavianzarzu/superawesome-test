/* 

We’ll use the first part of the answer from Question 5 and remove the join with the publisher.

*/


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

/*

  | Superpower      | Count |
  |-----------------|-------|
  | Agility         | 625   |
  | Stamina         | 587   |
  | Super Strength  | 582   |
  | Durability      | 557   |
  | Reflexes        | 483   |

*/