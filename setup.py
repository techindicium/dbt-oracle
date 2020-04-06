#!/usr/bin/env python
from setuptools import find_packages
from setuptools import setup

package_name = "dbt-oracle"
package_version = "0.0.1"
description = """The oracle adpter plugin for dbt (data build tool)"""

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=description,
    author="Indicium Tech",
    author_email="vitor.avancini@indicium.tech",
    url="https://indicium.tech",
    packages=find_packages(),
    package_data={
        'dbt': [
            'include/oracle/dbt_project.yml',
            'include/oracle/macros/*.sql',
            'include/oracle/macros/materializations/seed/*.sql'
        ]
    },
    install_requires=[
        'dbt-core==0.16.0',
        'cx_Oracle==7.3.0'
    ]
)
