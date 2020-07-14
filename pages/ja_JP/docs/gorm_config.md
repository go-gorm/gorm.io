---
title: GORM Config
layout: page
---

GORMは初期化時にConfigを使用できます

```go
type Config struct {
    SkipDefaultTransaction bool
    NamingStrategy schema.Namer
    Logger logger.Interface
    NowFunc func() time.Time
    DryRun bool
    PrepareStmt bool
    DisableAutomaticPing bool
    DisableForeignKeyConstraintWhenMigrating bool
}
```

## SkipDefaultTransaction

GORMは、データの一貫性を確保するために書き込み操作(作成/更新/削除) をトランザクション内で実行します。必要でなければ、初期化時に無効にできます

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

## NamingStrategy

GORMでは、`Namer` インターフェイスを実装する必要があるデフォルトの `NamingStrategy`をオーバーライドすることで、命名規則を変更できます。

```go
type Namer interface {
    TableName(table string) string
    ColumnName(table, column string) string
    JoinTableName(table string) string
    RelationshipFKName(Relationship) string
    CheckerName(table, column string) string
    IndexName(table, column string) string
}
```

デフォルトの `NamingStrategy` も、以下のようないくつかのオプションを提供します。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NamingStrategy: schema.NamingStrategy{
    TablePrefix: "t_",   //  テーブル名のプレフィックスを指定すると、`User` のテーブルは `t_users` となります。
    SingularTable: true, // このオプションを有効にすると、`User` のテーブルは `user` になります。
  },
})
```

## ロガー

GORMのデフォルトのロガーをこのオプションでオーバーライドすることで変更できます。詳細は [ロガー](logger.html) を参照してください。

## NowFunc

新しいタイムスタンプを作成するときに使用する関数を変更します

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NowFunc: func() time.Time {
    return time.Now().Local()
  },
})
```

## DryRun

実行せずに `SQL` を生成し、SQL生成の準備やテストに使用できます。詳細は [セッション](session.html) を参照してください。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DryRun: false,
})
```

## PrepareStmt

`PreparedStmt` は任意の SQL を実行するときに用意されたステートメントを作成し、将来の呼び出しを高速化するためにキャッシュします。詳細は [セッション](session.html) を参照してください。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: false,
})
```

## DisableAutomaticPing

GORMはデータベースの可用性をチェックするために初期化後に自動的にデータベースをpingします。 `true`に設定して無効にできます

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableAutomaticPing: true,
})
```

## DisableForeignKeyConstraintWhenMigrating

GORMは、`AutoMigrate`または`CreateTable`のときにデータベースの外部キー制約を自動的に作成します。これを`true`に設定して無効できます。詳細については、[マイグレーション](migration.html)を参照してください。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```
