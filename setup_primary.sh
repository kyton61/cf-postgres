#!/bin/bash
# timezoneの設定
timedatectl set-timezone Asia/Tokyo

# hostsの設定 
cat <<EOF | sudo tee -a /etc/hosts
10.5.10.11 ec2-postgres-1-cf
10.5.10.12 ec2-postgres-2-cf
EOF

# PostgreSQL14.0初期セットアップ

# 必要パッケージをdnfでインストール
dnf install -y perl-libs # perl-libs is needed by postgresql-contrib 


# その他postgreとその周辺ツールのrpmをダウンロード
## postgre本体で必要なパッケージ
wget --tries=3 http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/libxslt-1.1.32-6.el8.x86_64.rpm
wget --tries=3 http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/lz4-1.8.3-3.el8_4.x86_64.rpm
wget --tries=3 http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/libicu-60.3-2.el8_1.x86_64.rpm
## postgre本体
wget --tries=3 https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-8.4-x86_64/postgresql14-14.0-1PGDG.rhel8.x86_64.rpm
wget --tries=3 https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-8.4-x86_64/postgresql14-server-14.0-1PGDG.rhel8.x86_64.rpm
wget --tries=3 https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-8.4-x86_64/postgresql14-docs-14.0-1PGDG.rhel8.x86_64.rpm
wget --tries=3 https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-8.4-x86_64/postgresql14-libs-14.0-1PGDG.rhel8.x86_64.rpm
wget --tries=3 https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-8.4-x86_64/postgresql14-contrib-14.0-1PGDG.rhel8.x86_64.rpm
## postgre周辺ツール
wget --tries=3 https://github.com/ossc-db/pg_rman/releases/download/V1.3.14/pg_rman-1.3.14-1.pg14.rhel8.x86_64.rpm
wget --tries=3 https://github.com/ossc-db/pg_hint_plan/releases/download/REL14_1_4_0/pg_hint_plan14-1.4-1.el8.x86_64.rpm
wget --tries=3 https://github.com/ossc-db/pg_statsinfo/releases/download/14.0/pg_statsinfo-14.0-1.rhel8.x86_64.rpm
wget --tries=3 https://github.com/ossc-db/pg_store_plans/releases/download/1.6.1/pg_store_plans14-1.6.1-1.el8.x86_64.rpm
wget --tries=3 https://github.com/ossc-db/pg_bulkload/releases/download/VERSION3_1_19/pg_bulkload-3.1.19-1.pg14.rhel8.x86_64.rpm
wget --tries=3 https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-8.4-x86_64/pg_repack_14-1.4.7-1.rhel8.x86_64.rpm
wget --tries=3 https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-8-x86_64/orafce_14-3.18.1-1.rhel8.x86_64.rpm


# postgreと周辺ツールのインストール
## postgre本体で必要なパッケージ
## postgre本体
rpm -ivh libxslt-1.1.32-6.el8.x86_64.rpm \
lz4-1.8.3-3.el8_4.x86_64.rpm \
libicu-60.3-2.el8_1.x86_64.rpm \
postgresql14-14.0-1PGDG.rhel8.x86_64.rpm \
postgresql14-server-14.0-1PGDG.rhel8.x86_64.rpm \
postgresql14-docs-14.0-1PGDG.rhel8.x86_64.rpm \
postgresql14-libs-14.0-1PGDG.rhel8.x86_64.rpm \
postgresql14-contrib-14.0-1PGDG.rhel8.x86_64.rpm
## postgre周辺ツール
rpm -ivh pg_rman-1.3.14-1.pg14.rhel8.x86_64.rpm \
pg_hint_plan14-1.4-1.el8.x86_64.rpm \
pg_statsinfo-14.0-1.rhel8.x86_64.rpm \
pg_store_plans14-1.6.1-1.el8.x86_64.rpm \
pg_bulkload-3.1.19-1.pg14.rhel8.x86_64.rpm \
pg_repack_14-1.4.7-1.rhel8.x86_64.rpm \
orafce_14-3.18.1-1.rhel8.x86_64.rpm



