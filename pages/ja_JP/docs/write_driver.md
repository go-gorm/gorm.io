---
title: ドライバの作成
layout: page
---

## 新しいドライバを作成する

GORMは `sqlite`, `mysql`, `postgres`, `sqlserver` を公式にサポートしています。

いくつかのデータベースは `mysql` または `postgres` と互換性があります。 互換性がある場合は、それらのデータベース固有の文法を使用することができます。

上記以外のデータベース使用する場合、新しいドライバを作成することができます。ドライバの作成には [Dialector](https://pkg.go.dev/gorm.io/gorm?tab=doc#Dialector) インターフェイスを実装する必要があります。

```go
type Dialector interface {
    Name() string
    Initialize(*DB) error
    Migrator(db *DB) Migrator
    DataTypeOf(*schema.Field) string
    DefaultValueOf(*schema.Field) clause.Expression
    BindVarTo(writer clause.Writer, stmt *Statement, v interface{})
    QuoteTo(clause.Writer, string)
    Explain(sql string, vars ...interface{}) string
}
```

例として [MySQL Driver](https://github.com/go-gorm/mysql) を確認してみると良いでしょう。
