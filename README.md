isucon6
===

- 開催日時
  - 予選: 2016/09/17(土) or 2016/09/18(日)

- [公式ブログ](http://isucon.net/)


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
innodb_buffer_pool_size=1GB
innodb_flush_log_at_trx_commit=2 // 1に設定するとトランザクション単位でログを出力するが 2 を指定すると1秒間に1回ログファイルに出力するようになる
innodb_flush_method=O_DIRECT //データファイル/ログファイルの読み書き方式を指定
```


## 参考資料
- [ISUCON4 予選問題で(中略)、”my.cnf”に1行だけ足して予選通過ラインを突破するの術](http://www.slideshare.net/kazeburo/mysql-casual7isucon)
- [コマンド一つでMysqlを速くする](http://qiita.com/kkyouhei/items/d2c40d9e3952c7049ca3)
- [MySQL innodb_flush_method = O_DIRECTの検討](http://d.hatena.ne.jp/sh2/20101205)
- [ISUCON4予選の問題で31万点を出すためにやったこと](http://qiita.com/k0kubun/items/4c4e5f2f4aeefada0a30)
