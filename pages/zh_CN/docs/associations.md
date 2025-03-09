---
title: 实体关联
layout: page
---

## 自动创建、更新

GORM在创建或更新记录时会自动地保存其关联和引用，主要使用upsert技术来更新现有关联的外键引用。

### 在创建时自动保存关联

当你创建一条新的记录时，GORM会自动保存它的关联数据。 这个过程包括向关联表插入数据以及维护外键引用。

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

// 创建用户及其关联的地址、电子邮件和语言
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

### 通过`FullSaveAssociations`来更新关联

对于需要全面更新关联数据（不止外键）的情况，就应该使用 `FullSaveAssociations` 方法。

```go
// 更新用户并完全更新其所有关联
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// SQL：完全更新地址、用户、电子邮件表，包括现有的关联记录
```

使用`FullSaveAssociations` 方法来确保模型的整体状态，包括其所有关联都反映在了数据库中，从在应用中保持数据的完整性和一致性。

## 跳过自动创建、更新

GORM 提供了在创建或更新操作过程中跳过自动保存关联的灵活性。 通过使用`Select`或者`Omit`方法可以允许您指定具体哪些字段在操作中被包含或者排除

### 使用`Select` 来指定字段范围

`Select`方法可以让您模型中的哪些字段应该被保存 也就是说只有被选中的字段会被包含在SQL中

```go
user := User{
  // 用户及关联的数据
}

// 当插入用户的时候仅包含“Name”字段
db.Select("Name").Create(&user)
// SQL: INSERT INTO "users" (name) VALUES ("jinzhu");
```

### 使用`Omit`来排除字段或关联

```go
// 创建用户时跳过字段“BillingAddress”
db.Omit("BillingAddress").Create(&user)

// 创建用户时跳过全部关联关系
db.Omit(clause.Associations).Create(&user)
```

{% note warn %}
**注意:** 对于多对多关联关系, GORM 会在创建连接表引用之前更新关联。 要跳过更新，可以使用`Omit`，参数为关联名后面跟着`.*`

```go
// 跳过更新"Languages"关联
db.Omit("Languages.*").Create(&user)
```

跳过创建关联及其引用：

```go
// 跳过创建 'Languages' 关联及其引用
db.Omit("Languages").Create(&user)
```
{% endnote %}

通过使用 `Select` 和 `Omit`，你能够很好地调整GORM处理创建或更新您的模型的行为，同时让您也能控制关联关系的自动保存行为

## Select/Omit 关联字段

在GORM中创建或者更新记录时，可以使用`Select`和`Omit`方法来指定是否包含某个关联的字段

使用`Select`，你能够指定关联模型中的特定字段在保存主模型的时候是否被包含 在仅保存部分关联时这非常有用

而`Omit`则能够排除关联模型的特定字段。 这可能会在你想阻止关联模型的特定部分被更新时有用


```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// 创建用户和他的账单地址,邮寄地址,只包括账单地址指定的字段
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)
// SQL: 只使用地址1和地址2来创建用户和账单地址

// 创建用户和账单地址,邮寄地址,但不包括账单地址的指定字段
db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
// SQL: 创建用户和账单地址,省略'地址2'和创建时间字段
```

## 删除关联

GORM 能在删除主模型时使用`Select`方法来删除关联关系(一对一、一对多、多对多)。 在删除时维护好数据完整性并确保关联数据被妥当管理上，这项特性非常有用。

你可以用`Select`来指定哪些关联应该随着主模型被删除

```go
//删除用户时，也删除用户的帐户
db.Select("Account").Delete(&user)

// 删除 user 时，也删除 user 的 Orders、CreditCards 关联记录
db.Select("Orders", "CreditCards").Delete(&user)

// 删除用户 时，也删除用户的所有一对一、一对多和多对多关联
db.Select(clause.Associations).Delete(&user)

// 删除多个用户时，也同步删除每个用户的账户信息。
db.Select("Account").Delete(&users)
```

{% note warn %}
**注意：**请务必注意，仅当删除记录的主键不为零时，才会删除关联。 GORM 使用这些主键作为删除所选关联的条件。

```go
// 这样无法实现预期效果
db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{})
// SQL: 删除所有名为 'jinzhu' 的用户，但这些用户的关联账户不会被删除

// 正确删除用户及其账户的方式
db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{ID: 1})
// SQL: 删除名为 'jinzhu' 且 ID 为 '1' 的用户及其关联账户

// 删除指定 ID 用户及其账户db.Select("Account").Delete(&User{ID: 1})
// SQL: 删除 ID 为 '1' 的用户及其关联账户
```
{% endnote %}

