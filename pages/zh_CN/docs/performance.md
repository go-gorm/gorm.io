---
title: 性能
layout: page
---

GORM optimizes many things to improve the performance, the default performance should be good for most applications, but there are still some tips for how to improve it for your application.

## [禁用默认事务](transactions.html)

GORM performs write (create/update/delete) operations inside a transaction to ensure data consistency, which is bad for performance, you can disable it during initialization

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

## [缓存预编译语句](session.html)

执行任何 SQL 时都创建并缓存预编译语句，可以提高后续的调用速度

```go
// 全局模式
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

// 会话模式
tx := db.Session(&Session{PrepareStmt: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)
```

{% note warn %}
**注意** 也可以参考如何为 MySQL 开启 interpolateparams 以减少 roundtrip https://github.com/go-sql-driver/mysql#interpolateparams
{% endnote %}

### [带 PreparedStmt 的 SQL 生成器](sql_builder.html)

Prepared Statement 也可以和原生 SQL 一起使用，例如：

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: true,
})

db.Raw("select sum(age) from users where role = ?", "admin").Scan(&age)
```

您也可以使用 GORM 的 API [DryRun 模式](session.html) 编写 SQL 并执行 prepared statement ，查看 [会话模式](session.html) 获取详情

## 选择字段

默认情况下，GORM 在查询时会选择所有的字段，您可以使用 `Select` 来指定您想要的字段

```go
db.Select("Name", "Age").Find(&Users{})
```

或者定义一个较小的 API 结构体，使用 [智能选择字段功能](advanced_query.html)

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

用迭代或 in batches 查询并处理记录

## [Index Hints](hints.html)

[Index](indexes.html) 用于提高数据检索和 SQL 查询性能。 `Index Hints` 向优化器提供了在查询处理过程中如何选择索引的信息。与 optimizer 相比，它可以更灵活地选择更有效的执行计划

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"

db.Clauses(
    hints.ForceIndex("idx_user_name", "idx_user_id").ForOrderBy(),
    hints.IgnoreIndex("idx_user_name").ForGroupBy(),
).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR ORDER BY (`idx_user_name`,`idx_user_id`) IGNORE INDEX FOR GROUP BY (`idx_user_name`)"
```

## 读写分离

通过读写分离提高数据吞吐量，查看 [Database Resolver](dbresolver.html) 获取详情
