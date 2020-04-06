from dbt.adapters.oracle.connections import OracleAdapterConnectionManager
from dbt.adapters.oracle.connections import OracleAdapterCredentials
from dbt.adapters.oracle.impl import OracleAdapter

from dbt.adapters.base import AdapterPlugin
from dbt.include import oracle


Plugin = AdapterPlugin(
    adapter=OracleAdapter,
    credentials=OracleAdapterCredentials,
    include_path=oracle.PACKAGE_PATH
)
