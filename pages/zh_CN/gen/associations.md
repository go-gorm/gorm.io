---
title: Associations
layout: page
---

GEN will auto-save associations as GORM do. The relationships (BelongsTo/HasOne/HasMany/Many2Many) reuse GORM's tag. This feature only support exist model for now.

## Relation

There are 4 kind of relationship.

```go
const (
    HasOne    RelationshipType = RelationshipType(schema.HasOne)    // HasOneRel has one relationship
    HasMany   RelationshipType = RelationshipType(schema.HasMany)   // HasManyRel has many relationships
    BelongsTo RelationshipType = RelationshipType(schema.BelongsTo) // BelongsToRel belongs to relationship
    Many2Many RelationshipType = RelationshipType(schema.Many2Many) // Many2ManyRel many to many relationship
)
```

### Relate to exist model

```go
package model

// exist model
type Customer struct {
    gorm.Model
    CreditCards []CreditCard `gorm:"foreignKey:CustomerRefer"`
}

type CreditCard struct {
    gorm.Model
    Number        string
    CustomerRefer uint
}
```

GEN will detect model's associations:

```go
// specify model
g.ApplyBasic(model.Customer{}, model.CreditCard{})

// assoications will be detected and converted to code 
package query

type customer struct {
    ...
    CreditCards customerHasManyCreditCards
}

type creditCard struct{
    ...
}
```

### Relate to table in database

The association have to be speified by `gen.FieldRelate`

```go
card := g.GenerateModel("credit_cards")
customer := g.GenerateModel("customers", gen.FieldRelate(field.HasMany, "CreditCards", card, 
    &field.RelateConfig{
        // RelateSlice: true,
        GORMTag: "foreignKey:CustomerRefer",
    }),
)

g.ApplyBasic(card, custormer)
```

GEN will generate models with associated field:

```go
// customers
type Customer struct {
    ID          int64          `gorm:"column:id;type:bigint(20) unsigned;primaryKey" json:"id"`
    CreatedAt   time.Time      `gorm:"column:created_at;type:datetime(3)" json:"created_at"`
    UpdatedAt   time.Time      `gorm:"column:updated_at;type:datetime(3)" json:"updated_at"`
    DeletedAt   gorm.DeletedAt `gorm:"column:deleted_at;type:datetime(3)" json:"deleted_at"`
    CreditCards []CreditCard   `gorm:"foreignKey:CustomerRefer" json:"credit_cards"`
}


// credit_cards
type CreditCard struct {
    ID            int64          `gorm:"column:id;type:bigint(20) unsigned;primaryKey" json:"id"`
    CreatedAt     time.Time      `gorm:"column:created_at;type:datetime(3)" json:"created_at"`
    UpdatedAt     time.Time      `gorm:"column:updated_at;type:datetime(3)" json:"updated_at"`
    DeletedAt     gorm.DeletedAt `gorm:"column:deleted_at;type:datetime(3)" json:"deleted_at"`
    CustomerRefer int64          `gorm:"column:customer_refer;type:bigint(20) unsigned" json:"customer_refer"`
}
```

If associated model already exists, `gen.FieldRelateModel` can help you build associations between them.

```go
customer := g.GenerateModel("customers", gen.FieldRelateModel(field.HasMany, "CreditCards", model.CreditCard{}, 
    &field.RelateConfig{
        // RelateSlice: true,
        GORMTag: "foreignKey:CustomerRefer",
    }),
)

g.ApplyBasic(custormer)
```

### Relate Config

```go
type RelateConfig struct {
    // specify field's type
    RelatePointer      bool // ex: CreditCard  *CreditCard
    RelateSlice        bool // ex: CreditCards []CreditCard
    RelateSlicePointer bool // ex: CreditCards []*CreditCard

    JSONTag      string // related field's JSON tag
    GORMTag      string // related field's GORM tag
    NewTag       string // related field's new tag
    OverwriteTag string // related field's tag
}
```

## Operation

### Skip Auto Create/Update

```go
user := model.User{
  Name:            "modi",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "modi@example.com"},
    {Email: "modi-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

u := query.Use(db).User

u.WithContext(ctx).Select(u.Name).Create(&user)
// INSERT INTO "users" (name) VALUES ("jinzhu", 1, 2);

u.WithContext(ctx).Omit(u.BillingAddress.Field()).Create(&user)
// Skip create BillingAddress when creating a user

u.WithContext(ctx).Omit(u.BillingAddress.Field("Address1")).Create(&user)
// Skip create BillingAddress.Address1 when creating a user

u.WithContext(ctx).Omit(field.AssociationFields).Create(&user)
// Skip all associations when creating a user
```

Method `Field` will join a serious field name with ''.", for example: `u.BillingAddress.Field("Address1", "Street")` equals to `BillingAddress.Address1.Street`

### Find Associations

Find matched associations

```go
u := query.Use(db).User

languages, err = u.Languages.Model(&user).Find()
```

Find associations with conditions

```go
q := query.Use(db)
u := q.User

languages, err = u.Languages.Where(q.Language.Name.In([]string{"ZH","EN"})).Model(&user).Find()
```

### Append Associations

Append new associations for `many to many`, `has many`, replace current association for `has one`, `belongs to`

