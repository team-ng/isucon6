isucon6
===

- 開催日時
  - 予選: 2016/09/17(土) or 2016/09/18(日)

- [公式ブログ](http://isucon.net/)


## プロファイリング
### w
- 他にログインしている人がいるか確認

### uptime
- サーバの稼働時間確認


### ps auxf
- プロセスツリーを見る
- ``--sort``オプションでソートして表示できる

``` bash
$ ps auxf --sort -cpu
```

### ip a
- NICやIPアドレスの確認


### df -Th
- ファイルシステムの確認
- ``-h``: ヒューマンリーダブル
- ``-T``:ファイルシステムの種別表示


### iostat -dx 5
- ディスクI/Oの確認
- ``-d``でインターバル指定
- ``-x``で表示する情報を拡張


### netstat -tnl
- ネットワーク情報の表示
- ``-t``:tcp接続情報の表示
- ``-n``:名前解決せずIPアドレスで表示
- ``-l``: LISTENしているポート一覧
- ``-a``:すべてのステートを見る
- ``-o``:タイマー情報
- ``-p``:プロセス名の表示 root権限が必要

``` bash
$ sudo netstat -tanop
```


### sar
OSが報告する各種指標を参照する

- インストール

```bash
$ sudo apt-get install sysstat
```
もしくは

```bash
$ sudo yum install sysstat
```

- 過去のデータを見る
  - ``-f``でログファイルを指定する

``` bash
$ sar -f /var/log/sa/sa04
```

- 現在のデータを見る
  - 1秒ごとに100回

``` bash
$ sar 1 100
```



- cpu 情報を表示する

``` bash
$ sar -u
```


- ロードアベレージを見る

``` bash
$ sar -q
```


- メモリ使用状況を見る

``` bash
$ sar -r
```

- スワップ発生状況を見る

``` bash
$ sar -W
```

### top -c
- ``-c``で引数の情報も表示
- top コマンドを起動してから ``"M"(大文字) ``を入力すると消費メモリの順に表示される
- top コマンドを起動してから ``1``を入力するとCPUコアの使用率を個別で表示


### スロークエリログ解析
スロークエリログを吐く

- コマンドで実行する場合

``` bash
mysql> set global slow_query_log = 1;
mysql> set global long_query_time = 0;
mysql> set global slow_query_log_file = "/tm/slow.log";
```

- ファイルに設定する場合

``` 
slow_query_log                = 1
slow_query_log_file           = /var/lib/mysql/mysqld-slow.log 
long_query_time               = 0 
log-queries-not-using-indexes = 1
```


解析する

- **pt-query-digest**を使う

インストール

```bash
$ yum localinstall -y http://percona.com/get/percona-toolkit.rpm
```

集計
  
```bash
$ pt-query-digest /tmp/slow.log > /tmp/digest.txt
```

- 件数制限
``--limit 50``

- index効いてないやつだけ出力
``--filter '($event->{No_index_used} eq "Yes" || $event->{No_good_index_used} eq "Yes")'``





## チューニング
### MySQL
- my.cnfの場所を調べる

``` bash
$ mysql --help | grep my.cnf
```

- my.cnfに設定追加

``` bash
innodb_buffer_pool_size=1GB // インスタンスのメモリサイズを超えるとエラーになるので注意
innodb_flush_log_at_trx_commit=2 // 1に設定するとトランザクション単位でログを出力するが 2 を指定すると1秒間に1回ログファイルに出力するようになる
innodb_flush_method=O_DIRECT //データファイル/ログファイルの読み書き方式を指定
```

- トランザクションログファイル削除
  - 既にトランザクションログファイルが存在していて、innodb_log_file_sizeの設定の値の方が大きい場合、エラーとなってしまうというとこがあるため

``` bsah
rm /var/lib/mysql/ib_logfile0
rm /var/lib/mysql/ib_logfile1
```


- データサイズ確認

``` bash
mysql > use データベース名;
mysql > SELECT table_name, engine, table_rows, avg_row_length, floor((data_length+index_length)/1024/1024) as allMB, floor((data_length)/1024/1024) as dMB, floor((index_length)/1024/1024) as iMB FROM information_schema.tables WHERE table_schema=database() ORDER BY (data_length+index_length) DESC;
```


- インデックス追加

``` sql
ALTER TABLE テーブル名 ADD INDEX インデックス名(カラム名);
```

``` bsah
cat <<'EOF' | mysql -h ${myhost} -P ${myport} -u ${myuser} ${mydb}
alter table login_log add index ip (ip), add index user_id (user_id);
EOF
```


### カーネルパラメータの変更

``` bash
$ emacs /etc/sysctl.conf
```

- 以下を追記

``` 
net.ipv4.tcp_max_tw_buckets = 2000000 //  システムが同時に保持する time-wait ソケットの最大数。この数を越えると、time-wait ソケットは直ちに破棄され、警告が表示されます。この制限は単純な DoS 攻撃を防ぐためにあります。わざと制限を小さくしてはいけません。ネットワークの状況によって必要な場合は、 (できればメモリを追加してから) デフォルトより増やすのはかまいません。
net.ipv4.ip_local_port_range = 10000 65000 //ローカルポートとして利用できるアドレスの範囲 デフォルトだと28232 個なので増やす。ポートが足りなくなるとポートのどれかが解放されるまで新しいコネクションを確立できなくなる
net.core.somaxconn = 32768 // TCPソケットが受け付けた接続要求を格納するキューの最大長
net.core.netdev_max_backlog = 8192 // カーネルがキューイング可能なパケットの最大個数
net.ipv4.tcp_tw_reuse = 1 // TIME_OUT 状態のコネクションを再利用 (1使いまわす、0使いまわさない)
net.ipv4.tcp_fin_timeout = 10 // TCPの終了待ちタイムアウト秒数を設定(default 60)
```

- 適用する

``` bash
$ sudo /sbin/sysctl -p
```

### Nginx

``` 
$ cat /etc/nginx/nginx.conf
#Nginxがシングルスレッドで動作するため、コア数に合わせて設定しておく。コア数の確認は``grep processor /proc/cpuinfo | wc -l``
worker_processes  auto; 

events {
  #最大接続数を増やす。デフォルト1024
  worker_connections  10000; 
}

http {
  include     mime.types; // MIMEタイプと拡張子の関連付けを定義したファイルを読み込み
  access_log  off;
  sendfile    on; // OSが提供しているsendfileを使用するかどうか。
  tcp_nopush  on;
  tcp_nodelay on;
  etag        off;
  upstream app {
    server unix:/dev/shm/app.sock;
  }

  server {
    location / {
      proxy_pass http://app;
    }
    location ~ ^/(stylesheets|images)/ {
      open_file_cache max=100;
      root /home/isucon/webapp/public;
    }
  }
}

```


## その他
### systemctl
- 有効化されているUnitの一覧表示

``` bash
$ systemctl list-units
```

- インストールされているUnitファイルの一覧表示(

``` bash
$ systemctl list-unit-files
```

- Unitの有効化(enable)
  - 有効化すると、システム起動時に立ち上がるサービスとして登録される = ``chkconfig on``
  
``` bash
$ sudo systemctl enable ユニット名
```

- Unitの有効/無効の確認(is-enable)

``` bash
$ sudo systemctl is-enable ユニット名
```


- 起動状態確認

``` bash
$ systemctl status ユニット名
```

- 起動
``` bash
$ systemctl start ユニット名
```

- 終了
``` bash
$ systemctl stop ユニット名
```


### 自作コマンドをサービス化
- ``/etc/systemd/system/``の下にUnit定義ファイルを作る

``` bash
$ sudo emacs /etc/systemd/system/hello.service
```

- 定義ファイル
  - ``Restart = always``はプロセスやサーバが不意に落ちた時に自動再起動するモード
  
``` 
[Unit]
Description = hello daemon

[Service]
ExecStart = /opt/hello.sh
Restart = always
Type = simple

[Install]
WantedBy = multi-user.target
```

- UnitがServiceとして認識されたか確認する

```bash
$ sudo systemctl list-unit-files --type=service | grep hello
```

- enableしてstartする


### ubuntuバージョン確認

``` bash
$ cat /etc/lsb-release
```

### cpu情報

``` bash
$ cat /proc/cpuinfo 
```


### MySQL
- インストール

``` bash
$ sudo apt update
$ sudo apt upgrade
$ sudo apt install mysql-server mysql-client
```

- 起動
  - **mysqld**じゃないことに注意

``` bash
$ sudo systemctl start mysql
```

- 終了

``` bash
$ sudo systemctl stop mysql
```


## 参考資料
- [ISUCON予選突破を支えたオペレーション技術](http://blog.yuuk.io/entry/web-operations-isucon)
- [ISUCON4 予選問題で(中略)、”my.cnf”に1行だけ足して予選通過ラインを突破するの術](http://www.slideshare.net/kazeburo/mysql-casual7isucon)
- [コマンド一つでMysqlを速くする](http://qiita.com/kkyouhei/items/d2c40d9e3952c7049ca3)
- [MySQL innodb_flush_method = O_DIRECTの検討](http://d.hatena.ne.jp/sh2/20101205)
- [ISUCON4予選の問題で31万点を出すためにやったこと](http://qiita.com/k0kubun/items/4c4e5f2f4aeefada0a30)
- [MySQLの「innodb_buffer_pool_size」と「innodb_log_file_size」の設定](http://blog.flatlabs.net/20100727_212649/)
- [ISUCON4 予選でアプリケーションを変更せずに予選通過ラインを突破するの術](http://kazeburo.hatenablog.com/entry/2014/10/14/170129)
- [tcp_tw_なんとかの違い](http://qiita.com/smallpalace/items/b0b351cebc453287e10e)
- [ぜんぶTIME_WAITのせいだ！](http://qiita.com/kuni-nakaji/items/c07004c7d9e5bb683bc2)
- [kernel: TCP: time wait bucket table overflow の解消とTIME_WAITを減らすチューニング](http://oopsops.hatenablog.com/entry/2012/03/29/202433)
- [ローカルポートを食いつぶしていた話](http://d.hatena.ne.jp/download_takeshi/20091013/1255443592)
- [nginx - カーネルパラメーターのチューニング](http://qiita.com/sion_cojp/items/c02b5b5586b48eaaa469)
- [Nginx設定のまとめ](http://qiita.com/syou007/items/3e2d410bbe65a364b603)
- [プロセス毎のメモリ消費量を調べたい時に使えるコマンド](http://qiita.com/white_aspara25/items/cfc835006ae356189df3)
- [はじめてのsystemdサービス管理ガイド](http://dev.classmethod.jp/cloud/aws/service-control-use-systemd/)
