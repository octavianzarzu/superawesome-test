from dagster import Definitions
from dagster_dbt import DbtCliResource
from .assets import transform_dbt_assets
from .project import transform_project
from .schedules import schedules

defs = Definitions(
    assets=[transform_dbt_assets],
    schedules=schedules,
    resources={
        "dbt": DbtCliResource(project_dir=transform_project),
    },
)