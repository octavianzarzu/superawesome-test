/* 

Same as above, only replacing the alignment condition to be equal to `Good`. 

*/

SELECT 
    ccci.name,
    ccci.publisher,
    dmd.appearances
FROM {{ ref('clean_comic_characters_info') }} ccci
    INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
WHERE ccci.alignment = 'good'
QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances desc) <= 10
ORDER BY publisher asc, appearances desc

/* 

| Name              | Publisher      | Appearances |
|-------------------|----------------|-------------|
| Batman            | DC Comics      | 3093        |
| Superman          | DC Comics      | 2496        |
| Wonder Woman      | DC Comics      | 1231        |
| Aquaman           | DC Comics      | 1121        |
| Flash             | DC Comics      | 1028        |
| Alan Scott        | DC Comics      | 969         |
| Alfred Pennyworth | DC Comics      | 930         |
| Kyle Rayner       | DC Comics      | 716         |
| Guy Gardner       | DC Comics      | 593         |
| John Stewart      | DC Comics      | 549         |
| Spider-Man        | Marvel Comics  | 4043        |
| Captain America   | Marvel Comics  | 3362        |
| Wolverine         | Marvel Comics  | 3062        |
| Iron Man          | Marvel Comics  | 2966        |
| Thor              | Marvel Comics  | 2259        |
| Hulk              | Marvel Comics  | 2019        |
| Vision            | Marvel Comics  | 1137        |
| Jean Grey         | Marvel Comics  | 1115        |
| Emma Frost        | Marvel Comics  | 886         |
| Luke Cage         | Marvel Comics  | 862         |

*/