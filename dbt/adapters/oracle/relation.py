from dataclasses import dataclass
from dbt.adapters.base.relation import BaseRelation, Policy


@dataclass
class OracleQuotePolicy(Policy):
    database: bool = False
    schema: bool = False
    identifier: bool = False


@dataclass
class OracleIncludePolicy(Policy):
    database: bool = False
    schema: bool = True
    identifier: bool = True


@dataclass(frozen=True, eq=False, repr=False)
class OracleRelation(BaseRelation):
    quote_policy: OracleQuotePolicy = OracleQuotePolicy()
    include_policy: OracleIncludePolicy = OracleIncludePolicy()

    @staticmethod
    def add_ephemeral_prefix(name):
        return f'dbt__cte__{name}__'