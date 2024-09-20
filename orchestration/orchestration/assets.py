from dagster import AssetExecutionContext
from dagster_dbt import DbtCliResource, dbt_assets

from .project import transform_project


@dbt_assets(manifest=transform_project.manifest_path)
def transform_dbt_assets(context: AssetExecutionContext, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()
    