--query the uptime

select age(pg_postmaster_start_time());

           age

-------------------------

 12 days 14:36:16.396809

(1 row)




-- query the replication lag

SELECT CASE WHEN pg_last_xlog_receive_location() = pg_last_xlog_replay_location() THEN 0

       ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp()) END

       AS replication_lag;
