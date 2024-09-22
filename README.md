# SuperAwesome Home Assignment
author: [@octavianzarzu](https://www.linkedin.com/in/octavianz/)

This repository contains my submissions for the SuperAwesome Data Code Challenge.

> [!TIP]
> This private repository is accessible only via a secret token (part of the shared link). It cannot be found or accessed without the token.

## Contents

This setup can be executed locally. It installs [DuckDB](https://duckdb.org/), [dbt-duckdb](https://github.com/duckdb/dbt-duckdb), and [Dagster](https://dagster.io/). All SQL questions have been modeled as dbt models.

Here is a diagram illustrating the process:

TO ADD IMAGE

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

TO ADD IMAGE

You can build the assets by clicking on the Materialize button.

### dbt 

dbt uses DuckDB to perform SQL transformations (configured in `transform/profiles.yml`) and stores the results (schema and data) in a single file called `superawesome.duckdb` (also configured in `transform/profiles.yml`).

> [!WARNING]
> The superawesome.duckdb database file is included in .gitignore and not tracked by Git due to its size (>100MB).

Each question is modeled as a dbt model. Some base models were created for reusability, as several questions share similar SQL snippets.

TO ADD Structure of dbt models 


## How to read a model

In each model, you’ll find the query that populates the table. Some models reference other base models using the `{{ ref('') }}` function. The output has been added as a comment to the query, along with the full query (without references).

The structure of a SQL model is as follows:

1.	Explanation of the approach
2.	The dbt query using one or more reference models
3.	The output result set (which can also be viewed live in duckdb once all assets are materialized via Dagster)
4.	The output query (without references)

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
|----------------------------------------------------------|
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




