WITH top_10_villains_and_heroes AS 
(
    SELECT 
        ccci.name,
        ccci.publisher,
        dmd.appearances
    FROM {{ ref('clean_comic_characters_info') }} ccci
        INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
    QUALIFY ROW_NUMBER() OVER (partition by '' order by dmd.appearances desc) <= 10
    ORDER BY appearances desc
),
overall_score_by_character AS 
(
  SELECT 
    split_part(name, ' (', 1) as name, 
    AVG(CASE WHEN overall_score = '∞' THEN 10000 WHEN overall_score = '-' THEN 0 ELSE overall_score::INTEGER END) as overall_score
  FROM {{ ref('hero-abilities')}}
  GROUP BY ALL
)
SELECT 
  t10.name,
  t10.publisher,
  t10.appearances,
  osc.overall_score
FROM top_10_villains_and_heroes t10 
  LEFT JOIN overall_score_by_character osc ON t10.name = osc.name
ORDER BY overall_score DESC