## 关联模式

Association Mode in GORM offers various helper methods to handle relationships between models, providing an efficient way to manage associated data.

To start Association Mode, specify the source model and the relationship's field name. The source model must contain a primary key, and the relationship's field name should match an existing association.

```go
var user User
db.Model(&user).Association("Languages")
// Check for errors
error := db.Model(&user).Association("Languages").Error
```

### 查询关联

Retrieve associated records with or without additional conditions.

```go
// Simple find
db.Model(&user).Association("Languages").Find(&languages)

// Find with conditions
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)
```

### 追加关联

Add new associations for `many to many`, `has many`, or replace the current association for `has one`, `belongs to`.

```go

```

### 替换关联

```go
// Replace existing languages
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### 删除关联

Remove the relationship between the source and arguments, only deleting the reference.

```go
// Delete specific languages
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### 清空关联

Remove all references between the source and association.

```go
// Clear all languages
db.Model(&user).Association("Languages").Clear()
```

### 关联计数

Get the count of current associations, with or without conditions.

```go
// Count all languages
db.Model(&user).Association("Languages").Count()

// Count with conditions
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### 批量数据处理

Association Mode allows you to handle relationships for multiple records in a batch. This includes finding, appending, replacing, deleting, and counting operations for associated data.

- **Finding Associations**: Retrieve associated data for a collection of records.

```go
db.Model(&users).Association("Role").Find(&roles)
```

- **Deleting Associations**: Remove specific associations across multiple records.

```go
db.Model(&users).Association("Team").Delete(&userA)
```

- **Counting Associations**: Get the count of associations for a batch of records.

```go
db.Model(&users).Association("Team").Count()
```

- **Appending/Replacing Associations**: Manage associations for multiple records. Note the need for matching argument lengths with the data.

```go
var users = []User{user1, user2, user3}

// Append different teams to different users in a batch
// Append userA to user1's team, userB to user2's team, and userA, userB, userC to user3's team
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})

// Replace teams for multiple users in a batch
// Reset user1's team to userA, user2's team to userB, and user3's team to userA, userB, and userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_association_record">删除关联记录</span>

In GORM, the `Replace`, `Delete`, and `Clear` methods in Association Mode primarily affect the foreign key references, not the associated records themselves. Understanding and managing this behavior is crucial for data integrity.

- **Reference Update**: These methods update the association's foreign key to null, effectively removing the link between the source and associated models.
- **No Physical Record Deletion**: The actual associated records remain untouched in the database.

### 通过`Unscoped`来变更默认的删除行为

For scenarios requiring actual deletion of associated records, the `Unscoped` method alters this behavior.

- **Soft Delete**: Marks associated records as deleted (sets `deleted_at` field) without removing them from the database.

```go
db.Model(&user).Association("Languages").Unscoped().Clear()
```

- **Permanent Delete**: Physically deletes the association records from the database.

```go
// db.Unscoped().Model(&user)
db.Unscoped().Model(&user).Association("Languages").Unscoped().Clear()
```

## <span id="tags">关联标签（Association Tags）</span>

GORM中的关联标签通常用于指定如何处理模型之间的关联。 这些标签定义了一些关系细节，比如外键，引用和约束。 理解这些标签对于有效地建立和管理模型之间的关系而言至关重要。

| 标签                 | 描述                                                                                               |
| ------------------ | ------------------------------------------------------------------------------------------------ |
| `foreignKey`       | Specifies the column name of the current model used as a foreign key in the join table.          |
| `references`       | Indicates the column name in the reference table that the foreign key of the join table maps to. |
| `polymorphic`      | Defines the polymorphic type, typically the model name.                                          |
| `polymorphicValue` | Sets the polymorphic value, usually the table name, if not specified otherwise.                  |
| `many2many`        | Names the join table used in a many-to-many relationship.                                        |
| `joinForeignKey`   | Identifies the foreign key column in the join table that maps back to the current model's table. |
| `joinReferences`   | Points to the foreign key column in the join table that links to the reference model's table.    |
| `constraint`       | Specifies relational constraints like `OnUpdate`, `OnDelete` for the association.                |
