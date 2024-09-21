SELECT 
    ccci.name,
    ccci.publisher,
    dmd.appearances
FROM {{ ref('clean_comic_characters_info') }} ccci
    INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
WHERE ccci.alignment = 'bad'
QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances desc) <= 10
ORDER BY publisher asc, appearances desc