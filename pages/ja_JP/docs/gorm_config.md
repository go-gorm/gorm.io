---
title: GORM Config
layout: page
---

GORMは初期化時にConfigを使用できます

```go
type Config struct {
  SkipDefaultTransaction bool
  NamingStrategy         schema.Namer
  Logger                 logger.Interface
  NowFunc                func() time.Time
  DryRun                 bool
  PrepareStmt            bool
  AllowGlobalUpdate      bool
  DisableAutomaticPing   bool
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

## <span id="naming_strategy">NamingStrategy</span>

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

Allow to change GORM's default logger by overriding this option, refer [Logger](logger.html) for more details

## <span id="now_func">NowFunc</span>

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

## AllowGlobalUpdate

Enable global update/delete, refer [Session](session.html) for details

## DisableAutomaticPing

GORM automatically ping database after initialized to check database availability, disable it by setting it to `true`

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableAutomaticPing: true,
})
```

## DisableForeignKeyConstraintWhenMigrating

GORM creates database foreign key constraints automatically when `AutoMigrate` or `CreateTable`, disable this by setting it to `true`, refer [Migration](migration.html) for details

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```
