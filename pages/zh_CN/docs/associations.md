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
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "languages" ("name") VALUES ('ZH'), ('EN') ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "user_languages" ("user_id","language_id") VALUES (111, 1), (111, 2) ON DUPLICATE KEY DO NOTHING;
// COMMIT;

db.Save(&user)
```

如果您想要更新关联的数据，您应该使用 ` FullSaveAssociations ` 模式：

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
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
// Skip create BillingAddress when creating a user

db.Omit(clause.Associations).Create(&user)
// Skip all associations when creating a user
```

{% note warn %}
**NOTE:** 对于 many2many 关联，GORM 在创建连接表引用之前，会先 upsert 关联。如果你想跳过关联的 upsert，你可以这样做：

```go
db.Omit("Languages.*").Create(&user)
```

下面的代码将跳过创建关联及其引用

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## Select/Omit 关联字段

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// 创建 user 及其 BillingAddress、ShippingAddress
// 在创建 BillingAddress 时，仅使用其 address1、address2 字段，忽略其它字段
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## 关联模式

关联模式包含一些在处理关系时有用的方法

```go
// 开始关联模式
var user User
db.Model(&user).Association("Languages")
// `user` 是源模型，它的主键不能为空
// 关系的字段名是 `Languages`
// 如果匹配了上面两个要求，会开始关联模式，否则会返回错误
db.Model(&user).Association("Languages").Error
```

### 查找关联

查找所有匹配的关联记录

```go
db.Model(&user).Association("Languages").Find(&languages)
```

查找带条件的关联

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### 添加关联

为 `many to many`、`has many` 添加新的关联；为 `has one`, `belongs to` 替换当前的关联

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
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

// 条件计数
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### 批量处理数据

关联模式也支持批量处理，例如：

```go
// 查询所有用户的所有角色
db.Model(&users).Association("Role").Find(&roles)

// 将 userA 移出所有的 Team
db.Model(&users).Association("Team").Delete(&userA)

// 获取所有 Team 成员的不重复计数
db.Model(&users).Association("Team").Count()

// 对于 `Append`、`Replace` 的批量处理，参数与数据的长度必须相等，否则会返回错误
var users = []User{user1, user2, user3}
// 例如：我们有 3 个 user，将 userA 添加到 user1 的 Team，将 userB 添加到 user2 的 Team，将 userA、userB、userC 添加到 user3 的 Team
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// 将 user1 的 Team 重置为 userA，将 user2的 team 重置为 userB，将 user3 的 team 重置为 userA、userB 和 userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_with_select">Delete with Select</span>

你可以在删除记录时通过 `Select` 来删除具有 has one、has many、many2many 关系的记录，例如：

```go
// 删除 user 时，也删除 user 的 account
db.Select("Account").Delete(&user)

// 删除 user 时，也删除 user 的 Orders、CreditCards 记录
db.Select("Orders", "CreditCards").Delete(&user)

// 删除 user 时，也删除用户所有 has one/many、many2many 记录
db.Select(clause.Associations).Delete(&user)

// 删除 user 时，也删除 user 的 account
db.Select("Account").Delete(&users)
```

## <span id="tags">关联标签</span>

| 标签               | 描述                            |
| ---------------- | ----------------------------- |
| foreignKey       | 指定外键                          |
| references       | 指定引用                          |
| polymorphic      | 指定多态类型                        |
| polymorphicValue | 指定多态值、默认表名                    |
| many2many        | 指定连接表表名                       |
| joinForeignKey   | 指定连接表的外键                      |
| joinReferences   | 指定连接表的引用外键                    |
| constraint       | 关系约束，例如：`OnUpdate`、`OnDelete` |
