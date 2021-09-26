---
title: 一般的なデータベースインターフェース sql.DB
layout: page
---

GORMは、`DB` メソッドを定義しています。これは `*gorm.DB` から、汎用的なDB操作のインターフェイスである `*sql.DB` を返却します。

```go
// 汎用データベースオブジェクトの sql.DB を取得する
sqlDB, err := db.DB()

// Ping
sqlDB.Ping()

// Close
sqlDB.Close()

// データベースの統計を返却する
sqlDB.Stats()
```

{% note warn %}
**注意** トランザクション内のような、基盤となるデータベース接続が `*sql.DB`でない場合、DBメソッドはエラーを返します。
{% endnote %}

## コネクションプール

```go
// Get generic database object sql.DB to use its functions
sqlDB, err := db.DB()

// SetMaxIdleConns sets the maximum number of connections in the idle connection pool.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns sets the maximum number of open connections to the database.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime sets the maximum amount of time a connection may be reused.
sqlDB.SetConnMaxLifetime(time.Hour)
```
