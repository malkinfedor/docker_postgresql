#!/bin/sh

chown -R postgres: /var/lib/pgsql/9.3/data
chmod 0700 -R /var/lib/pgsql/9.3/data
if [ "$1" = 'postgres' ]; then
   runuser -u postgres  -- /usr/pgsql-9.3/bin/postgres -D /var/lib/pgsql/9.3/data -i 
else 
   exec "$@" 
fi

