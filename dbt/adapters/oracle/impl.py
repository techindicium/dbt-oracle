from dbt.adapters.sql import SQLAdapter
from dbt.adapters.oracle import OracleAdapterConnectionManager
from dbt.adapters.oracle.relation import OracleRelation

import agate


class OracleAdapter(SQLAdapter):
    ConnectionManager = OracleAdapterConnectionManager
    Relation = OracleRelation

    @classmethod
    def date_function(cls):
        return 'CURRENT_DATE'

    @classmethod
    def convert_number_type(cls, agate_table, col_idx):
        decimals = agate_table.aggregate(agate.MaxPrecision(col_idx))
        return "float" if decimals else "int"