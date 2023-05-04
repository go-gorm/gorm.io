---
title: Preloading (Eager Loading)
layout: page
---

## Preload

GORM allows eager loading relations in other SQL with `Preload`, for example:

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

`Preload` loads the association data in a separate query, `Join Preload` will loads association data using left join, for example:

```go
db.Joins("Company").Joins("Manager").Joins("Account").First(&user, 1)
db.Joins("Company").Joins("Manager").Joins("Account").First(&user, "users.name = ?", "jinzhu")
db.Joins("Company").Joins("Manager").Joins("Account").Find(&users, "users.id IN ?", []int{1,2,3,4,5})
```

Join with conditions

```go
db.Joins("Company", DB.Where(&Company{Alive: true})).Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id` AND `Company`.`alive` = true;
```

Join nested model

```go
db.Joins("Manager").Joins("Manager.Company").Find(&users)
// SELECT "users"."id","users"."created_at","users"."updated_at","users"."deleted_at","users"."name","users"."age","users"."birthday","users"."company_id","users"."manager_id","users"."active","Manager"."id" AS "Manager__id","Manager"."created_at" AS "Manager__created_at","Manager"."updated_at" AS "Manager__updated_at","Manager"."deleted_at" AS "Manager__deleted_at","Manager"."name" AS "Manager__name","Manager"."age" AS "Manager__age","Manager"."birthday" AS "Manager__birthday","Manager"."company_id" AS "Manager__company_id","Manager"."manager_id" AS "Manager__manager_id","Manager"."active" AS "Manager__active","Manager__Company"."id" AS "Manager__Company__id","Manager__Company"."name" AS "Manager__Company__name" FROM "users" LEFT JOIN "users" "Manager" ON "users"."manager_id" = "Manager"."id" AND "Manager"."deleted_at" IS NULL LEFT JOIN "companies" "Manager__Company" ON "Manager"."company_id" = "Manager__Company"."id" WHERE "users"."deleted_at" IS NULL
```

{% note warn %}
**NOTE** `Join Preload` works with one-to-one relation, e.g: `has one`, `belongs to`
{% endnote %}

## Preload All

`clause.Associations` can work with `Preload` similar like `Select` when creating/updating, you can use it to `Preload` all associations, for example:

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

`clause.Associations` won't preload nested associations, but you can use it with [Nested Preloading](#nested_preloading) together, e.g:

```go
db.Preload("Orders.OrderItems.Product").Preload(clause.Associations).Find(&users)
```

## Preload with conditions

GORM allows Preload associations with conditions, it works similar to [Inline Conditions](query.html#inline_conditions)

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

You are able to custom preloading SQL by passing in `func(db *gorm.DB) *gorm.DB`, for example:

```go
db.Preload("Orders", func(db *gorm.DB) *gorm.DB {
  return db.Order("orders.amount DESC")
}).Find(&users)
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4) order by orders.amount DESC;
```

## <span id="nested_preloading">Nested Preloading</span>

GORM supports nested preloading, for example:

```go
db.Preload("Orders.OrderItems.Product").Preload("CreditCard").Find(&users)

// Customize Preload conditions for `Orders`
// And GORM won't preload unmatched order's OrderItems then
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