/* 

  1. Join superpowers with clean_dc_marvel_data (similar to Questions 1, 2, 3, and 4).

    ```sql
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
    ..
    ```

    2. Convert the `superpowers` column into an array and using UNNEST so each superpower from the array appears on a separate row for each publisher.

    ```sql 
    ,
    publisher_superpowers_join_unnest AS 
    (
    SELECT 
        UNNEST(CAST(superpowers AS VARCHAR[])) as superpower, 
        publisher
    FROM publisher_superpowers_join
    )
    ...
    ```

    3. Count how many times each superpower is mentioned per publisher and apply the same QUALIFY clause as in Questions 1-4 to only output the top 10 per publisher.

    ```sql 
    SELECT 
        replace(superpower,'''','') as superpower,
        publisher,
        count(*) as count  
    FROM publisher_superpowers_join_unnest
    GROUP BY superpower, publisher
    QUALIFY ROW_NUMBER() OVER (partition by publisher order by count(*) desc) <= 10
    ORDER BY publisher, count(*) DESC
    ```
  
*/


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

/* 

  | Name                | Publisher      | Appearances |
  |---------------------|----------------|-------------|
  | Agility             | DC Comics      | 79          |
  | Stamina             | DC Comics      | 74          |
  | Super Strength      | DC Comics      | 72          |
  | Durability          | DC Comics      | 68          |
  | Weapons Master      | DC Comics      | 67          |
  | Intelligence        | DC Comics      | 66          |
  | Reflexes            | DC Comics      | 66          |
  | Super Speed         | DC Comics      | 53          |
  | Weapon-based Powers | DC Comics      | 51          |
  | Marksmanship        | DC Comics      | 50          |
  | Agility             | Marvel Comics  | 134         |
  | Super Strength      | Marvel Comics  | 129         |
  | Durability          | Marvel Comics  | 128         |
  | Stamina             | Marvel Comics  | 118         |
  | Super Speed         | Marvel Comics  | 96          |
  | Reflexes            | Marvel Comics  | 92          |
  | Weapons Master      | Marvel Comics  | 90          |
  | Intelligence        | Marvel Comics  | 87          |
  | Accelerated Healing | Marvel Comics  | 82          |
  | Marksmanship        | Marvel Comics  | 75          |

*/