


## Streaming Replication設定
### standbyサーバ（ec2-postgres-2-cf）にて以下のコマンドを実行
primaryサーバにアクセスしてレプリケーションスロットを作成
```
sudo su - postgres
psql -h ec2-postgres-1-cf -U postgres
## パスワードを入力：password
select * from pg_create_physical_replication_slot('db02_repl_slot');
select slot_name, slot_type, active, wal_status from pg_replication_slots;
\q
exit
```

primaryサーバのデータコピー
```
sudo -iu postgres pg_basebackup --pgdata /var/lib/pgsql/14/data --format=p \
--write-recovery-conf --checkpoint=fast --label=mffb --progress \
--host=ec2-postgres-1-cf --port=5432 --username=repl
```

レプリケーション設定
```
cat <<EOF >> /var/lib/pgsql/14/data/postgresql.conf
# Standby
primary_conninfo = 'user=repl port=5432 host=ec2-postgres-1-cf application_name=db02.repl'
primary_slot_name = 'db02_repl_slot'
EOF
```

レプリケーション開始
```
systemctl start postgresql-14
```


## 動作確認
### primaryサーバ（ec2-postgres-1-cf）にて以下のコマンドを実行
データベースの作成とデータインサート
```
su - postgres
createuser -U postgres -d -P testuser
## パスワードを2回入力
createdb -U testuser testdb
psql -U testuser testdb
testdb=# create table test_table (id int);
testdb=# insert into test_table values (1);
testdb=# select * from test_table;
```

レプリケーション状態確認
```
\x
select * from pg_stat_replication;
```

### standbyサーバ（ec2-postgres-2-cf）にて以下のコマンドを実行
primaryサーバの情報が反映されていることを確認
```
sudo su - postgres
psql -U testuser testdb
testdb=# select * from test_table;
```

データの更新はできない
```
testdb=# insert into test_table values (2);
ERROR:  cannot execute INSERT in a read-only transaction
```

