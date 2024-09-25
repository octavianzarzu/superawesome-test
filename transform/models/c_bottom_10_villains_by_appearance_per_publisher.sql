/* 

Same query as in Question 1, but changing the ordering in the QUALIFY clause from 
`dmd.appearances DESC` to `dmd.appearances ASC`, and updating the ORDER BY in the outer query for readability. 

*/

SELECT 
    ccci.name,
    ccci.publisher,
    dmd.appearances
FROM {{ ref('clean_comic_characters_info') }} ccci
    INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
WHERE ccci.alignment = 'bad'
QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances asc) <= 10
ORDER BY publisher asc, appearances asc

/* 

    | Name              | Publisher      | Appearances |
    |-------------------|----------------|-------------|
    | White Canary      | DC Comics      | 6           |
    | Siren             | DC Comics      | 8           |
    | Faora             | DC Comics      | 15          |
    | Parademon         | DC Comics      | 15          |
    | Atlas             | DC Comics      | 16          |
    | Steppenwolf       | DC Comics      | 23          |
    | Trigon            | DC Comics      | 58          |
    | Mister Mxyzptlk   | DC Comics      | 64          |
    | Amazo             | DC Comics      | 71          |
    | Black Manta       | DC Comics      | 95          |
    | Bird-Man          | Marvel Comics  | 1           |
    | Tiger Shark       | Marvel Comics  | 1           |
    | Abomination       | Marvel Comics  | 1           |
    | Hydro-Man         | Marvel Comics  | 1           |
    | Yellow Claw       | Marvel Comics  | 1           |
    | Black Mamba       | Marvel Comics  | 1           |
    | Apocalypse        | Marvel Comics  | 2           |
    | Red Skull         | Marvel Comics  | 2           |
    | Vulture           | Marvel Comics  | 2           |
    | Snake-Eyes        | Marvel Comics  | 3           |

/*