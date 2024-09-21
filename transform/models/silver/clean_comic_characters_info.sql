SELECT 
    name, 
    alignment, 
    publisher
FROM {{ ref('comic_characters_info') }} 
QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
ORDER BY name