==========
 ⚠️ This repo is archived!
==========

Oracle are now the maintainers of the adapter for Oracle db. The repo can be found here: https://github.com/oracle/dbt-oracle

For further questions please ask in the [#db-oracle channel](https://getdbt.slack.com/archives/C01PWH4TXLY) on the [dbt community slack](https://www.getdbt.com/community/join-the-community/)

==========
Oracle DBT
==========

Tested with dbt==0.19.1

for dbt 0.18.0 and below, use dbt-oracle version 0.3.2

.. image:: https://img.shields.io/pypi/v/dbt-oracle.svg
        :target: https://pypi.python.org/pypi/dbt-oracle

Installation
------------

You need the oracle database client installed in your system in order for this to work,
here (https://cx-oracle.readthedocs.io/en/latest/user_guide/installation.html) you can find the cx_oracle python driver installation instructions.

This (https://gist.github.com/tcnksm/7316877) gist is also a useful resource for installing the client in Ubuntu. It's an old link for Ubuntu 12 but it still works at least for ubuntu 18.

Installing:

:: 
 
    pip install dbt-oracle==0.4.3

Configure your profile
----------------------

dbt-oracle supports three authentication methods. In any case, one must specifiy ``user``, ``pass``, ``dbname``, and ``schema``

* host: Setting ``host`` (and possibly ``port`` and ``service``, if that differs from ``dbname``)
* connection string: Setting ``connection_string``
* TNS: Setting dbname only


Host example
------------

.. code-block:: yaml

    dbt_oracle_test: 
       target: dev
       outputs:
          dev:
             type: oracle
             host: localhost
             user: system
             pass: oracle
             port: 1522
             dbname: xe
             schema: system
             threads: 4


If you need to connect via a service name that doesn't match the database name, then you may
optionally specify ``service`` with the above, e.g.:

.. code-block:: yaml
 
             service: xe_ha.domain.tld

TNS example
-----------

Configuring your ORACLE_HOME environment variable so dbt-oracle can find the tnsnames.ora file.
Let's assume your tnsnames.ora file is placed at 

:: 
 
    /home/user/oracle/network/admin/tnsnames.ora


you could set 

:: 
 
    ORACLE_HOME=/home/user/oracle/ 

and your profile:

.. code-block:: yaml

    dbt_oracle_test: 
       target: dev
       outputs:
          dev:
             type: oracle
             user: system
             pass: oracle
             dbname: xe
             schema: system
             threads: 4


Connection string example
-------------------------

.. code-block:: yaml

    dbt_oracle_test: 
       target: dev
       outputs:
          dev:
             type: oracle
             user: system
             pass: oracle
             dbname: xe
             schema: system
             threads: 4
             connection_string: "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=xe_ha.domain.tld)))"


Supported Features
------------------

Materilizations
###############

* table: OK
* view: OK
* incremental: OK
* ephemeral: not OK

Seeds 
#####
OK

Hooks 
#####
OK

Custom schemas 
###############
Not tested

Sources 
###################

Not tested

Testing & documentation
#######################

- Schema tests OK
- Relationship tests Not OK
- Data tests Not OK in general -- These work as long as you do not use CTEs in your data tests. One strategy to manage this is to persist a useful CTE as an analysis.
- SQL Tests OK
- Docs generate Not OK

Snapshots 
#########

OK

Testing
-------

There is a dummy dbt project called dbt_test_project for testing some things that the official dbt integration tests do not cover.
For both dbt_test_project and dbt oficial adpter tests we are using a database user 'dbt_test' with password 'dbt_test'
You have to either create this user os change the credentias at tests/oracle.dbtspec and dbt_test_project/profiles.yml

For running it first start an oracle database instance:
::

    docker run \
        --name dbt-oracle-db \
        -d \
        -p 1522:1522 \
        epiclabs/docker-oracle-xe-11g


Install the project locally

::

    python setup.py install


then run dbt seed and run (theres is a profile file compatible with oracle 11g docker defaults at the test dir)

::
    
    cd dbt_test_project
    dbt seed --profiles-dir ./
    dbt run --profiles-dir ./
    dbt test --profiles-dir ./

you can also run 

::

    make test

for running both dbt adapter tests and the dbt_test_project included in this repo

The following dbt adapter tests are passing:

::

    tests/oracle.dbtspec::test_dbt_empty
    tests/oracle.dbtspec::test_dbt_base
    tests/oracle.dbtspec::test_dbt_ephemeral
    tests/oracle.dbtspec::test_dbt_incremental
    tests/oracle.dbtspec::test_dbt_snapshot_strategy_timestamp
    tests/oracle.dbtspec::test_dbt_snapshot_strategy_check_cols
    tests/oracle.dbtspec::test_dbt_schema_test

Known failing tests:

::

    FAILED tests/oracle.dbtspec::test_dbt_data_test
    FAILED tests/oracle.dbtspec::test_dbt_ephemeral_data_tests
    
The dbt adapter tests for data tests fails due to how the test_dbt_data_test sequence is implemented.
You can use data tests with this adapter, there is an example at the test project in this repo.


Final Notes
-----------

This is a new project and any contribuitions are welcome.


