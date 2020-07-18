---
title: 链式方法
layout: page
---

GORM 允许进行链式操作，所以您可以像这样写代码：

```go
db.Where("name = ?", "jinzhu").Where("age = ?", 18).First(&user)
```

GORM 中有三种类型的方法： `链式方法`、`Finisher 方法`、`新建会话方法`

## 链式方法

链式方法是将 `Clauses` 修改或添加到当前 `Statement` 的方法，例如：

`Where`, `Select`, `Omit`, `Joins`, `Scopes`, `Preload`, `Raw`...

这是 [完整方法列表](https://github.com/go-gorm/gorm/blob/master/chainable_api.go)，也可以查看 [SQL 构建器](sql_builder.html) 获取更多关于 `Clauses` 的信息

## Finisher Method

Finishers 是会立即执行注册回调的方法，然后生成并执行 SQL，比如这些方法：

`Create`, `First`, `Find`, `Take`, `Save`, `Update`, `Delete`, `Scan`, `Row`, `Rows`...

查看[完整方法列表](https://github.com/go-gorm/gorm/blob/master/finisher_api.go)

## 新建会话模式

在初始化了 `*gorm.DB` 或 `新建会话方法` 后， 调用下面的方法会创建一个新的 `Statement` 实例而不是使用当前的

GROM 定义了 `Session`、`WithContext`、`Debug` 方法做为 `新建会话方法`，参考[会话](session.html) 获得详细

让我们用一些例子来解释它：

示例 1：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is new initialized *gorm.DB, which under `New Session Mode`
db.Where("name = ?", "jinzhu").Where("age = ?", 18).Find(&users)
// `Where("name = ?", "jinzhu")` is the first method call, it will creates a new `Statement`
// `Where("age = ?", 18)` reuse the `Statement`, and add conditions to the `Statement`
// `Find(&users)` is a finisher, it executes registered Query Callbacks, generate and run following SQL
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18;

db.Where("name = ?", "jinzhu2").Where("age = ?", 20).Find(&users)
// `Where("name = ?", "jinzhu2")` is also the first method call, it creates new `Statement` too
// `Where("age = ?", 20)` reuse the `Statement`, and add conditions to the `Statement`
// `Find(&users)` is a finisher, it executes registered Query Callbacks, generate and run following SQL
// SELECT * FROM users WHERE name = 'jinzhu2' AND age = 20;

db.Find(&users)
// `Find(&users)` is a finisher method and also the first method call for a `New Session Mode` `*gorm.DB`
// It creates a new `Statement` and executes registered Query Callbacks, generates and run following SQL
// SELECT * FROM users;
```

Example 2:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db is new initialized *gorm.DB, which under `New Session Mode`
tx := db.Where("name = ?", "jinzhu")
// `Where("name = ?", "jinzhu")` is the first method call, it creates a new `Statement` and add conditions

tx.Where("age = ?", 18).Find(&users)
// `tx.Where("age = ?", 18)` REUSE above `Statement`, and add conditions to the `Statement`
// `Find(&users)` is a finisher, it executes registered Query Callbacks, generate and run following SQL
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

tx.Where("age = ?", 28).Find(&users)
// `tx.Where("age = ?", 18)` REUSE above `Statement` also, and add conditions to the `Statement`
// `Find(&users)` is a finisher, it executes registered Query Callbacks, generate and run following SQL
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 AND age = 20;
```

**NOTE** In example 2, the first query affected the second generated SQL as GORM reused the `Statement`, this might cause unexpected issues, refer [Goroutine Safety](#goroutine_safe) for how to avoid it

## <span id="goroutine_safe">Goroutine Safety</span>

Methods will create new `Statement` instances for new initialized `*gorm.DB` or after a `New Session Method`, so to reuse a `*gorm.DB`, you need to make sure they are under `New Session Mode`, for example:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

// Safe for new initialized *gorm.DB
for i := 0; i < 100; i++ {
  go db.Where(...).First(&user)
}

tx := db.Where("name = ?", "jinzhu")
// NOT Safe as reusing Statement
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.WithContext(ctx)
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.Where("name = ?", "jinzhu").WithContext(ctx)
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user) // `name = 'jinzhu'` will applies to all
}

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{WithConditions: true})
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user) // `name = 'jinzhu'` will applies to all
}
```
