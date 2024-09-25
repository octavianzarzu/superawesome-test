
/* 

We’ll use the answer from Question 7 and join it back with `hero-abilities` to perform array searching via an INNER JOIN. 
Lastly, we will filter for characters who have all five of the most common superpowers.

*/

WITH superpowers AS 
(
  SELECT 
        name,
        superpowers
  FROM {{ ref('superpowers_character') }}
),
superpowers_unnest AS
(
  SELECT 
    name,
    UNNEST(CAST(superpowers AS VARCHAR[])) as superpower
  FROM superpowers
), top_5_superpowers AS 
(
  SELECT
    superpower,
    count
  FROM {{ ref("g_five_most_common_superpowers")}}
)
SELECT su.name
FROM superpowers_unnest su 
  INNER JOIN top_5_superpowers t5s ON replace(su.superpower,'''','') = t5s.superpower
GROUP BY su.name
HAVING COUNT(*) = 5

/* 

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

*/