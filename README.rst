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
    
    pip install dbt-oracle=0.1.3

Configure your profile
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
             port: 1521
             dbname: xe
             schema: system
             threads: 4

Supported Features
-------
Materilizations
###############

* table: OK
* view: OK
* incremental: not OK
* ephemeral: not tested

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
- Relationship testes Not OK
- SQL Tests OK
- Docs generate Not OK

Snapshots 
#########

Not OK

Testing
-------

There is a dummy dbt project called dbt_test_project for testing some things that the official dbt integration tests do not cover. For running it first start an oracle database instance:

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


DBT Integration Tests
---------------------

DBT team provides a project with some integration tests that can programatically assert that the plugin provides all 
the DBT features.

you can find it here: https://github.com/fishtown-analytics/dbt-integration-tests

Currently we are using a fork of this project to apadpt some parts of it for running with oracle db

https://github.com/vitoravancini/dbt-integration-tests

The specific changes are specified at the project's readme

for running it against dbt-oracle adapter one can run:

::

    make test-dbt-integration



Final Notes
-----------

This is a new project and any contribuitions are welcome.

ChangeLog
-----------
v0.1.3
######

First Version

