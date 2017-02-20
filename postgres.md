## Streaming replication setup

### Master

```bash
export PGHOME=/opt/sql
export PGDATA =~/data
```

postgresql.conf
```
wal_level = hot_standby
#synchronous_commit = on
checkpoint_timeout = 5min
archive_mode = on
archive_command = '/bin/date'
max_wal_senders = 2
wal_keep_segments = 16
hot_standby = on
max_standby_archive_delay = 300s
max_standby_streaming_delay = 30s
wal_receiver_status_interval = 1s
hot_standby_feedback = on
wal_receiver_timeout = 60s
```

pg_hba.conf

```
host all all 127.0.0.1/32 trust
host all all 0.0.0.0/0 trust
host replication repuser 192.168.1.200/32 md5
```



### Slave

```bash
export PGHOME=/opt/sql
export PGDATA = ~/standby

```

```bash
# create pg pass file

cd && vi  .pgpass
192.168.1.189:5432:replication:repuser:123

chmod 600 .pgpass

cd && rm -rf standby

## basebackup
pg_basebackup -F p -D $PGDATA -h 192.168.1.189 -p 5432 -U repuser

```

postgresql.conf

```
standby_mode = on
primary_conninfo = 'host=192.168.1.189  port=5432  user=repuser'
trigger_file = '/home/postgres/standby/postgresql.trigger.5432'
```


## Master / Slave Switchover

```sql
select usename,application_name,client_addr,state,sent_location,replay_location,sync_state from pg_stat_replication;

 usename | application_name | client_addr  |   state   | sent_location | replay_location | sync_state

---------+------------------+--------------+-----------+---------------+-----------------+------------

 rep     | walreceiver      | 172.20.0.250 | streaming | 0/16101658    | 0/16101658      | sync       

(1 row)
```


recovery.conf in Slave

```
standby_mode = 'on'

primary_slot_name = 'rep_slot_1'

primary_conninfo = 'host=172.20.0.245 port=5432 user=rep password=repl keepalives_idle=60'

trigger_file = '/u02/pgdata/data/postgresql.trigger.5432'
```

postgresql.conf in Master

```
#synchronous_standby_names = '*'# standby servers that provide sync rep

                                # comma-separated list of application_name

                                # from standby(s); '*' = all

```


changed to asynchronized from synchronized

```sql
select usename,application_name,client_addr,state,sent_location,replay_location,sync_state from pg_stat_replication;

 usename | application_name | client_addr  |   state   | sent_location | replay_location | sync_state

---------+------------------+--------------+-----------+---------------+-----------------+------------

 rep     | walreceiver      | 172.20.0.250 | streaming | 0/170000C8    | 0/170000C8      | async

(1 row)
```


when slave is down

```sql
select usename,application_name,client_addr,state,sent_location,replay_location,sync_state from pg_stat_replication;

 usename | application_name | client_addr | state | sent_location | replay_location | sync_state

---------+------------------+-------------+-------+---------------+-----------------+------------

(0 rows)
```

when slave is up again

```sql
select usename,application_name,client_addr,state,sent_location,replay_location,sync_state from pg_stat_replication;

 usename | application_name | client_addr  |   state   | sent_location | replay_location | sync_state

---------+------------------+--------------+-----------+---------------+-----------------+------------

 rep     | walreceiver      | 172.20.0.250 | streaming | 0/17000680    | 0/17000680      | async

(1 row)
```

## Misc

Trigger / rule based replication

session_replication_role(enum) to distinguish the current database role:
	origin
	replica
