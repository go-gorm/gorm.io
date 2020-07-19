---
title: 性能
layout: page
---

GORM 已经优化了许多东西来提高性能，其默认性能对大多数应用来说都够用了。但这里还是有一些关于如何为您的应用改进性能的方法。

## [禁用默认事务](transactions.html)

对于写操作（创建、更新、删除），为了确保数据的完整性，GORM 会将它们封装在事务内运行。但这会降低性能，你可以在初始化时禁用这种方式

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

## [缓存 Prepared Statement](session.html)

执行任何 SQL 时都创建 prepared statement 并缓存，可以提高后续的调用速度

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})
```

## [带 PreparedStmt 的 SQL 生成器](sql_builder.html)

在生成 SQL 方面，GORM 做了大量的改进尝试，您仍然可以在使用 GORM API（[DryRun 模式](session.html)）之前选择使用原生 SQL 或 prepare SQL, 然后用 prepared statement 执行它，例如：

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

db.Raw("select sum(age) from users where role = ?", "admin").Scan(&age)
```

## 选择字段

默认情况下，GORM 在查询时会选择所有的字段，您可以使用 `Select` 来指定您想要的字段

```go
db.Select("Name", "Age").Find(&Users{})
```

或者定义一个较小的 API 结构，使用 [智能选择字段功能](advanced_query.html)

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // 假设后面还有几百个字段...
}

type APIUser struct {
  ID   uint
  Name string
}

// 查询时会自动选择 `id`、`name` 字段
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

## [迭代、FindInBatches](advanced_query.html)

用迭代或批量进行记录的查询和处理

## [索引提示](hints.html)

[索引](indexes.html) 用于提高数据检索和 SQL 查询性能。 `索引提示` 提供了在查询处理过程中如何选择索引信息的优化器。与选择器相比，它可以更灵活地选择更有效的执行计划

```go
import "gorm.io/hints"

DB.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

DB.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"

DB.Clauses(
    hints.ForceIndex("idx_user_name", "idx_user_id").ForOrderBy(),
    hints.IgnoreIndex("idx_user_name").ForGroupBy(),
).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR ORDER BY (`idx_user_name`,`idx_user_id`) IGNORE INDEX FOR GROUP BY (`idx_user_name`)"
```
