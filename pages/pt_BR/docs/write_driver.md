---
title: Escrever um Driver
layout: page
---

## Escreva um novo driver

O GORM tem suporte oficial para `sqlite`, `mysql`, `postgres`, `sqlserver`.

Alguns bancos de dados podem ser compatíveis com o dialeto do `mysql` ou `postgres`, nesse caso seria possível usar o dialeto para essas bases de dados.

Para outros, você pode escrever um novo driver, ele precisa implementar [a interface de dialeto](https://pkg.go.dev/gorm.io/gorm?tab=doc#Dialector).

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

Consulte o [Driver do MySQL](https://github.com/go-gorm/mysql) como exemplo
