import agate
from typing import List, Optional, Tuple, Any, Iterable, Dict
from contextlib import contextmanager
import time

import dbt.exceptions
import cx_Oracle
from cx_Oracle import Connection

from dbt.logger import GLOBAL_LOGGER as logger

from dataclasses import dataclass
from dbt.helper_types import Port

from dbt.adapters.base import Credentials
from dbt.adapters.sql import SQLConnectionManager


@dataclass
class OracleAdapterCredentials(Credentials):
    host: str
    user: str
    port: Port
    password: str  # on postgres the password is mandatoryd

    _ALIASES = {
        'dbname': 'database',
        'sid': 'schema',
        'pass': 'password'
    }

    @property
    def type(self):
        return 'oracle'

    def _connection_keys(self):
        """
        List of keys to display in the `dbt info` output.
        """
        return ('database', 'schema', 'host', 'port', 'user')


class OracleAdapterConnectionManager(SQLConnectionManager):
    TYPE = 'oracle'

    @classmethod
    def open(cls, connection):

        if connection.state == 'open':
            logger.debug('Connection is already open, skipping open.')
            return connection

        credentials = cls.get_credentials(connection.credentials)
        host = f'{credentials.host}:{credentials.port}/{credentials.database}'

        try:
            handle = cx_Oracle.connect(
                credentials.user,
                credentials.password,
                host,
                encoding="UTF-8"
            )

            connection.handle = handle
            connection.state = 'open'
        except cx_Oracle.DatabaseError as e:
            logger.info("Got an error when attempting to open an oracle "
                         "connection: '{}'"
                         .format(e))

            connection.handle = None
            connection.state = 'fail'

            raise dbt.exceptions.FailedToConnectException(str(e))

        return connection

    @classmethod
    def cancel(self, connection):
        connection_name = connection.name
        oracle_connection = connection.handle

        logger.info("Cancelling query '{}' ".format(connection_name))

        try:
            Connection.close(oracle_connection)
        except Exception as e:
            logger.error('Error closing connection for cancel request')
            raise Exception(str(e))

        logger.info("Canceled query '{}'".format(connection_name))

    @classmethod
    def get_status(cls, cursor):
        # Do oracle cx has something for this? could not find it
        return 'OK'

    @classmethod
    def get_response(cls, cursor):
        return 'OK'

    @contextmanager
    def exception_handler(self, sql):
        try:
            yield

        except cx_Oracle.DatabaseError as e:
            logger.info('Oracle error: {}'.format(str(e)))

            try:
                # attempt to release the connection
                self.release()
            except cx_Oracle.Error:
                logger.info("Failed to release connection!")
                pass

            raise dbt.exceptions.DatabaseException(str(e).strip()) from e

        except Exception as e:
            logger.info("Rolling back transaction.")
            self.release()
            if isinstance(e, dbt.exceptions.RuntimeException):
                # during a sql query, an internal to dbt exception was raised.
                # this sounds a lot like a signal handler and probably has
                # useful information, so raise it without modification.
                raise e

            raise dbt.exceptions.RuntimeException(e) from e

    @classmethod
    def get_credentials(cls, credentials):
        return credentials

    def add_query(
        self,
        sql: str,
        auto_begin: bool = True,
        bindings: Optional[Any] = {},
        abridge_sql_log: bool = False
    ) -> Tuple[Connection, Any]:
        connection = self.get_thread_connection()
        if auto_begin and connection.transaction_open is False:
            self.begin()

        logger.debug('Using {} connection "{}".'
                     .format(self.TYPE, connection.name))

        with self.exception_handler(sql):
            if abridge_sql_log:
                log_sql = '{}...'.format(sql[:512])
            else:
                log_sql = sql

            logger.debug(
                'On {connection_name}: {sql}',
                connection_name=connection.name,
                sql=log_sql,
            )
            pre = time.time()

            cursor = connection.handle.cursor()
            cursor.execute(sql, bindings)
            connection.handle.commit()
            logger.debug(
                "SQL status: {status} in {elapsed:0.2f} seconds",
                status=self.get_status(cursor),
                elapsed=(time.time() - pre)
            )

            return connection, cursor

    def add_begin_query(self):
        connection = self.get_thread_connection()
        cursor = connection.handle.cursor
        return connection, cursor
