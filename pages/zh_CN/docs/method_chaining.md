---
title: 链式方法
layout: page
---

GORM 允许进行链式操作，所以您可以像这样写代码：

```go
db.Where("name = ?", "jinzhu").Where("age = ?", 18).First(&user)
```

GORM 中有三种类型的方法： `链式方法`、`Finisher 方法`、`新建会话方法`

在 `链式方法`, `Finisher 方法`, GORM 返回一个初始化的 `*gorm.DB` 实例，不能安全地重复使用，或新生成的 SQL 可能会被先前的条件污染，例如：

```go
queryDB := DB.Where("name = ?", "jinzhu")

queryDB.Where("age > ?", 10).First(&user)
// SELECT * FROM users WHERE name = "jinzhu" AND age > 10

queryDB.Where("age > ?", 20).First(&user2)
// SELECT * FROM users WHERE name = "jinzhu" AND age > 10 AND age > 20
```

为了重新使用初始化的 `*gorm.DB` 实例, 您可以使用 `新建会话方法` 创建一个可共享的 `*gorm.DB`, 例如:

```go
queryDB := DB.Where("name = ?", "jinzhu").Session(&gorm.Session{})

queryDB.Where("age > ?", 10).First(&user)
// SELECT * FROM users WHERE name = "jinzhu" AND age > 10

queryDB.Where("age > ?", 20).First(&user2)
// SELECT * FROM users WHERE name = "jinzhu" AND age > 20
```

## 链式方法

链式方法是将 `Clauses` 修改或添加到当前 `Statement` 的方法，例如：

`Where`, `Select`, `Omit`, `Joins`, `Scopes`, `Preload`, `Raw` (`Raw` can't be used with other chainable methods to build SQL)...

这是 [完整方法列表](https://github.com/go-gorm/gorm/blob/master/chainable_api.go)，也可以查看 [SQL 构建器](sql_builder.html) 获取更多关于 `Clauses` 的信息

## <span id="finisher_method">Finisher 方法</span>

Finishers 是会立即执行注册回调的方法，然后生成并执行 SQL，比如这些方法：

`Create`, `First`, `Find`, `Take`, `Save`, `Update`, `Delete`, `Scan`, `Row`, `Rows`...

查看[完整方法列表](https://github.com/go-gorm/gorm/blob/master/finisher_api.go)

## <span id="goroutine_safe">新建会话方法</span>

GORM 定义了 `Session`、`WithContext`、`Debug` 方法做为 `新建会话方法`，查看[会话](session.html) 获取详情.

在 `链式方法`, `Finisher 方法`之后, GORM 返回一个初始化的 `*gorm. B` 实例，不能安全地再使用 您应该使用 `新建会话方法` 标记 `*gorm.DB` 为可共享。

让我们用实例来解释它：

示例 1：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is a new initialized `*gorm.DB`, which is safe to reuse

db.Where("name = ?", "jinzhu").Where("age = ?", 18).Find(&users)
// `Where("name = ?", "jinzhu")` is the first chain method call, it will create an initialized `*gorm.DB` instance, aka `*gorm.Statement`
// `Where("age = ?", 18)` is the second chain method call, it reuses the above `*gorm.Statement`, adds new condition `age = 18` to it
// `Find(&users)` is a finisher method, it executes registered Query Callbacks, which generates and runs the following SQL:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18;

db.Where("name = ?", "jinzhu2").Where("age = ?", 20).Find(&users)
// `Where("name = ?", "jinzhu2")` is also the first chain method call, it creates a new `*gorm.Statement`
// `Where("age = ?", 20)` reuses the above `Statement`, and add conditions to it
// `Find(&users)` is a finisher method, it executes registered Query Callbacks, generates and runs the following SQL:
// SELECT * FROM users WHERE name = 'jinzhu2' AND age = 20;

db.Find(&users)
// `Find(&users)` is a finisher method call, it also creates a new `Statement` and executes registered Query Callbacks, generates and runs the following SQL:
// SELECT * FROM users;
```

(错误的) 示例2：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is a new initialized *gorm.DB, which is safe to reuse

tx := db.Where("name = ?", "jinzhu")
// `Where("name = ?", "jinzhu")` returns an initialized `*gorm.Statement` instance after chain method `Where`, which is NOT safe to reuse

// good case
tx.Where("age = ?", 18).Find(&users)
// `tx.Where("age = ?", 18)` use the above `*gorm.Statement`, adds new condition to it
// `Find(&users)` is a finisher method call, it executes registered Query Callbacks, generates and runs the following SQL:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

// bad case
tx.Where("age = ?", 28).Find(&users)
// `tx.Where("age = ?", 18)` also use the above `*gorm.Statement`, and keep adding conditions to it
// So the following generated SQL is polluted by the previous conditions:
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 AND age = 28;
```

示例 3：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is a new initialized *gorm.DB, which is safe to reuse

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{})
tx := db.Where("name = ?", "jinzhu").WithContext(context.Background())
tx := db.Where("name = ?", "jinzhu").Debug()
// `Session`, `WithContext`, `Debug` returns `*gorm.DB` marked as safe to reuse, newly initialized `*gorm.Statement` based on it keeps current conditions

// good case
tx.Where("age = ?", 18).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

// good case
tx.Where("age = ?", 28).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 28;
```
