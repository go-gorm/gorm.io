---
title: GORM 配置
layout: page
---

GORM 提供的配置可以在初始化时使用

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

## 跳过默认事务

为了确保数据一致性，GORM 会在事务里执行写入操作（创建、更新、删除）。如果没有这方面的要求，您可以在初始化时禁用它。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

## 命名策略

GORM 允许用户通过覆盖默认的`命名策略`更改默认的命名约定，这需要实现接口 `Namer`

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

默认 `NamingStrategy` 也提供了几个选项，如：

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NamingStrategy: schema.NamingStrategy{
    TablePrefix: "t_",   // 表名前缀，`User` 的表名应该是 `t_users`
    SingularTable: true, // 使用单数表名，启用该选项，此时，`User` 的表名应该是 `t_user`
  },
})
```

## Logger

允许通过覆盖此选项更改 GORM 的默认 logger，参考 [Logger](logger.html) 获取详情

## NowFunc

更改创建时间使用的函数

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NowFunc: func() time.Time {
    return time.Now().Local()
  },
})
```

## DryRun

生成 `SQL` 但不执行，可以用于准备或测试生成的 SQL，参考 [会话](session.html) 获取详情

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DryRun: false,
})
```

## PrepareStmt

`PreparedStmt` creates a prepared statement when executing any SQL and caches them to speed up future calls, refer [Session](session.html) for details

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: false,
})
```

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
