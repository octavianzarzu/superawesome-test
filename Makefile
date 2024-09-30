# Makefile for setting up dbt-duckdb project and seeding data

# Variables
DBT_PROJECT_DIR := transform
DAGSTER_PROJECT_DIR := orchestration
SEEDS_DIR := $(DBT_PROJECT_DIR)/seeds
CSVS_SOURCE_DIR := assignment/data
VENV_DIR := venv

# Default target
all: install_requirements copy_seeds start_dagster

# Create virtual environment if it doesn't exist
$(VENV_DIR)/bin/activate:
	python3 -m venv $(VENV_DIR)

# Install all required Python packages
install_requirements: $(VENV_DIR)/bin/activate
	$(VENV_DIR)/bin/pip install --upgrade pip
	$(VENV_DIR)/bin/pip install duckdb
	$(VENV_DIR)/bin/pip install dbt-duckdb
	$(VENV_DIR)/bin/pip install dagster dagit
	$(VENV_DIR)/bin/pip install dagster-dbt

install_duckdb:
	brew install duckdb

# Initialize dbt project if it doesn't exist
# init_dbt_project: install_requirements
# 	if [ ! -d "$(DBT_PROJECT_DIR)" ]; then \
# 		$(VENV_DIR)/bin/dbt init $(DBT_PROJECT_DIR); \
# 	fi

# create_profiles_yml: init_dbt_project
# 	cd $(DBT_PROJECT_DIR) && \
# 	echo "$(DBT_PROJECT_DIR):" > profiles.yml && \
# 	echo "  target: dev" >> profiles.yml && \
# 	echo "  outputs:" >> profiles.yml && \
# 	echo "    dev:" >> profiles.yml && \
# 	echo "      type: duckdb" >> profiles.yml && \
# 	echo "      path: ../superawesome.duckdb" >> profiles.yml && \
# 	echo "      threads: 4" >> profiles.yml

# Copy CSV files to seeds folder
copy_seeds: install_requirements
	mkdir -p $(SEEDS_DIR)
	cp $(CSVS_SOURCE_DIR)/*.csv $(SEEDS_DIR)/

# # Initialize a Dagster project
# init_dagster_project: init_dbt_project
# 	if [ ! -d "$(DAGSTER_PROJECT_DIR)" ]; then \
# 		$(VENV_DIR)/bin/dagster-dbt project scaffold --project-name $(DAGSTER_PROJECT_DIR) --dbt-project-dir $(DBT_PROJECT_DIR); \
# 	fi

start_dagster: install_requirements
	export DAGSTER_HOME=$(PWD)/orchestration/dagster_home && \
	source $(VENV_DIR)/bin/activate && \
	mkdir -p $(PWD)/orchestration/dagster_home && \
	cd orchestration && ../$(VENV_DIR)/bin/dagster dev

# Clean up
clean:
	# rm -rf $(DBT_PROJECT_DIR)
	# rm -rf $(DAGSTER_PROJECT_DIR)
	rm -rf $(VENV_DIR)/
	rm -rf logs/