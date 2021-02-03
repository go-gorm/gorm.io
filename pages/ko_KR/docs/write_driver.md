---
title: Write Driver
layout: page
---

## 새로운 드라이버 작성

GORM은 `sqlite`, `mysql`, `postgres`, `sqlserver`를 공식 지원합니다.

어떤 database들은 `mysql` 또는 `postgres` 방언<sup>dialect</sup>을 그냥 사용하면 될 정도의 호환성을 가지고 있기도 합니다.

그 이외에는, [the dialect interface](https://pkg.go.dev/gorm.io/gorm?tab=doc#Dialector)의 구현체를 만들어, 새로운 드라이버를 만들 수 있습니다.

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

[MySQL Driver](https://github.com/go-gorm/mysql) 예제를 참고하세요.
