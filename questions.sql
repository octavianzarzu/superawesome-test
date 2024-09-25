

6. Of the top 10 villains and heroes, re-rank them based on their overall score

Let's start from the answer we got in Question 1 and 2 and remove the alignment = 'good' condition to get all villains and heroes

WITH clean_comics_character_info AS 
(
    SELECT 
        name, 
        alignment, 
        publisher,
    FROM comic_characters_info
    QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
    ORDER BY name
),
clean_dc_data AS 
(
    SELECT 
        split_part(name, ' (', 1) as character_name, 
        sum(appearances) as appearances
    FROM "dc-data"
    GROUP BY character_name
),
clean_marvel_data AS 
(
    SELECT 
        split_part(name, ' (', 1) as character_name, 
        sum(appearances) as appearances
    FROM "marvel-data"
    GROUP BY character_name
),
dc_marvel_data AS 
(
    SELECT 'DC Comics' as publisher, character_name, appearances
    FROM clean_dc_data
    UNION 
    SELECT 'Marvel Comics' as publisher, character_name, appearances
    FROM clean_marvel_data
)
SELECT 
    ccci.name,
    ccci.publisher,
    dmd.appearances
FROM clean_comics_character_info ccci
    INNER JOIN dc_marvel_data dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
QUALIFY ROW_NUMBER() OVER (partition by '' order by dmd.appearances desc) <= 10
ORDER BY appearances desc


Let's join in hero-abilities to get the overall_score. As we can see in the data there are duplicate entries by character name, given that there might be multiple
Comics in which the same character was part of. We'll use average on the overall_score to get a single overall_score for a character. 

But, we get an error! Strings ∞ and - are part of the data. Let's use a CASE statement to replace these values: ∞ as 10000 (max value in the dataset is less than 1000) and - as 0. 

SELECT 
    split_part(name, ' (', 1) as name, 
    AVG(CASE WHEN overall_score = '∞' THEN 10000 WHEN overall_score = '-' THEN 0 ELSE overall_score::INTEGER END) as overall_score
  FROM "hero-abilities"
GROUP BY ALL;

Let's join the two datasets and order by the overall_score:

