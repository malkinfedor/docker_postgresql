FROM centos:7
RUN mkdir /tmp/packages/ \
&& mkdir /tmp/packages/dependency/
RUN rpm -i http://yum.postgresql.org/9.3/redhat/rhel-7-x86_64/pgdg-centos93-9.3-3.noarch.rpm
COPY postgresql93-contrib-9.3.20-1PGDG.rhel7.x86_64.rpm postgresql93-server-9.3.20-1PGDG.rhel7.x86_64.rpm  /tmp/packages/
COPY ./dependency /tmp/packages/dependency/
COPY zabbix-server-pgsql_create.sql /zabbix-server-pgsql_create.sql 
RUN yum localinstall  /tmp/packages/dependency/* -y \
&& rm -rf /tmp/packages/dependency/ \
&& yum localinstall /tmp/packages/* -y \
&& yum localinstall /tmp/packages/postgresql93-contrib-9.3.20-1PGDG.rhel7.x86_64.rpm \
&& yum localinstall /tmp/packages/postgresql93-server-9.3.20-1PGDG.rhel7.x86_64.rpm 

RUN mkdir /opt/test_mount
### 2. Initialize DB data files
RUN su - postgres -c '/usr/pgsql-9.3/bin/initdb -D /var/lib/pgsql/9.3/data -U postgres --locale=en_US.UTF-8'

### 3. Expose database and it's port to host machine
# set permissions to allow logins, trust the bridge, this is the default for docker YMMV
RUN echo "host    all             all             172.17.42.1/16            trust" >> /var/lib/pgsql/9.3/data/pg_hba.conf
#listen on all interfaces
RUN echo "listen_addresses='*'" >> /var/lib/pgsql/9.3/data/postgresql.conf
#expose 5432
EXPOSE 5432

### 4. Creates initial empty database and database user
# Switches user executing next command
USER postgres
# Creates user and database
RUN /usr/pgsql-9.3/bin/pg_ctl -D /var/lib/pgsql/9.3/data -w start \
 && /usr/pgsql-9.3/bin/psql --command "CREATE USER zabbix WITH SUPERUSER PASSWORD 'zabbix';" \
 && /usr/pgsql-9.3/bin/createdb -O zabbix zabbix \
 && /usr/pgsql-9.3/bin/createdb -O zabbix zabbix_proxy  \
 && psql --username zabbix --dbname zabbix < /zabbix-server-pgsql_create.sql \
 && /usr/pgsql-9.3/bin/pg_ctl -D /var/lib/pgsql/9.3/data -w stop

### 5. Add VOLUMEs to allow persistence of database  
VOLUME ["/usr/pgsql-9.3", "/var/lib/pgsql/9.3/data/"]

USER root

COPY entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh

#ENTRYPOINT ["bin/sh", "entrypoint.sh"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["postgres"]

#CMD ["/usr/pgsql-9.3/bin/postgres -D /var/lib/pgsql/9.3/data -i"]

#CMD ["/usr/pgsql-9.3/bin/postgres", "-D", "/var/lib/pgsql/9.3/data", "-i"]
