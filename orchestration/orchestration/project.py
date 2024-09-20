from pathlib import Path

from dagster_dbt import DbtProject

transform_project = DbtProject(
    project_dir=Path(__file__).joinpath("..", "..", "..", "transform").resolve(),
    packaged_project_dir=Path(__file__).joinpath("..", "..", "dbt-project").resolve(),
)
transform_project.prepare_if_dev()