```go
u := query.Use(db).User

u.Languages.Model(&user).Append(&languageZH, &languageEN)

u.Languages.Model(&user).Append(&Language{Name: "DE"})

u.CreditCards.Model(&user).Append(&CreditCard{Number: "411111111111"})
```

### Replace Associations

Replace current associations with new ones

```go
u.Languages.Model(&user).Replace(&languageZH, &languageEN)
```

### Delete Associations

Remove the relationship between source & arguments if exists, only delete the reference, won’t delete those objects from DB.

```go
u := query.Use(db).User

u.Languages.Model(&user).Delete(&languageZH, &languageEN)

u.Languages.Model(&user).Delete([]*Language{&languageZH, &languageEN}...)
```

### Clear Associations

Remove all reference between source & association, won’t delete those associations

```go
u.Languages.Model(&user).Clear()
```

### Count Associations

Return the count of current associations

```go
u.Languages.Model(&user).Count()
```

### Delete with Select

You are allowed to delete selected has one/has many/many2many relations with `Select` when deleting records, for example:

```go
u := query.Use(db).User

// delete user's account when deleting user
u.Select(u.Account).Delete(&user)

// delete user's Orders, CreditCards relations when deleting user
db.Select(u.Orders.Field(), u.CreditCards.Field()).Delete(&user)

// delete user's has one/many/many2many relations when deleting user
db.Select(field.AssociationFields).Delete(&user)
```

## Preloading

This feature only support exist model for now.

### Preload

GEN allows eager loading relations in other SQL with `Preload`, for example:

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

q := query.Use(db)
u := q.User
o := q.Order

// Preload Orders when find users
users, err := u.WithContext(ctx).Preload(u.Orders).Find()
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4);

users, err := u.WithContext(ctx).Preload(u.Orders).Preload(u.Profile).Preload(u.Role).Find()
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4); // has many
// SELECT * FROM profiles WHERE user_id IN (1,2,3,4); // has one
// SELECT * FROM roles WHERE id IN (4,5,6); // belongs to
```

### Preload All

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

users, err := u.WithContext(ctx).Preload(field.Associations).Find()
```

`clause.Associations` won’t preload nested associations, but you can use it with [Nested Preloading](#nested-preloading) together, e.g:

```go
users, err := u.WithContext(ctx).Preload(u.Orders.OrderItems.Product).Find()
```

### Preload with select

Specify selected columns with method `Select`. Foregin key must be selected.

```go
type User struct {
  gorm.Model
  CreditCards []CreditCard `gorm:"foreignKey:UserRefer"`
}

type CreditCard struct {
  gorm.Model
  Number    string
  UserRefer uint
}

u := q.User
cc := q.CreditCard

// !!! Foregin key "cc.UserRefer" must be selected
users, err := u.WithContext(ctx).Where(c.ID.Eq(1)).Preload(u.CreditCards.Select(cc.Number, cc.UserRefer)).Find()
// SELECT * FROM `credit_cards` WHERE `credit_cards`.`customer_refer` = 1 AND `credit_cards`.`deleted_at` IS NULL
// SELECT * FROM `customers` WHERE `customers`.`id` = 1 AND `customers`.`deleted_at` IS NULL LIMIT 1
```

### Preload with conditions

GEN allows Preload associations with conditions, it works similar to Inline Conditions.

```go
q := query.Use(db)
u := q.User
o := q.Order

// Preload Orders with conditions
users, err := u.WithContext(ctx).Preload(u.Orders.On(o.State.NotIn("cancelled")).Find()
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2,3,4) AND state NOT IN ('cancelled');

users, err := u.WithContext(ctx).Where(u.State.Eq("active")).Preload(u.Orders.On(o.State.NotIn("cancelled")).Find()
// SELECT * FROM users WHERE state = 'active';
// SELECT * FROM orders WHERE user_id IN (1,2) AND state NOT IN ('cancelled');

users, err := u.WithContext(ctx).Preload(u.Orders.Order(o.ID.Desc(), o.CreateTime).Find()
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2) Order By id DESC, create_time;

users, err := u.WithContext(ctx).Preload(u.Orders.On(o.State.Eq("on")).Order(o.ID.Desc()).Find()
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2) AND state = "on" Order By id DESC;

users, err := u.WithContext(ctx).Preload(u.Orders.Clauses(hints.UseIndex("idx_order_id"))).Find()
// SELECT * FROM users;
// SELECT * FROM orders WHERE user_id IN (1,2) USE INDEX (`idx_order_id`);

user, err := u.WithContext(ctx).Where(u.ID.Eq(1)).Preload(u.Orders.Offset(100).Limit(20)).Take()
// SELECT * FROM users WHERE `user_id` = 1 LIMIT 20 OFFSET 100;
// SELECT * FROM `users` WHERE `users`.`id` = 1 LIMIT 1
```

### Nested Preloading

GEN supports nested preloading, for example:

```go
db.Preload(u.Orders.OrderItems.Product).Preload(u.CreditCard).Find(&users)

// Customize Preload conditions for `Orders`
// And GEN won't preload unmatched order's OrderItems then
db.Preload(u.Orders.On(o.State.Eq("paid"))).Preload(u.Orders.OrderItems).Find(&users)
```

