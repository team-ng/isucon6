isucon6
===

- 開催日時
  - 予選: 2016/09/17(土) or 2016/09/18(日)

- [公式ブログ](http://isucon.net/)

ー
## ツール
### sar
- インストール

```bash
$ sudo apt-get install sysstat
```
もしくは

```bash
$ sudo yum install sysstat
```

## MySQL
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


## カーネルパラメータの変更

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


## Redis or Memcached

``` 
$ cat /etc/nginx/nginx.conf
worker_processes  1;

events {
  worker_connections  10000;
}

http {
  include     mime.types;
  access_log  off;
  sendfile    on;
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

## Nginx

## 参考資料
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
