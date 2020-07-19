---
title: 编写驱动
layout: page
---

## 编写新驱动

GORM 官方支持 `sqlite`、`mysql`、`postgres`、`sqlserver`。

有些数据库可能兼容 `mysql`、`postgres` 的方言，在这种情况下，你可以直接使用这些数据库的方言。

对于其它不兼容的情况，您可以自行编写一个新驱动，这需要实现 [方言接口](https://pkg.go.dev/gorm.io/gorm?tab=doc#Dialector)。

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

查看 [MySQL 驱动](https://github.com/go-gorm/mysql) 的例子