WITH clean_comics_character_info AS 
(
    SELECT 
        name, 
        alignment, 
        publisher,
    FROM comic_characters_info
    QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
    ORDER BY name
),
clean_dc_data AS 
(
    SELECT 
        split_part(name, ' (', 1) as character_name, 
        sum(appearances) as appearances
    FROM "dc-data"
    GROUP BY character_name
),
clean_marvel_data AS 
(
    SELECT 
        split_part(name, ' (', 1) as character_name, 
        sum(appearances) as appearances
    FROM "marvel-data"
    GROUP BY character_name
),
dc_marvel_data AS 
(
    SELECT 'DC Comics' as publisher, character_name, appearances
    FROM clean_dc_data
    UNION 
    SELECT 'Marvel Comics' as publisher, character_name, appearances
    FROM clean_marvel_data
),
top_10_villains_and_heroes AS 
(
SELECT 
    ccci.name,
    ccci.publisher,
    dmd.appearances
FROM clean_comics_character_info ccci
    INNER JOIN dc_marvel_data dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
QUALIFY ROW_NUMBER() OVER (partition by '' order by dmd.appearances desc) <= 10
ORDER BY appearances desc
),
overall_score_by_character AS 
(
  SELECT 
    split_part(name, ' (', 1) as name, 
    AVG(CASE WHEN overall_score = '∞' THEN 10000 WHEN overall_score = '-' THEN 0 ELSE overall_score::INTEGER END) as overall_score
  FROM "hero-abilities"
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

| Name            | Publisher      | Appearances | Overall_score        |
|-----------------|----------------|-------------|----------------------|
| Hulk            | Marvel Comics  | 2019        | 32                   |
| Iron Man        | Marvel Comics  | 2966        | 22.8                 |
| Wonder Woman    | DC Comics      | 1231        | 19.66666666666668    |
| Superman        | DC Comics      | 2496        | 17                   |
| Vision          | Marvel Comics  | 1137        | 13                   |
| Captain America | Marvel Comics  | 3362        | 9.66666666666666     |
| Wolverine       | Marvel Comics  | 3062        | 8.5                  |
| Batman          | DC Comics      | 3093        | 8                    |
| Spider-Man      | Marvel Comics  | 4043        | 7.66666666666667     |
| Thor            | Marvel Comics  | 2259        |                      |


We have used a LEFT JOIN given tha hero-abilities dataset doesn't contain an entry for Thor (only Thor Girl).


7. What are the 5 most common superpowers?

We'll use question 5 answer, and remove the join with publisher. 

WITH superpowers AS 
(
  SELECT 
    split_part(name, ' (', 1) as name, 
    superpowers
  FROM "hero-abilities"
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
ORDER BY count(*) DESC; 

| Superpower      | Count |
|-----------------|-------|
| Agility         | 625   |
| Stamina         | 587   |
| Super Strength  | 582   |
| Durability      | 557   |
| Reflexes        | 483   |


* Which hero and villain have the 5 most common superpowers?

We'll use the answer from question 7. and join back with the hero-abilities to do some array searching via an INNER JOIN. Lastly we will filter only those Characters who have all 5 most common superpowers:

WITH superpowers AS 
(
  SELECT 
    split_part(name, ' (', 1) as name, 
    superpowers
  FROM "hero-abilities"
),
  superpowers_unnest AS
(
  SELECT 
    name,
    UNNEST(CAST(superpowers AS VARCHAR[])) as superpower
  FROM superpowers
),
top_5_superpowers AS 
(
  SELECT 
      replace(superpower,'''','') as superpower,
      count(*) as count  
  FROM superpowers_unnest
  GROUP BY superpower
  QUALIFY ROW_NUMBER() OVER (partition by '' order by count(*) desc) <= 5
  ORDER BY count(*) DESC
)
SELECT su.name
FROM superpowers_unnest su INNER JOIN top_5_superpowers t5s ON replace(su.superpower,'''','') = t5s.superpower
GROUP BY su.name
HAVING COUNT(*) = 5

# 199 rows returned. 

A-Bomb
Asura
Commander Machia
Darth Nox
Devilman
Fangtom
Goku
Hancock
Harry Osborn
Hourman
Kenshiro
Killow
Kisame
Kruncha
Lady Deadpool
Laira
Life Entity
Namor
Resurrection Spawn
Skales
Spider-Gwen
The Executioner
The Great Devourer
Ultron
Volstagg
Angela
Azrael
Brainiac 5
Captain Britain
Damien Darhk
Garmadon
Graviton
Hogun
Hybrid
Invincible
Killian
Kylo Ren
Lucifer
Mario
Nadakhan
Old King Thor
Puck
Reign
Shadow The Hedgehog
Skaar
Stargirl
The Keeper
The One Below All
Zane
Attuma
Bloodaxe
Buri
Chop'rai
Cyborg Superman
Dante
Dark Phoenix
Doctor Occult
Ghost Rider 2099
Grid
Icon
Infernal Hulk
Killmonger
Legolas
Nagato Uzumaki
Nightcrawler
Nomad
Samukai
Samurai Mech(Stone Army)
The Goon
Venompool
Wesker
World Breaker Hulk
Big Barda
Black Bolt
Caesar
Captain Soto
Commander Blunck
Cull Obsidian
Death Seed Draken
Doom Slayer
Firestorm II
First Spinjitzu Master
General Cryptor
Grand Master Skywalker
Immortal Hulk
Iron Baron
Mongul
Ragman
Samurai X
Sasuke Uchiha
Scorpion
Strange Visitor Superman
The Crow
The Upgrade
Toad
Tobirama Senju
Ursa Major
Violator
Warpath
Abe Sapien
Acidicus
Big Boss
Catwoman
Darth Maul
Fëanor
Golden Ninja
Gorilla Grodd
Incredible Hulk
Lightray
Mongul The Elder
Mystique
Namorita
Omega
Powerboy
Queen Hippolyta
Shisui Uchiha
Silk
Solid Snake
Steel Serpent
The Rival
Vixen
White Wolf
Wonder Girl
Zero
Achilles Warkiller
Amazo
Anti-Spawn
Bumblebee
Firestorm
Giant Stone Warrior
Heart Of The Monster Hulk
Honey Badger
John Constantine
Kratos
Lashina
Madara Uchiha
Mistake
Morlun
Percy Jackson
Proxima Midnight
Raiden
Selene
Spider-Woman
Symbiote Wolverine
Thanos
Vixen II
Yang
Zoom
Angel Of Death
Annihilus
Battlestar
Bizarro-Girl
Bor Burison
Caliban
Captain Mar-vell
Destroyer
Doomguy
General Kozu
Granny Goodness
Green Lantern
Hellboy
Hive
Homelander
Karlof
Lar Gand
Martian Manhunter
Sonic The Hedgehog
Vampire Batman
Vergil
Vili
Alita
Anacondrai Serpent
Aquaman
Aspheera
Balder
Buffy
Cheetah III
Corvus Glaive
Cosmic Hulk
Donna Troy
Dracula
Gaara
Gamora
Goblin Force
Iron Destroyer
Kapau'rai
Lady Deathstrike
Lizard
Lord Garmadon
Naruto Uzumaki
Omni-Man
Reverse Flash
Scarlet Spider II
Shao Kahn
Shin Godzilla
Songbird
Supergirl
T-X
The Beyonder

