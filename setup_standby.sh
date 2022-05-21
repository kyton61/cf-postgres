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
wget --tries=3 http://54.169.224.98/centos/8-stream/BaseOS/x86_64/os/Packages/libxslt-1.1.32-6.el8.x86_64.rpm
wget --tries=3 http://54.169.224.98/centos/8-stream/BaseOS/x86_64/os/Packages/lz4-1.8.3-3.el8_4.x86_64.rpm
wget --tries=3 http://54.169.224.98/centos/8-stream/BaseOS/x86_64/os/Packages/libicu-60.3-2.el8_1.x86_64.rpm
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
## postgre周辺ツール（pg_stats_reporter関連）
wget --tries=3 https://github.com/ossc-db/pg_stats_reporter/releases/download/14.0/pg_stats_reporter-14.0-1.el8.noarch.rpm
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/apr-1.6.3-12.el8.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/apr-util-openssl-1.6.1-6.el8.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/apr-util-bdb-1.6.1-6.el8.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/apr-util-1.6.1-6.el8.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/php-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/php-common-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/php-fpm-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/php-intl-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/php-cli-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/php-xml-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/php-pdo-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/php-pgsql-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/mod_http2-1.15.7-3.module_el8.4.0+778+c970deab.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/libpq-13.3-1.el8_4.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/httpd-tools-2.4.37-43.module_el8.5.0+1022+b541f3b1.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/httpd-filesystem-2.4.37-43.module_el8.5.0+1022+b541f3b1.noarch.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/httpd-2.4.37-43.module_el8.5.0+1022+b541f3b1.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/libxslt-devel-1.1.32-6.el8.x86_64.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/nginx-filesystem-1.14.1-9.module_el8.0.0+1060+3ab382d3.noarch.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/BaseOS/x86_64/os/Packages/mailcap-2.1.48-3.el8.noarch.rpm 
wget --tries=3 http://54.169.224.98/centos/8-stream/AppStream/x86_64/os/Packages/centos-logos-httpd-85.8-2.el8.noarch.rpm 


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
#rpm -ivh pg_rman-1.3.14-1.pg14.rhel8.x86_64.rpm \
#pg_hint_plan14-1.4-1.el8.x86_64.rpm \
#pg_statsinfo-14.0-1.rhel8.x86_64.rpm \
#pg_store_plans14-1.6.1-1.el8.x86_64.rpm \
#pg_bulkload-3.1.19-1.pg14.rhel8.x86_64.rpm \
#pg_repack_14-1.4.7-1.rhel8.x86_64.rpm \
#orafce_14-3.18.1-1.rhel8.x86_64.rpm
## postgre周辺ツール（pg_stats_reporter関連）
rpm -ivh pg_stats_reporter-14.0-1.el8.noarch.rpm \
apr-1.6.3-12.el8.x86_64.rpm \
apr-util-openssl-1.6.1-6.el8.x86_64.rpm \
apr-util-bdb-1.6.1-6.el8.x86_64.rpm \
apr-util-1.6.1-6.el8.x86_64.rpm \
php-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm \
php-common-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm \
php-fpm-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm \
php-intl-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm \
php-cli-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm \
php-xml-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm \
php-pdo-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm \
php-pgsql-7.2.24-1.module_el8.2.0+313+b04d0a66.x86_64.rpm \
mod_http2-1.15.7-3.module_el8.4.0+778+c970deab.x86_64.rpm \
libpq-13.3-1.el8_4.x86_64.rpm \
httpd-tools-2.4.37-43.module_el8.5.0+1022+b541f3b1.x86_64.rpm \
httpd-filesystem-2.4.37-43.module_el8.5.0+1022+b541f3b1.noarch.rpm \
httpd-2.4.37-43.module_el8.5.0+1022+b541f3b1.x86_64.rpm \
mailcap-2.1.48-3.el8.noarch.rpm \
centos-logos-httpd-85.8-2.el8.noarch.rpm \
nginx-filesystem-1.14.1-9.module_el8.0.0+1060+3ab382d3.noarch.rpm

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


# pg_rman用設定
## アーカイブディレクトリ作成
mkdir -p /var/lib/pgsql/14/arch
chmod 700 /var/lib/pgsql/14/arch
chown postgres:postgres /var/lib/pgsql/14/arch

# pg_stats_reporterの初期セットアップ
## set repository db
sed -i s/'host = dbserver01'/'host = ec2-postgres-1-cf'/g /etc/pg_stats_reporter.ini
sed -i s/';password ='/'password = password'/g /etc/pg_stats_reporter.ini
# change SELinux for DB
# https://dev.classmethod.jp/articles/redhat-selinx-might-block-network-connection-to-servers-from-apache-php/
# sudo setsebool -P httpd_can_network_connect_db=1
# sudo chcon -h system_u:httpd_sys_rw_content_t /var/www/pg_stats_reporter_lib/{cache,compiled}
sed -i s/'SELINUX=enforcing'/'SELINUX=disabled'/g /etc/selinux/config
# sudo systemctl start httpd.service
systemctl enable httpd.service
systemctl start httpd.service


# hostname設定のため再起動
shutdown -r now
