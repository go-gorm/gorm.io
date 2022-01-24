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

带条件的 Join

```go
db.Joins("Company", DB.Where(&Company{Alive: true})).Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id` AND `Company`.`alive` = true;
```

{% note warn %}
**注意** `Join Preload` 适用于一对一的关系，例如： `has one`, `belongs to`
{% endnote %}

## 预加载全部

与创建、更新时使用 `Select` 类似，`clause.Associations` 也可以和 `Preload` 一起使用，它可以用来 `预加载` 全部关联，例如：

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company
  Role       Role
  Orders     []Order
}

db.Preload(clause.Associations).Find(&users)
```

`clause.Associations` 不会预加载嵌套的关联，但你可以使用[嵌套预加载](#nested_preloading) 例如：

```go
db.Preload("Orders.OrderItems.Product").Preload(clause.Associations).Find(&users)
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

## <span id="nested_preloading">嵌套预加载</span>

GORM 支持嵌套预加载，例如：

```go
db.Preload("Orders.OrderItems.Product").Preload("CreditCard").Find(&users)

// 自定义预加载 `Orders` 的条件
// 这样，GORM 就不会加载不匹配的 order 记录
db.Preload("Orders", "state = ?", "paid").Preload("Orders.OrderItems").Find(&users)
```
