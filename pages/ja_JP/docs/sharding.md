---
title: Sharding
layout: page
---

シャーディングプラグインは、巨大なテーブルを小さいテーブルに分割し、シャーディングテーブルにクエリをリダイレクトするために、SQLパーサーを使用してクエリを置き換えます。 高パフォーマンスなデータベースアクセスが可能となります。

https://github.com/go-gorm/sharding

## 特徴

- シンプルなデザイン。 プラグインをロードして設定を指定するだけで使用できます。
- 高速な動作。 Goと同じくらい速く、ネットワークに依存しないミドルウェア。
- Multiple database (PostgreSQL, MySQL) support.
- Integrated primary key generator (Snowflake, PostgreSQL Sequence, Custom, ...).

## 使用方法

シャーディングミドルウェアを設定し、シャーディング対象のテーブルを登録します。 See [Godoc](https://pkg.go.dev/gorm.io/sharding) for config details.

```go
import (
    "fmt"

    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/sharding"
)

db, err := gorm.Open(postgres.New(postgres.Config{DSN: "postgres://localhost:5432/sharding-db?sslmode=disable"))

db.Use(sharding.Register(sharding.Config{
    ShardingKey:         "user_id",
    NumberOfShards:      64,
    PrimaryKeyGenerator: sharding.PKSnowflake,
}, "orders", Notification{}, AuditLog{}))
// This case for show up give notifications, audit_logs table use same sharding rule.
```

通常通りdbセッションを使用します。 シャーディング対象のテーブルを操作する場合は、クエリに `Sharding Key` を持つ必要があることに注意してください。

```go
// GORMでのレコード作成例。この場合 orders_02 にレコードが挿入されます。
db.Create(&Order{UserID: 2})
// sql: INSERT INTO orders_02 ...

// 素のSQLでのinsert。この場合 orders_03 にレコードが挿入されます。
db.Exec("INSERT INTO orders(user_id) VALUES(?)", int64(3))

// シャーディングキーがないため、これは ErrMissingShardingKey エラーが発生します。
db.Create(&Order{Amount: 10, ProductID: 100})
fmt.Println(err)

// Findの場合です。これは orders_02 にクエリがリダイレクトされます。
var orders []Order
db.Model(&Order{}).Where("user_id", int64(2)).Find(&orders)
fmt.Printf("%#v\n", orders)

// 素のSQLでの取得もサポートされています。
db.Raw("SELECT * FROM orders WHERE user_id = ?", int64(3)).Scan(&orders)
fmt.Printf("%#v\n", orders)

// WHERE条件にシャーディングキーが含まれていないため、これは ErrMissingShardingKey エラーが発生します。
err = db.Model(&Order{}).Where("product_id", "1").Find(&orders).Error
fmt.Println(err)

// Update と Delete は作成や取得時と同様です
db.Exec("UPDATE orders SET product_id = ? WHERE user_id = ?", 2, int64(3))
err = db.Exec("DELETE FROM orders WHERE product_id = 3").Error
fmt.Println(err) // ErrMissingShardingKey
```

より詳細な例は [こちら](https://github.com/go-gorm/sharding/tree/main/examples) にあります。
