---
title: GORM Config
layout: page
---

GORMは初期化時にConfigを使用できます

```go
type Config struct {
  SkipDefaultTransaction   bool
  NamingStrategy           schema.Namer
  Logger                   logger.Interface
  NowFunc                  func() time.Time
  DryRun                   bool
  PrepareStmt              bool
  DisableNestedTransaction bool
  AllowGlobalUpdate        bool
  DisableAutomaticPing     bool
  DisableForeignKeyConstraintWhenMigrating bool
}
```

## デフォルトトランザクションを無効にする

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
    SchemaName(table string) string
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
    TablePrefix: "t_",   // table name prefix, table for `User` would be `t_users`
    SingularTable: true, // use singular table name, table for `User` would be `user` with this option enabled
    NoLowerCase: true, // skip the snake_casing of names
    NameReplacer: strings.NewReplacer("CID", "Cid"), // use name replacer to change struct/field name before convert it to db name
  },
})
```

## Logger

オプションをオーバーライドすることで、GORMのデフォルトのLoggerを変更できます。詳細は [Logger](logger.html) を参照してください。

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

## トランザクションのネストを無効にする

トランザクション内で `Transaction` メソッドを使用した場合、GORMは `SavePoint(savedPointName)`, `RollbackTo(savedPointName)` を利用してトランザクションのネストをサポートしています。これを無効にするには、`DisableNestedTransaction` オプションを利用します。詳細については、[Session](session.html) を参照してください。


## Global Updateを有効にする

Global update/deleteを有効にすることが可能です。詳細は [Session](session.html) を参照してください。

## 自動の Ping を無効にする

GORMはデータベースの可用性をチェックするため、初期化後に自動でデータベースに ping を行います。以下の設定を `true` に設定してすることでこれを無効にできます。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableAutomaticPing: true,
})
```

## マイグレーション時の外部キー制約を無効にする

GORMは、`AutoMigrate` または `CreateTable` 実行時にデータベースの外部キー制約を自動的に作成します。以下の設定を `true` に設定することでこれを無効できます。詳細については、[マイグレーション](migration.html)を参照してください。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```
