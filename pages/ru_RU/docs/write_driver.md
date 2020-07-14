---
title: Написание нового драйвера
layout: страница
---

## Написание нового драйвера

GORM предоставляет официальную поддержку `sqlite`, `mysql`, `postgres`, `sqlserver`.

Некоторые базы данных могут быть совместимы с `mysql` или `postgres` диалектами, в этом случае можно просто использовать диалект для этих баз данных.

Для других вы можете создать новый драйвер, он должен реализовывать [интерфейс диалекта](https://pkg.go.dev/gorm.io/gorm?tab=doc#Dialector).

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

Смотрите [Драйвер MySQL](https://github.com/go-gorm/mysql) в качестве примера