# postgre本体の初期セットアップ
# set bin command path 
sudo -iu postgres echo "export PATH=$PATH:/usr/pgsql-14/bin/" >> /var/lib/pgsql/.pgsql_profile
## ロケールなし、エンコーディングはUTF-8
sudo -iu postgres initdb --no-locale --encoding=utf-8
## TODO:クラスタDBディレクトリの指定する
systemctl enable postgresql-14
systemctl start postgresql-14
# set PostgreSQL admin user's password 
sudo -iu postgres psql -c "alter user postgres with password 'password'" 
# Enabling remote Database connections 
echo "listen_addresses = '*'" >> /var/lib/pgsql/14/data/postgresql.conf 
# Accept from anywhere (not recommended) 
echo "host all all 0.0.0.0/0 md5" >> /var/lib/pgsql/14/data/pg_hba.conf 
# Restart the database service after saving the changes 
systemctl restart postgresql-14



# pg_statsinfo/pg_store_plansの初期セットアップ
## Set postgresql.conf
cat <<EOF >> /var/lib/pgsql/14/data/postgresql.conf
# 推奨設定
shared_preload_libraries = 'pg_statsinfo,pg_stat_statements,pg_store_plans'
# 事前ロードを行う。
# クエリ統計取得のためpg_stat_statements追加
# クエリ実行計画取得のためpg_store_plans追加
track_counts = 'on'                             # データベースの活動に関する統計情報の取集設定
track_activities = 'on'                         # セッションで実行中のコマンドに関する情報収集
pg_statsinfo.repository_server = 'host=ec2-postgres-2-cf port=5432 user=postgres dbname=postgres' 
                                                # スナップショットの保存先
pg_statsinfo.snapshot_interval = 1min          # スナップショットの取得間隔
pg_statsinfo.enable_maintenance = 'on'          # 自動メンテナンス設定
pg_statsinfo.maintenance_time = '00:02:00'      # 自動メンテナンス実行時刻設定
pg_statsinfo.repolog_min_messages = disable     # ログ蓄積機能の設定
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log' # ログファイル名を指定する
log_min_messages = 'log'                        # ログへ出力するメッセージレベル。
pg_statsinfo.syslog_min_messages = 'error'      # syslogに出力するログレベルを指定する。
pg_statsinfo.textlog_line_prefix = '%t %p %c-%l %x %q(%u, %d, %r, %a) '
   # pg_statsinfoがテキストログに出力する際、各行の先頭に追加される書式を指定する。log_line_prefixと同じ形式で指定する。
pg_statsinfo.syslog_line_prefix = '%t %p %c-%l %x %q(%u, %d, %r, %a) '
   # pg_statsinfoがsyslog経由でログを出力する際、各行の先頭に追加される書式を指定する。
track_functions = 'all'                         # ストアドプロシージャの呼び出しに関する統計情報を収集する
log_checkpoints = on                            # チェックポイントを記録
log_autovacuum_min_duration = 0                 # 自動バキュームを記録
#pg_statsinfo.long_lock_threshold = 30s         # ロック競合情報に記録する対象の条件(閾値)を指定する
EOF
## set pg_hba.conf
sed -i '1s/^/local   all             postgres                                ident\n/' /var/lib/pgsql/14/data/pg_hba.conf  




## 追加ライブラリ読み込み
sudo -iu postgres psql -d postgres -c "CREATE EXTENSION pg_stat_statements"
sudo -iu postgres psql -d postgres -c "CREATE EXTENSION pg_store_plans"

# パスワードファイル作成
sudo -iu postgres touch /var/lib/pgsql/.pgpass
sudo -iu postgres echo "ec2-postgres-2-cf:5432:postgres:postgres:password" > /var/lib/pgsql/.pgpass
chmod 600 /var/lib/pgsql/.pgpass


# change SELinux for DB
# https://dev.classmethod.jp/articles/redhat-selinx-might-block-network-connection-to-servers-from-apache-php/ 
sed -i s/'SELINUX=enforcing'/'SELINUX=disabled'/g /etc/selinux/config


# hostname設定のため再起動
shutdown -r now
