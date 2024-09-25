# SuperAwesome Home Assignment
author: [@octavianzarzu](https://www.linkedin.com/in/octavianz/)

This repository contains my submissions for the SuperAwesome Data Code Challenge.

> [!TIP]
> This private repository is accessible only via a secret token included in the shared link. It cannot be found or accessed without the token.

## Contents

This setup can be executed locally. It installs [DuckDB](https://duckdb.org/), [dbt-duckdb](https://github.com/duckdb/dbt-duckdb), and [Dagster](https://dagster.io/). All SQL questions have been modeled as dbt models.

Here is a diagram illustrating the process:

![](./images/superawesome-diagram.png)

## How to run it

At the root folder, there is a Makefile that creates a virtual environment (venv), installs the required dependencies, the DuckDB CLI, copies input CSVs as dbt seeds, and starts Dagster.

To run it, open a terminal and execute:

```
make all
```

This will install the dependencies, copy the input CSVs as dbt seeds, and start the Dagster web server.

Optionally, to install DuckDB CLI on Mac, run:

```
make install_duckdb
```

To remove the virtual environment and logs, run:

```
make clean
```

### Dagster

Once `make all` command finishes, you can access Dagster in your browser at `localhost:3000`. Dagster reads the dbt project from the `transform/` folder.

![](./images/superawesome-dagster.png)

You can build the assets by clicking on the Materialize button.

### dbt 

dbt uses DuckDB to perform SQL transformations (configured in `transform/profiles.yml`) and stores the results (schema and data) in a single file called `superawesome.duckdb` (also configured in `transform/profiles.yml`).

> [!WARNING]
> The superawesome.duckdb database file is included in .gitignore and not tracked by Git due to its size (>100MB).

Once the first model is materialized, the superawesome.duckdb database file is created.

Each question is modeled as a dbt model. Some base models were created for reusability, as several questions share similar SQL snippets.

## Reading a model

In each model, you’ll find the query that populates the table. Some models reference other base models using the `{{ ref('') }}` function. The output has been added as a comment to the query, along with the full query (without references).

The structure of a SQL model is as follows:

1.	Explanation of the approach
2.	The dbt query using one or more reference models
3.	The output result set (which can also be viewed live in duckdb once all assets are materialized via Dagster)
4.	The output query (without references)

Order in which to read: 

```md
transform/models
└── staging
    ├── 1. clean_comic_characters_info.sql - Cleans `comic_characters_info`. Used in Questions a, b, c, d, f
    ├── 2. union_dc_marvel_data.sql - Unions `dc-data` and `marvel-data`. Used in Questions a, b, c, d, e, f
    └── 3. superpowers_character.sql - Fetches only the name of a character and their superpower. Used in Questions e, g, h
├── 4. a_top_10_villains_by_appearance_per_publisher.sql
├── 5. b_top_10_heroes_by_appearance_per_publisher.sql
├── 6. c_bottom_10_villains_by_appearance_per_publisher.sql
├── 7. d_bottom_10_heroes_by_appearance_per_publisher.sql
├── 8. e_top_10_most_common_superpowers.sql
├── 9. f_top_10_heroes.sql
├── 10. g_five_most_common_superpowers.sql
├── 11. h_villain_hero_having_the_five_most_common_superpowers.sql
```


### Querying tables live 

If DuckDB CLI was installed (`make install_duckdb`), activate the virtual environment in the root folder and open the `superawesome.duckdb` file in DuckDB:

```
source venv/bin/activate
duckdb superawesome.duckdb
```

You can query individual models, like:

```
show tables;
```

|                           name                           |
|----------------------------------------------------------|
| a_top_10_villains_by_appearance_per_publisher             |
| b_top_10_heroes_by_appearance_per_publisher               |
| c_bottom_10_villains_by_appearance_per_publisher          |
| clean_comic_characters_info                               |
| comic_characters_info                                     |
| d_bottom_10_heroes_by_appearance_per_publisher            |
| dc-data                                                   |
| e_top_10_most_common_superpowers                          |
| f_top_10_heroes                                           |
| g_five_most_common_superpowers                            |
| h_villain_hero_having_the_five_most_common_superpowers    |
| hero-abilities                                            |
| marvel-data                                               |
| superpowers_character                                     |
| union_dc_marvel_data                                      |
|                           15 rows                        |

```
select * from a_top_10_villains_by_appearance_per_publisher;
```

Alternatively, you can use [Motherduck](https://motherduck.com/), a managed DuckDB service. After creating a free account, you can connect to the local DuckDB file:

```
ATTACH 'md:';
```

Then create or replace the remote database as a clone of the local one:

```
CREATE OR REPLACE DATABASE superawesome_s FROM CURRENT_DATABASE();
```

![](./images/superawesome-motherduck.png)

## Answers

<details><summary>Base models (clean_comic_characters_info, union_dc_marvel_data, superpowers_character) </summary>

### model: [clean_comic_characters_info](./transform/models/staging/clean_comic_characters_info.sql)

1.  The `Alignment` column (good, bad, neutral, and 7 NA values) identifies a character as either a villain (bad) or a hero (good).
2.  There is only one character that is identified as both a villain (bad) and a hero (good):
    
    ```sql
    SELECT name
    FROM comic_characters_info
    GROUP BY name
    HAVING count(distinct alignment) > 1;
    ```
    
    | Name  |
    |-------|
    | Atlas |
    
    However, this character is labeled differently by different publishers:
    
    | Name  | Alignment | Publisher         |
    |-------|-----------|-------------------|
    | Atlas | good      | Marvel Comics     |
    | Atlas | bad       | DC Comics         |
    
    Most questions focus on publisher-specific answers, so this doesn’t pose an issue.

3.  There are duplicate character names, and some characters appear across multiple publishers (e.g., `Atlas` above). Since no question requires attributes from `comic_characters_info` beyond name, alignment, and publisher, we can safely ‘drop’ the remaining features and select only one entry per character, publisher, and alignment.

    ```sql
    SELECT 
        name, 
        alignment, 
        publisher
    FROM comic_characters_info
    QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
    ORDER BY name;
    ```

    **718 rows (734 without filtering)**

    Some characters lack publisher information, but this does not affect our analysis.
    
    This subset will act as the base for further analysis.


    ```sql clean_comic_characters_info
    SELECT 
        name, 
        alignment, 
        publisher
    FROM {{ ref('comic_characters_info') }} 
    QUALIFY row_number() OVER (PARTITION BY name, alignment, publisher) = 1
    ORDER BY name
    ```

### model: [union_dc_marvel_data](./transform/models/staging/union_dc_marvel_data.sql)
    
**dc-data table**

1. The name represents a concatenation of the character name and the universe/comic name (in parentheses). We can extract only the first part (before the parentheses) using `split_part`, but there may be cases where the character name contains parentheses as well. Let’s look at those cases:

    ```sql
    SELECT split_part(name, '(', 1) as character_name 
    FROM "dc-data"
    GROUP BY ALL 
    HAVING count(*) > 1;
    ```

    **17 rows returned, of which:**
    
    - 12 have the same alive status (either deceased or alive in both comics they appear in)
    - 5 have a different status (deceased in one comic, alive in another)

    The only noticeable entry is `Krypto`

    ```sql
    SELECT split_part(name, '(', 1) as character_name, name, alive, appearances 
    FROM "dc-data"
    WHERE name like 'Krypto %';
    ```

    | character_name       | name                             | alive              | appearances |
    |----------------------|----------------------------------|--------------------|-------------|
    | Krypto 	           | Krypto (New Earth)	              | Living Characters  | 109         |
    | Krypto the Earth Dog | Krypto the Earth Dog (New Earth) | Living Characters  | 24          |
    | Krypto 	           | Krypto (Clone) (New Earth)       |	Deceased Characters| 1           |

    Even though it’s a clone/duplicate entry, the status is different, so the additional appearance will count toward the total.

    ```sql
    SELECT split_part(name, '(', 1) as character_name, 
       sum(appearances) 
    FROM "marvel-data"
    GROUP BY character_name
    ```

**marvel-data table** 

1. The same analysis can be done as for the `dc-data` file.

2. Character names are lowercase in `marvel-data`, while in `dc-data` and `comic_characters_info` they are capitalized.


    ```sql union_dc_marvel_data
    WITH 
    clean_dc_data AS 
    (
        SELECT 
            split_part(name, ' (', 1) as character_name, 
            sum(appearances) as appearances
        FROM {{ ref('dc-data') }} 
        GROUP BY character_name
    ),
    clean_marvel_data AS 
    (
        SELECT 
            split_part(name, ' (', 1) as character_name, 
            sum(appearances) as appearances
        FROM {{ ref('marvel-data') }} 
        GROUP BY character_name
    )
    SELECT 'DC Comics' as publisher, character_name, appearances
    FROM clean_dc_data
    UNION 
    SELECT 'Marvel Comics' as publisher, character_name, appearances
    FROM clean_marvel_data
    ```

### model: [superpowers_character](./transform/models/staging/superpowers_character.sql)

1. Cleans up the character name.
    
    ```sql
    SELECT 
        split_part(name, ' (', 1) as name, 
        superpowers
    FROM {{ ref('hero-abilities') }}
    ```

</details>

<details><summary>Top 10 villains by appearance per publisher 'DC', 'Marvel' and 'other'</summary>

### model: [a_top_10_villains_by_appearance_per_publisher](./transform/models/a_top_10_villains_by_appearance_per_publisher.sql)

1. Starting from the [clean_comic_characters_info](./transform/models/staging/clean_comic_characters_info.sql) model, and joining with the appearance data from the [dc-data and marvel-data union](./transform/models/staging/union_dc_marvel_data.sql).

2. Filter only the top 10 villains by appearances per publisher using the `QUALIFY` clause.

    ```sql
    SELECT 
        ccci.name,
        ccci.publisher,
        dmd.appearances
    FROM {{ ref('clean_comic_characters_info') }} ccci
        INNER JOIN {{ ref('union_dc_marvel_data') }} dmd ON lower(ccci.name) = lower(dmd.character_name) AND ccci.publisher = dmd.publisher
    WHERE ccci.alignment = 'bad'
    QUALIFY ROW_NUMBER() OVER (partition by ccci.publisher order by dmd.appearances desc) <= 10
    ORDER BY publisher asc, appearances desc
    ```

> [!WARNING]
> Many rows are filtered out when joining with `clean_comics_character_info` (this can be observed by changing from an INNER JOIN to a FULL OUTER JOIN). While one might perform the analysis based on dc-data and marvel-data only, we cannot determine if a character is good or bad without performing this join.

</details>
