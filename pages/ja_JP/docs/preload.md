---
title: Preloading (Eager Loading)
layout: page
---

## Preload

GORMの `Preload` を使用すると、別のSQLを発行して関連レコードを eager loading することができます。例：

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

## Joins による Preloading

`Preload` はアソシエーションデータを別々のクエリでロードします。 `Join Preload` は内部結合を使用してアソシエーションデータをロードします。例：

```go
db.Joins("Company").Joins("Manager").Joins("Account").First(&user, 1)
db.Joins("Company").Joins("Manager").Joins("Account").First(&user, "users.name = ?", "jinzhu")
db.Joins("Company").Joins("Manager").Joins("Account").Find(&users, "users.id IN ?", []int{1,2,3,4,5})
```

条件を指定して結合する

```go
db.Joins("Company", DB.Where(&Company{Alive: true})).Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id` AND `Company`.`alive` = true;
```

{% note warn %}
**注意** `Join Preload` は、1 対 1 関係にあるリレーションで動作します。例えば `has one`, `belongs to` がそれにあたります。
{% endnote %}

## Preload All

レコード作成/更新時の `Select` で指定するのと同様に、 `Preload` でも `clause.Associations` を指定することができます。全ての関連レコードを `Preload` する際にこれを使用することができます。例：

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

`clause.Associations` はネストした関連のPreloadは行いません。しかし、 [Nested Preloading](#nested_preloading) と併用することができます。例:

```go
db.Preload("Orders.OrderItems.Product").Preload(clause.Associations).Find(&users)
```

## 条件付きのPreload

GORMでは条件付きでのPreloadが可能です。これは [Inline Conditions](query.html#inline_conditions) と同様の動作になります。

```go
// Preload Orders with conditions
db.Preload("Orders", "state NOT IN (?)", "cancelled").Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4) AND state NOT IN ('cancelled');

db.Where("state = ?", "active").Preload("Orders", "state NOT IN (?)", "cancelled").Find(&users)
// SELECT * FROM users WHERE state = 'active';
// SELECT * FROM orders WHERE user_id IN (1,2) AND state NOT IN ('cancelled');
```

## Preload の SQL をカスタマイズする

`func(db *gorm.DB) *gorm.DB` を引数に渡すことで、PreloadのSQLをカスタマイズできます。例：

```go
db.Preload("Orders", func(db *gorm.DB) *gorm.DB {
  return db.Order("orders.amount DESC")
}).Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4) order by orders.amount DESC;
```

## <span id="nested_preloading">Nested Preloading</span>

GORMはネストした関連データのPreloadをサポートしています。例：

```go
db.Preload("Orders.OrderItems.Product").Preload("CreditCard").Find(&users)

// Customize Preload conditions for `Orders`
// `Orders` の Preload をカスタマイズして、
// 条件に一致しない `Orders` の `OrderItems` を preloadしないようにする
db.Preload("Orders", "state = ?", "paid").Preload("Orders.OrderItems").Find(&users)
```

## <span id="embedded_preloading">Embedded Preloading</span>

Embedded Preloading is used for [Embedded Struct](models.html#embedded_struct), especially the same struct. The syntax for Embedded Preloading is similar to Nested Preloading, they are divided by dot.

For example:

```go
type Address struct {
    CountryID int
    Country   Country
}

type Org struct {
    PostalAddress   Address `gorm:"embedded;embeddedPrefix:postal_address_"`
    VisitingAddress Address `gorm:"embedded;embeddedPrefix:visiting_address_"`
    Address         struct {
        ID int
        Address
    }
}

// Only preload Org.Address and Org.Address.Country
db.Preload("Address.Country")  // "Address" is has_one, "Country" is belongs_to (nested association)

// Only preload Org.VisitingAddress
db.Preload("PostalAddress.Country") // "PostalAddress.Country" is belongs_to (embedded association)

// Only preload Org.NestedAddress
db.Preload("NestedAddress.Address.Country") // "NestedAddress.Address.Country" is belongs_to (embedded association)

// All preloaded include "Address" but exclude "Address.Country", because it won't preload nested associations.
db.Preload(clause.Associations)
```

We can omit embedded part when there is no ambiguity.

```go
type Address struct {
    CountryID int
    Country   Country
}

type Org struct {
    Address Address `gorm:"embedded"`
}

db.Preload("Address.Country")
db.Preload("Country") // omit "Address" because there is no ambiguity
```

{% note warn %}
**NOTE** `Embedded Preload` only works with `belongs to` relation. Values of other relations are the same in database, we can't distinguish them.
{% endnote %}