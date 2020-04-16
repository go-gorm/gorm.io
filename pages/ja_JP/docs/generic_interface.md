---
title: 一般的なデータベースインタフェース sql.DB
layout: page
---

GORMは`DB`メソッドを提供しており、一般的なデータベースインタフェース[*sql.DB](http://golang.org/pkg/database/sql/#DB)を現在の`*gorm.DB`コネクションから返します。

```go
// 一般的なデータベースオブジェクト sql.DB をその機能を利用するために取得します
db.DB()

// Ping
db.DB().Ping()
```

**NOTE** If the underlying database connection is not a `*sql.DB`, like in a transaction, it will return `nil`

## コネクションプール

```go
// SetMaxIdleConnsはアイドル状態のコネクションプール内の最大数を設定します
db.DB().SetMaxIdleConns(10)

// SetMaxOpenConnsは接続済みのデータベースコネクションの最大数を設定します
db.DB().SetMaxOpenConns(100)

// SetConnMaxLifetimeは再利用され得る最長時間を設定します
db.DB().SetConnMaxLifetime(time.Hour)
```