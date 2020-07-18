---
title: 实体关联
layout: page
---

## 自动创建、更新

在创建、更新记录时，GORM 会通过 [Upsert](create.html#upsert) 自动保存关联及其引用记录。

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db.Create(&user)
// BEGIN TRANSACTION;
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "addresses" (address1) VALUES ("Shipping Address - Address 1") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu-2@example.com") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "languages" ("name") VALUES ('ZH') ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "user_languages" ("user_id","language_id") VALUES (111, 1) ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "languages" ("name") VALUES ('EN') ON DUPLICATE KEY DO NOTHING;
// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 2) ON DUPLICATE KEY DO NOTHING;
// COMMIT;

db.Save(&user)
```

## 跳过自动创建、更新

若要在创建、更新时跳过自动保存，您可以使用 `Select` 或 `Omit`，例如：

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db.Select("Name").Create(&user)
// INSERT INTO "users" (name) VALUES ("jinzhu", 1, 2);

db.Omit("BillingAddress").Create(&user)
// 创建 user 时，跳过自动创建 BillingAddress

db.Omit(clause.Associations).Create(&user)
// 创建 user 时，跳过自动创建所有关联记录
```

## 关联模式

关联模式包含一些在处理关系时有用的方法

```go
// 开始关联模式
var user User
db.Model(&user).Association("Languages")
// `user` 是源模型，它的主键不能为空
// 关系的字段名是 `Languages`
// 如果上面两个条件匹配，会开始关联模式，否则会返回错误
db.Model(&user).Association("Languages").Error
```

### 查找关联

查找所有匹配的关联记录

```go
db.Model(&user).Association("Languages").Find(&languages)

// 带条件的查找
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)
```

### 添加关联

为 `many to many`、`has many` 添加新的关联；为 `has one`, `belongs to` 替换当前的关联

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(CreditCard{Number: "411111111111"})
```

### 替换关联

用一个新的关联替换当前的关联

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### 删除关联

Remove the relationship between source & arguments if exists, only delete the reference, won't delete those objects from DB.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Clear Associations

Remove all reference between source & association, won't delete those associations

```go
db.Model(&user).Association("Languages").Clear()
```

### Count Associations

Return the count of current associations

```go
db.Model(&user).Association("Languages").Count()
```

### Batch Data

Association Mode supports batch data, e.g:

```go
// Find all roles for all users
gorm.Model(&users).Association("Role").Find(&roles)

// Delete User A from all users's team
gorm.Model(&users).Association("Team").Delete(&userA)

// Get unduplicated count of members in all user's team
gorm.Model(&users).Association("Team").Count()

// For `Append`, `Replace` with batch data, arguments's length need to equal to data's length or will returns error
var users = []User{user1, user2, user3}
// e.g: we have 3 users, Append userA to user1's team, append userB to user2's team, append userA, userB and userC to user3's team
gorm.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Reset user1's team to userA，reset user2's team to userB, reset user3's team to userA, userB and userC
gorm.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="tags">Association Tags</span>

| Tag              | Description                                     |
| ---------------- | ----------------------------------------------- |
| foreignKey       | Specifies foreign key                           |
| references       | Specifies references                            |
| polymorphic      | Specifies polymorphic type                      |
| polymorphicValue | Specifies polymorphic value, default table name |
| many2many        | Specifies join table name                       |
| jointForeignKey  | Specifies foreign key of jointable              |
| joinReferences   | Specifies references' foreign key of jointable  |
| constraint       | Relations constraint                            |
