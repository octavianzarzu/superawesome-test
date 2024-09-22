SELECT 
    split_part(name, ' (', 1) as name, 
    superpowers
FROM {{ ref('hero-abilities') }}