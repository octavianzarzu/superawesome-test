/* 

Motherduck:
╰─$ duckdb superawesome.duckdb
v1.1.0 fa5c2fe15f
Enter ".help" for usage hints.
D ATTACH 'md:';

## Assumptions

**comic_characters_info table**

1.  The `Alignment` column (good, bad, neutral, and 7 NA values) identifies a character as a villain (bad) or hero (good)
2.  There is only one Character that is identified as both villain (bad) and hero (good): 

    SELECT name
    FROM comic_characters_info
    GROUP BY name
    HAVING count(distinct alignment) > 1;

    # Atlas

    However, this Character is labeled differently for different Publishers 

    # Atlas | good | Marvel Comics
    # Atlas | bad  | DC Comics

    The majority of the questions focus specifically on a per publisher answer, so this doesn't represent an issue.

3.  There are duplicate character names. There are also Characters across multiple publishers (3), such as Atlas above. Given that in no question we are interested
    in other attributes from comic_characters_info other than name, alignment, and publisher we can safely 'drop' the remaining features in our analysis and only pick
    one entry per character, publisher, and alignment. 

    SELECT 
        name, 
        alignment, 
        publisher
    FROM comic_characters_info
    QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
    ORDER BY name;

    # 718 rows (734 without filtering)

    Some of the Characters have no publisher information but this doesn't affect our analysis. 

    This subset will act as the base for any further analysis. - silver_comic_characters_info


**dc-data table**

1. The name represents a concatenation of Character (Universe/Comic name). We can extract only the first part (before '(') using split_part, however there might be cases where the name of the character contains '(' also. Let's look at those: 

    SELECT split_part(name, '(', 1) as character_name 
    FROM "dc-data"
    GROUP BY ALL 
    HAVING count(*) > 1;

    # 17 rows returned, of which: 
    
    12 have the same alive status (deceased or alive in both comics they appear in) and 
    5 have a different status (deceased in one comic, alive in another comic).

    The only noticeable entry is of Krypto

    SELECT split_part(name, '(', 1) as character_name, name, alive, appearances 
    FROM "dc-data"
    WHERE name like 'Krypto %';

    # Krypto 	            Krypto (New Earth)	                Living Characters	109
    # Krypto the Earth Dog 	Krypto the Earth Dog (New Earth)	Living Characters	24
    # Krypto 	            Krypto (Clone) (New Earth)      	Deceased Characters	1

    Even if it's a clone/duplicate entry, the status is different and the additional appearance will be counted towards the total. 

    SELECT split_part(name, '(', 1) as character_name, 
       sum(appearances) 
    FROM "marvel-data"
    GROUP BY character_name

** marvel-data table ** 

1. The same analysis can be done as in the case of the dc-data table above. 

2. Character names are lowercase, whereas in dc-data and comic_characters_info are capitalized. 

** dc-data and marvel-data tables ** 

We will create a union of the two given that all questions require us to focus on both equally:

    WITH 
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
    )
    SELECT 'DC Comics' as publisher, character_name, appearances
    FROM clean_dc_data
    UNION 
    SELECT 'Marvel Comics' as publisher, character_name, appearances
    FROM clean_marvel_data



## Questions

1. * Top 10 villains by appearance per publisher 'DC', 'Marvel' and 'other'

We will start from the query above filtering duplicate names across names, and publishers (clean_comics_character_info) and join with the appearances in "dc-data" and "marvel-data".

We will union the data in dc and marvel subsets to get a holistic view. When joining we will lower the names as in "marvel-data" they are lowercase and in "dc-data" comics_character_info and  they are capitalized. 

Lastly we will filter only the top 10 villains by appearence by publisher using the QUALIFY clause. 

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
WHERE ccci.alignment = 'bad'
QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances desc) <= 10
ORDER BY publisher asc, appearances desc

| Name              | Publisher      | Appearances |
|-------------------|----------------|-------------|
| Joker             | DC Comics      | 517         |
| Swamp Thing       | DC Comics      | 309         |
| Big Barda         | DC Comics      | 216         |
| Gorilla Grodd     | DC Comics      | 179         |
| Bane              | DC Comics      | 157         |
| Maxima            | DC Comics      | 124         |
| Granny Goodness   | DC Comics      | 115         |
| Black Manta       | DC Comics      | 95          |
| Amazo             | DC Comics      | 71          |
| Mister Mxyzptlk   | DC Comics      | 64          |
| Sabretooth        | Marvel Comics  | 382         |
| Venom             | Marvel Comics  | 371         |
| Mephisto          | Marvel Comics  | 317         |
| Thanos            | Marvel Comics  | 317         |
| Bullseye          | Marvel Comics  | 277         |
| Mandarin          | Marvel Comics  | 193         |
| Ultron            | Marvel Comics  | 187         |
| Sebastian Shaw    | Marvel Comics  | 174         |
| Hela              | Marvel Comics  | 170         |
| Dormammu          | Marvel Comics  | 132         |


Note: A lot of rows get filtered out when joining with clean_comics_character_info (can be seen when changing from INNER JOIN to FULL OUTER JOIN) and one might
do the analysis based on "dc-data" and "marvel-data" alone, but we cannot infer if a character is good or bad without performing this join. 

* Top 10 heroes by appearance per publisher 'DC', 'Marvel' and 'other'

Same as above, only replacing the alignemnt condition to be equal to Good.

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
WHERE ccci.alignment = 'good'
QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances desc) <= 10
ORDER BY publisher asc, appearances desc


* Bottom 10 villains by appearance per publisher 'DC', 'Marvel' and 'other'

Same query as per number 1, just changing the ordering in the QUALIFY clause from dmd.appearances DESC to dmd.appearances ASC and the outer query ORDER BY for readability.

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
WHERE ccci.alignment = 'bad'
QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances asc) <= 10
ORDER BY publisher asc, appearances asc

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

* Bottom 10 heroes by appearance per publisher 'DC', 'Marvel' and 'other'

Same as above. 

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
WHERE ccci.alignment = 'good'
QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances asc) <= 10
ORDER BY publisher asc, appearances asc

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

* Top 10 most common superpowers by creator 'DC', 'Marvel' and 'other'

Step 1. Join superpowers with clean_dc_marvel_data (see Questions 1, 2, 3 and 4.)

WITH superpowers AS 
(
  SELECT 
    split_part(name, ' (', 1) as name, 
    superpowers
  FROM "hero-abilities"
),
clean_dc_data AS 
(
    SELECT 
        DISTINCT split_part(name, ' (', 1) as character_name
    FROM "dc-data"
    
),
clean_marvel_data AS 
(
    SELECT 
        DISTINCT split_part(name, ' (', 1) as character_name
    FROM "marvel-data"
),
dc_marvel_data AS 
(
    SELECT 'DC Comics' as publisher, character_name
    FROM clean_dc_data
    UNION 
    SELECT 'Marvel Comics' as publisher, character_name
    FROM clean_marvel_data
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

2. The superpowers columns we will convert into an ARRAY and UNNEST to have one superpower from the array on one row for each publisher. 

publisher_superpowers_join_unnest AS 
(
  SELECT 
    UNNEST(CAST(superpowers AS VARCHAR[])) as superpower, 
    publisher
  FROM publisher_superpowers_join
)
..

3. We will count how many times a superpower was mentioned for each publisher and apply the same QUALIFY clause as in Questions 1, 2, 3, and 4 to only output the top 10 by publisher.

SELECT 
    replace(superpower,'''','') as superpower,
    publisher,
    count(*) as count  
FROM publisher_superpowers_join_unnest
GROUP BY superpower, publisher
QUALIFY ROW_NUMBER() OVER (partition by publisher order by count(*) desc) <= 10
ORDER BY publisher, count(*) DESC; 

Final query:

WITH superpowers AS 
(
  SELECT 
    split_part(name, ' (', 1) as name, 
    superpowers
  FROM "hero-abilities"
),
clean_dc_data AS 
(
    SELECT 
        DISTINCT split_part(name, ' (', 1) as character_name
    FROM "dc-data"
    
),
clean_marvel_data AS 
(
    SELECT 
        DISTINCT split_part(name, ' (', 1) as character_name
    FROM "marvel-data"
),
dc_marvel_data AS 
(
    SELECT 'DC Comics' as publisher, character_name
    FROM clean_dc_data
    UNION 
    SELECT 'Marvel Comics' as publisher, character_name
    FROM clean_marvel_data
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
ORDER BY publisher, count(*) DESC; 

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

