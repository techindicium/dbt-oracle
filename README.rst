==========
Oracle DBT
==========


.. image:: https://img.shields.io/pypi/v/dbt-oracle.svg
        :target: https://pypi.python.org/pypi/dbt-oracle

Installation
------------

You need the oracle database client installed in your system in order for this to work,
here (https://cx-oracle.readthedocs.io/en/latest/user_guide/installation.html) you can find the cx_oracle python driver installation instructions.

This (https://gist.github.com/tcnksm/7316877) gist is also a useful resource for installing the client in Ubuntu. It's an old link for Ubuntu 12 but it still works at least for ubuntu 18.

Installing:

:: 
 
    pip install dbt-oracle=0.3.0

Configure your profile
----------------------
.. code-block:: yaml

    dbt_oracle_test: 
       target: dev
       outputs:
          dev:
             type: oracle
             host: localhost
             user: system
             pass: oracle
             port: 1521
             dbname: xe
             schema: system
             threads: 4


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
    -p 1521:1521 \
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


Final Notes
-----------

This is a new project and any contribuitions are welcome.


