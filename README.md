Контейнер с postgresql с выполненным init скриптом для zabbix. Запуск через entrypoint.

docker run -v /opt/docker/pgdata:/var/lib/pgsql/9.3/data --name=postgresql -d -p 5432:5432 postgres_noentrypoint
