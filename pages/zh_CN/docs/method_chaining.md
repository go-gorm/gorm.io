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

`Where`、`Select`、`Omit`、`Joins`、`Scopes`、`Preload`、`Raw`（但在构建 SQL 语句时，`Raw` 不能与其它链式方法一起使用）...

这是 [完整方法列表](https://github.com/go-gorm/gorm/blob/master/chainable_api.go)，也可以查看 [SQL 构建器](sql_builder.html) 获取更多关于 `Clauses` 的信息

## <span id="finisher_method">Finisher 方法</span>

Finishers 是会立即执行注册回调的方法，然后生成并执行 SQL，比如这些方法：

`Create`, `First`, `Find`, `Take`, `Save`, `Update`, `Delete`, `Scan`, `Row`, `Rows`...

查看[完整方法列表](https://github.com/go-gorm/gorm/blob/master/finisher_api.go)

## 新建会话模式

在初始化了 `*gorm.DB` 或 `新建会话方法` 后， 调用下面的方法会创建一个新的 `Statement` 实例而不是使用当前的

GROM 定义了 `Session`、`WithContext`、`Debug` 方法做为 `新建会话方法`，查看[会话](session.html) 获取详情

让我们用一些例子来解释它：

示例 1：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db 是一个刚完成初始化的 *gorm.DB 实例，这是一个 `新建会话`
db.Where("name = ?", "jinzhu").Where("age = ?", 18).Find(&users)
// `Where("name = ?", "jinzhu")` 是调用的第一个方法，它会创建一个新 `Statement`
// `Where("age = ?", 18)` 会复用 `Statement`，并将条件添加至这个 `Statement`
// `Find(&users)` 是一个 finisher 方法，它运行注册的查询回调，生成并运行下面这条 SQL：
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18;

db.Where("name = ?", "jinzhu2").Where("age = ?", 20).Find(&users)
// `Where("name = ?", "jinzhu2")` 也是调用的第一个方法，也会创建一个新 `Statement`
// `Where("age = ?", 20)` 会复用 `Statement`，并将条件添加至这个 `Statement`
// `Find(&users)` 是一个 finisher 方法，它运行注册的查询回调，生成并运行下面这条 SQL：
// SELECT * FROM users WHERE name = 'jinzhu2' AND age = 20;

db.Find(&users)
// 对于这个 `新建会话模式` 的 `*gorm.DB` 实例来说，`Find(&users)` 是一个 finisher 方法也是第一个调用的方法。 
// 它创建了一个新的 `Statement` 运行注册的查询回调，生成并运行下面这条 SQL：
// SELECT * FROM users;
```

示例 2：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db 是一个刚完成初始化的 *gorm.DB 实例，这是一个 `新建会话`
tx := db.Where("name = ?", "jinzhu")
// `Where("name = ?", "jinzhu")` 是第一个被调用的方法，它创建了一个新的 `Statement` 并添加条件

tx.Where("age = ?", 18).Find(&users)
// `tx.Where("age = ?", 18)` 会复用上面的那个 `Statement`，并向其添加条件
// `Find(&users)` 是一个 finisher 方法，它运行注册的查询回调，生成并运行下面这条 SQL：
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

tx.Where("age = ?", 28).Find(&users)
// `tx.Where("age = ?", 18)` 同样会复用上面的那个 `Statement`，并向其添加条件
// `Find(&users)` 是一个 finisher 方法，它运行注册的查询回调，生成并运行下面这条 SQL：
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 AND age = 20;
```

{% note warn %}
**注意** 在示例 2 中，第一个查询会影响第二个查询生成的 SQL ，因为 GORM 复用 `Statement` 这可能会引发预期之外的问题，请参考 [线程安全](#goroutine_safe) 了解如何避免该问题。
{% endnote %}

## <span id="goroutine_safe">方法链和协程安全</span>

新初始化的 `*gorm.DB` 或调用 `新建会话方法` 后，GORM 会创建新的 `Statement` 实例。因此想要复用 `*gorm.DB`，您需要确保它们处于 `新建会话模式`，例如：

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

// 安全的使用新初始化的 *gorm.DB
for i := 0; i < 100; i++ {
  go db.Where(...).First(&user)
}

tx := db.Where("name = ?", "jinzhu")
// 不安全的复用 Statement
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.WithContext(ctx)
// 在 `新建会话方法` 之后是安全的
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.Where("name = ?", "jinzhu").WithContext(ctx)
// 在 `新建会话方法` 之后是安全的
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user) // `name = 'jinzhu'` 会应用到查询中
}

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{})
// 在 `新建会话方法` 之后是安全的
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user) // `name = 'jinzhu'` 会应用到查询中
}
```
