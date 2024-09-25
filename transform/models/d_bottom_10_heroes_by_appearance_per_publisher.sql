/* 

Same query as in Question 2, but changing the ordering in the QUALIFY clause from 
`dmd.appearances DESC` to `dmd.appearances ASC`, and updating the ORDER BY in the outer query for readability.

*/

SELECT 
    ccci.name,
    ccci.publisher,
    dmd.appearances
FROM {{ ref('clean_comic_characters_info') }} ccci
    INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
WHERE ccci.alignment = 'good'
QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances asc) <= 10
ORDER BY publisher asc, appearances asc

/* 

    | Name              | Publisher      | Appearances |
    |-------------------|----------------|-------------|
    | Arsenal           | DC Comics      | 1           |
    | Impulse           | DC Comics      | 1           |
    | Green Arrow       | DC Comics      | 1           |
    | Huntress          | DC Comics      | 1           |
    | Oracle            | DC Comics      | 3           |
    | Misfit            | DC Comics      | 3           |
    | Enchantress       | DC Comics      | 5           |
    | Osiris            | DC Comics      | 8           |
    | Starfire          | DC Comics      | 15          |
    | Azrael            | DC Comics      | 37          |
    | Vulcan            | Marvel Comics  | 1           |
    | Corsair           | Marvel Comics  | 1           |
    | Dagger            | Marvel Comics  | 1           |
    | Phoenix           | Marvel Comics  | 1           |
    | Boom-Boom         | Marvel Comics  | 1           |
    | Thing             | Marvel Comics  | 1           |
    | Morph             | Marvel Comics  | 1           |
    | Goliath           | Marvel Comics  | 1           |
    | Man-Thing         | Marvel Comics  | 1           |
    | Valkyrie          | Marvel Comics  | 1           |

*/