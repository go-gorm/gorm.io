---
title: 链式操作
layout: page
---

## 链式操作

Method Chaining，Gorm 实现了链式操作接口，所以你可以把代码写成这样：

```go
db, err := gorm.Open("postgres", "user=gorm dbname=gorm sslmode=disable")

// 创建一个新的 relation
tx := db.Where("name = ?", "jinzhu")

// 添加更多查询条件
if someCondition {
    tx = tx.Where("age = ?", 20)
} else {
    tx = tx.Where("age = ?", 30)
}

if yetAnotherCondition {
    tx = tx.Where("active = ?", 1)
}
```

在调用立即执行方法前不会生成 Query 语句，有时候这会很有用。

比如你可以抽取一个函数来处理一些通用逻辑。

## 立即执行方法

Immediate methods ，立即执行方法是指那些会立即生成 SQL 语句并发送到数据库的方法, 他们一般是 CRUD 方法，比如：

`Create`, `First`, `Find`, `Take`, `Save`, `UpdateXXX`, `Delete`, `Scan`, `Row`, `Rows`...

这有一个基于上面链式方法代码的立即执行方法的例子：

```go
tx.Find(&user)
```

生成的 Sql

```sql
SELECT * FROM users where name = 'jinzhu' AND age = 30 AND active = 1;
```

## 范围

Scopes，Scope 是建立在链式操作的基础之上的。

基于它，你可以抽取一些通用逻辑，写出更多可重用的函数库。

```go
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
    return db.Where("amount > ?", 1000)
}

func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
    return db.Where("pay_mode_sign = ?", "C")
}

func PaidWithCod(db *gorm.DB) *gorm.DB {
    return db.Where("pay_mode_sign = ?", "C")
}

func OrderStatus(status []string) func (db *gorm.DB) *gorm.DB {
    return func (db *gorm.DB) *gorm.DB {
        return db.Scopes(AmountGreaterThan1000).Where("status IN (?)", status)
    }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// 查询所有信用卡中金额大于 1000 的订单

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// 查询所有 Cod 中金额大于 1000 的订单

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// 查询所有已付款、已发货中金额大于 1000 的订单
```

## 多个立即执行方法

Multiple Immediate Methods，在 GORM 中使用多个立即执行方法时，后一个立即执行方法会复用前一个 立即执行方法的条件 (不包括内联条件) 。

```go
db.Where("name LIKE ?", "jinzhu%").Find(&users, "id IN (?)", []int{1, 2, 3}).Count(&count)
```

生成的 Sql

```sql
SELECT * FROM users WHERE name LIKE 'jinzhu%' AND id IN (1, 2, 3)

SELECT count(*) FROM users WHERE name LIKE 'jinzhu%'
```

## 线程安全

所有链式方法都会创建并克隆一个新的 DB 对象 (共享一个连接池)，GORM 在多 goroutine 中是并发安全的。