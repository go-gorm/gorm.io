---
title: Escrever um Driver
layout: page
---

## Escreva um novo driver

O GORM tem suporte oficial para `sqlite`, `mysql`, `postgres`, `sqlserver`.

Some databases may be compatible with the `mysql` or `postgres` dialect, in which case you could just use the dialect for those databases.

For others, you can create a new driver, it needs to implement [the dialect interface](https://pkg.go.dev/gorm.io/gorm?tab=doc#Dialector).

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

Checkout the [MySQL Driver](https://github.com/go-gorm/mysql) as example
