---
title: Preloading (Eager Loading)
layout: page
---

## Preload

GORMは、 `Preload`で他のSQL内のリレーションを事前読み込みできます。例：

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

// Preload Orders when find users
db.Preload("Orders").Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4);

db.Preload("Orders").Preload("Profile").Preload("Role").Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4); // has many
// SELECT * FROM profiles WHERE user_id IN (1,2,3,4); // has one
// SELECT * FROM roles WHERE id IN (4,5,6); // belongs to
```

## Joins Preloading

`Preload` はアソシエーションデータを別々のクエリにロードします。 `Join Preload` は内部結合を使用してアソシエーションデータをロードします。例：

```go
db.Joins("Company").Joins("Manager").Joins("Account").First(&user, 1)
db.Joins("Company").Joins("Manager").Joins("Account").First(&user, "users.name = ?", "jinzhu")
db.Joins("Company").Joins("Manager").Joins("Account").Find(&users, "users.id IN ?", []int{1,2,3,4,5})
```

**注：** `Join Preload` は`has one`や`belongs to`のような1:1のリレーションで動作します。

## Preload All

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

## Preload with conditions

GORMは条件付きのPreloadが可能です。これは[Inline Conditions](query.html#inline_conditions)と同様に動作します。

```go
// Preload Orders with conditions
db.Preload("Orders", "state NOT IN (?)", "cancelled").Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4) AND state NOT IN ('cancelled');

db.Where("state = ?", "active").Preload("Orders", "state NOT IN (?)", "cancelled").Find(&users)
// SELECT * FROM users WHERE state = 'active';
// SELECT * FROM orders WHERE user_id IN (1,2) AND state NOT IN ('cancelled');
```

## Custom Preloading SQL

`func(db *gorm.DB) *gorm.DB`を渡すことで、SQLのプリロードをカスタマイズできます。例：

```go
db.Preload("Orders", func(db *gorm.DB) *gorm.DB {
  return db.Order("orders.amount DESC")
}).Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4) order by orders.amount DESC;
```

## Nested Preloading

GORMはネストしたPreloadをサポートしています。例：

```go
db.Preload("Orders.OrderItems.Product").Preload("CreditCard").Find(&users)

// Customize Preload conditions for `Orders`
// And GORM won't preload unmatched order's OrderItems then
db.Preload("Orders", "state = ?", "paid").Preload("Orders.OrderItems").Find(&users)
```
