---
title: Associations
layout: page
---

GEN 支持像 GORM 一样的处理关联的方式。 关系(属于To/HasOne/HasMany2Many) 重新使用GORM的标签。 支持关联已经存在的model，或者关联数据库中的表两种方式。

## 关联

Gen 支持四种关联方式。

```go
const (
    HasOne    RelationshipType = RelationshipType(schema.HasOne)    // HasOneRel has one relationship
    HasMany   RelationshipType = RelationshipType(schema.HasMany)   // HasManyRel has many relationships
    BelongsTo RelationshipType = RelationshipType(schema.BelongsTo) // BelongsToRel belongs to relationship
    Many2Many RelationshipType = RelationshipType(schema.Many2Many) // Many2ManyRel many to many relationship
)
```

### 关联已经存在的model

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

GEN 将检测模型的关联：

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

### 关联数据库中的表。

关联必须由 `gen.FieldRelate` 指定。

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

GEN 将生成带有关联字段的model：

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

如果关联的mode已经存在， 可以通过`gen.FieldRelateModel` 设置关联。

```go
customer := g.GenerateModel("customers", gen.FieldRelateModel(field.HasMany, "CreditCards", model.CreditCard{}, 
    &field.RelateConfig{
        // RelateSlice: true,
        GORMTag: "foreignKey:CustomerRefer",
    }),
)

g.ApplyBasic(custormer)
```

### 关联配置

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

## 操作

### 跳过自动创建、更新

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

方法 ` Field ` 将通过 '.'进行连接, 例如: `u.BillingAddress.Field("Address1", "Street")` 等于 `BillingAddress.Address.Address.Address.Street`

### 查找关联

查找匹配的关联

```go
u := query.Use(db).User

languages, err = u.Languages.Model(&user).Find()
```

查找带条件的关联表数据

```go
q := query.Use(db)
u := q.User

languages, err = u.Languages.Where(q.Language.Name.In([]string{"ZH","EN"})).Model(&user).Find()
```

### 添加关联

Append 可以添加新的关联关系`many to many`、`has many` ；替换已经存在的关联关系 `has one`, `belongs to`

```go
u := query.Use(db).User

u.Languages.Model(&user).Append(&languageZH, &languageEN)

u.Languages.Model(&user).Append(&Language{Name: "DE"})

u.CreditCards.Model(&user).Append(&CreditCard{Number: "411111111111"})
```

### 替换关联

用新的关联关系替换当前存在的关联关联关系

```go
u.Languages.Model(&user).Replace(&languageZH, &languageEN)
```

### 删除关联

如果存在，则删除源模型与参数之间的关系，只会删除引用，不会从数据库中删除这些对象。

```go
u := query.Use(db).User

u.Languages.Model(&user).Delete(&languageZH, &languageEN)

u.Languages.Model(&user).Delete([]*Language{&languageZH, &languageEN}...)
```

### 清除关联

删除源 & 关联之间的所有引用，不会删除这些关联

```go
u.Languages.Model(&user).Clear()
```

### Count Associations

返回当前关联的数量

```go
u.Languages.Model(&user).Count()
```

### Delete with Select

你可以在删除记录时通过 `Select` 来删除具有 has one、has many、many2many 关系的记录，例如：

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

支持关联已经存在的model，或者关联数据库中的表两种方式。

### Preload

GEN允许使用 `Preload`通过多个SQL来直接加载关联表数据, 例如：

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

users, err := u.WithContext(ctx).Preload(field.Associations).Find()
```

`clause.Associations`不会预加载嵌套的关联关系，但是你可以将其与[Nested Preloading](#nested-preloading)一起使用， 例如：

```go
users, err := u.WithContext(ctx).Preload(u.Orders.OrderItems.Product).Find()
```

To include soft deleted records in all associactions use relation scope `field.RelationFieldUnscoped`, e.g:
```go
users, err := u.WithContext(ctx).Preload(field.Associations.Scopes(field.RelationFieldUnscoped)).Find()
```

### Preload with select

使用方法 `Select` 指定加载的列. 。 外键必须选择。

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

GEN 允许带条件的 Preload 关联，类似于内联条件.

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

GEN 支持嵌套预加载，例如：

```go
db.Preload(u.Orders.OrderItems.Product).Preload(u.CreditCard).Find(&users)

// Customize Preload conditions for `Orders`
// And GEN won't preload unmatched order's OrderItems then
db.Preload(u.Orders.On(o.State.Eq("paid"))).Preload(u.Orders.OrderItems).Find(&users)
```

