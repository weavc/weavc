---
layout: post
title: Docker based PostgreSQL database with replica sets
tags: ['postgres', 'docker']
terms: ['docker']
icon: server
---

{% include alert.html type="warning" text="This setup works but is somewhat incomplete and not fully tested to be working with hot switching etc. These should only be used as direction and not as complete." %}

#### Docker Compose

```yaml
version: "3.8"
services:

  # Master Postgres DB
  # There should only be 1 of these 
  # located on the node with the database=master label 
  postgres:
    image: postgres
    command: "-c 'config_file=/etc/postgresql/postgresql.conf' -c 'hba_file=/etc/postgresql/pg_hba.conf'"
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_DB: deploy-examples
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - "node.labels.database==master"
    networks:
      - db-overlay
    volumes:
      - type: volume
        source: postgres-data
        target: /var/lib/postgresql/data
    configs:
      - source: 20-replication-user-setup.sh
        target: /docker-entrypoint-initdb.d/20-replication-user-setup.sh
      - source: postgresql.conf
        target: /etc/postgresql/postgresql.conf
      - source: pg-hba.conf
        target: /etc/postgresql/pg_hba.conf

  # Replica DB(s), can have multiple of these
  # Key difference is the '10-replication-restore.sh' config file and no database env variable
  pg-replica:
    image: postgres
    command: "-c 'config_file=/etc/postgresql/postgresql.conf' -c 'hba_file=/etc/postgresql/pg_hba.conf'"
    environment:
      POSTGRES_PASSWORD: password
    depends_on:
      - postgres
    deploy:
      mode: replicated
      replicas: 2
      placement:
        max_replicas_per_node: 1
        constraints:
          - "node.labels.database==replica"
    networks:
      - db-overlay
    volumes:
      - type: volume
        source: postgres-replica
        target: /var/lib/postgresql/data
    configs:
      - source: 20-replication-user-setup.sh
        target: /docker-entrypoint-initdb.d/20-replication-user-setup.sh
      - source: 10-replication-restore.sh
        target: /docker-entrypoint-initdb.d/10-replication-restore.sh
      - source: postgresql.conf
        target: /etc/postgresql/postgresql.conf
      - source: pg-hba.conf
        target: /etc/postgresql/pg_hba.conf

networks:
  db-overlay:
    driver: overlay
    name: db-overlay

configs:
  20-replication-user-setup.sh:
    file: ../configs/postgresql/20-replication-user-setup.sh
  10-replication-restore.sh:
    file: ../configs/postgresql/10-replication-restore.sh
  postgresql.conf:
    file: ../configs/postgresql/postgresql.conf
  pg-hba.conf:
    file: ../configs/postgresql/pg_hba.conf

volumes:
  postgres-data:
  postgres-replica:
```

#### Scripts

`10-replication-restore.sh`
```bash
#!/bin/bash
set -e

# this runs after setting up database etc, remove current database
rm -rf /var/lib/postgresql/data/*

# take a backup of master postgres database into our database directory
# this also creates a recovery configuration file
pg_basebackup --host postgres -D /var/lib/postgresql/data -P -U repl -Fp -R
```

`20-replication-user-setup.sh`
```
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
	CREATE USER repl WITH REPLICATION ENCRYPTED PASSWORD 'repl';
EOSQL
```

#### Configuration

`pg_hba.conf`
```
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
local   replication     all                                     trust
host    replication     all             ::1/128                 trust
host    replication     all             10.0.0.0/16             trust
host    replication     repl            10.0.0.0/16             trust
host    all             all             all                     md5
```

`postgresql.conf`
```
listen_addresses = '*'

wal_level = replica
hot_standby = on
max_wal_senders = 10
max_replication_slots = 10
hot_standby_feedback = on
```