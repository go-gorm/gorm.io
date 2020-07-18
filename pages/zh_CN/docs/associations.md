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

如果存在，则删除源模型与参数之间的关系，只会删除引用，不会从数据库中删除这些对象。

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### 清空关联

删除源模型与关联之间的所有引用，但不会删除这些关联

```go
db.Model(&user).Association("Languages").Clear()
```

### 关联计数

返回当前关联的计数

```go
db.Model(&user).Association("Languages").Count()
```

### 批量处理数据

关联模式支持批量处理数据，例如：

```go
// 查询所有用户的所有角色
gorm.Model(&users).Association("Role").Find(&roles)

// 将 userA 移出所有的 Team
gorm.Model(&users).Association("Team").Delete(&userA)

// 获取所有 Team 成员的不重复计数。
gorm.Model(&users).Association("Team").Count()

// 对于 `Append`、`Replace` 的批量处理，参数与数据的长度必须相等，否则会返回错误
var users = []User{user1, user2, user3}
// 例如：我们有 3 个 user，将 userA 添加到 user1 的 Team，将 userB 添加到 user2 的 Team，将 userA、userB、userC 添加到 user3 的 Team。
gorm.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
//将 user1 的 Team 重置为 userA，将 user2的 team 重置为 userB，将 user3 的 team 重置为 userA、userB 和 userC。
gorm.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="tags">关联标签</span>

| 标签               | 描述                                              |
| ---------------- | ----------------------------------------------- |
| foreignKey       | Specifies foreign key                           |
| references       | Specifies references                            |
| polymorphic      | Specifies polymorphic type                      |
| polymorphicValue | Specifies polymorphic value, default table name |
| many2many        | Specifies join table name                       |
| jointForeignKey  | Specifies foreign key of jointable              |
| joinReferences   | Specifies references' foreign key of jointable  |
| constraint       | Relations constraint                            |
