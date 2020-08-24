---
title: 预加载
layout: page
---

## 预加载

GORM 允许在 `Preload` 的其它 SQL 中直接加载关系，例如：

```go
type User struct {
  gorm.Model
  Username string
  Orders   []Order
}

type Order struct {
  gorm.Model
  UserID uint
  Price  float64
}

// 查找 user 时预加载相关 Order
db.Preload("Orders").Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4);

db.Preload("Orders").Preload("Profile").Preload("Role").Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4); // has many
// SELECT * FROM profiles WHERE user_id IN (1,2,3,4); // has one
// SELECT * FROM roles WHERE id IN (4,5,6); // belongs to
```

## Joins 预加载

`Preload` 在一个单独查询中加载关联数据。而 `Join Preload` 会使用 inner join 加载关联数据，例如：

```go
db.Joins("Company").Joins("Manager").Joins("Account").First(&user, 1)
db.Joins("Company").Joins("Manager").Joins("Account").First(&user, "users.name = ?", "jinzhu")
db.Joins("Company").Joins("Manager").Joins("Account").Find(&users, "users.id IN ?", []int{1,2,3,4,5})
```

**注意** `Join Preload` 适用于一对一的关系，例如： `has one`, `belongs to`

## 预加载全部

`clause.Associations` can works with `Preload` similar like `Select` when creating/updating, you can use it to `Preload` all associations, for example:

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company
  Role       Role
}

db.Preload(clause.Associations).Find(&users)
```

## 带条件的预加载

GORM 允许带条件的 Preload 关联，类似于[内联条件](query.html#inline_conditions)

```go
// 带条件的预加载 Order
db.Preload("Orders", "state NOT IN (?)", "cancelled").Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4) AND state NOT IN ('cancelled');

db.Where("state = ?", "active").Preload("Orders", "state NOT IN (?)", "cancelled").Find(&users)
// SELECT * FROM users WHERE state = 'active';
// SELECT * FROM orders WHERE user_id IN (1,2) AND state NOT IN ('cancelled');
```

## 自定义预加载 SQL

您可以通过 `func(db *gorm.DB) *gorm.DB` 实现自定义预加载 SQL，例如：

```go
db.Preload("Orders", func(db *gorm.DB) *gorm.DB {
  return db.Order("orders.amount DESC")
}).Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4) order by orders.amount DESC;
```

## 嵌套预加载

GORM 支持嵌套预加载，例如：

```go
db.Preload("Orders.OrderItems.Product").Preload("CreditCard").Find(&users)

// 自定义预加载 `Orders` 的条件
// 这样，GORM 就不会加载不匹配的 order 记录
db.Preload("Orders", "state = ?", "paid").Preload("Orders.OrderItems").Find(&users)
```
