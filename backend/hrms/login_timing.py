import logging
from functools import wraps
from time import perf_counter

from django.db import connection


logger = logging.getLogger(__name__)


def measure_login(view):
    """Report aggregate durations without logging credentials or tokens."""
    @wraps(view)
    def measured(*args, **kwargs):
        started = perf_counter()
        database_seconds = 0.0
        query_count = 0

        def measure_query(execute, sql, params, many, context):
            nonlocal database_seconds, query_count
            query_started = perf_counter()
            try:
                return execute(sql, params, many, context)
            finally:
                database_seconds += perf_counter() - query_started
                query_count += 1

        with connection.execute_wrapper(measure_query):
            response = view(*args, **kwargs)
        total_ms = (perf_counter() - started) * 1000
        response['Server-Timing'] = (
            f'login;dur={total_ms:.1f}, db;dur={database_seconds * 1000:.1f}'
        )
        logger.info(
            'Login status=%s total_ms=%.1f db_ms=%.1f queries=%s',
            response.status_code, total_ms, database_seconds * 1000, query_count,
        )
        return response

    return measured
