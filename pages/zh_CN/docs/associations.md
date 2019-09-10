---
title: 关联
layout: page
---

## 自动创建/更新

创建/更新记录时, GORM 将自动保存关联及其引用。如果关联具有主键, GORM 将调用 ` Update ` 来保存它, 否则将创建它。

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
//// BEGIN TRANSACTION;
//// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1");
//// INSERT INTO "addresses" (address1) VALUES ("Shipping Address - Address 1");
//// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
//// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com");
//// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu-2@example.com");
//// INSERT INTO "languages" ("name") VALUES ('ZH');
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 1);
//// INSERT INTO "languages" ("name") VALUES ('EN');
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 2);
//// COMMIT;

db.Save(&user)
```

## 跳过自动更新

如果数据库中已存在关联, 你可能不希望对其进行更新。

可以使用 DB 设置, 将 ` gorm: association_autoupdate ` 设置为 ` false `

```go
// Don't update associations having primary key, but will save reference
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
```

或者使用 GORM tags `gorm:"association_autoupdate:false"`

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // Don't update associations having primary key, but will save reference
  Company    Company `gorm:"association_autoupdate:false"`
}
```

## 跳过自动创建

即使你禁用了 `AutoUpdating`，没有主键的关联仍然会被创建，所有关联的引用也会被保存。

如果你也想跳过，那么你可以通过 DB 的设置，将`gorm:association_autocreate`设置为`false`

```go
// Don't create associations w/o primary key, WON'T save its reference
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)
```

或使用 GORM tags ` GORM: "association_autocreate: false" `

    type User struct {
      gorm.Model
      Name       string
      // Don't create associations w/o primary key, WON'T save its reference
      Company1   Company `gorm:"association_autocreate:false"`
    }
    

## 跳过自动创建及更新

若要禁用 `自动创建` 及 `自动更新`, 可以将这两个设置一起使用

```go
db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
```

或使用 GORM Tag ` gorm: save_associations `

    db.Set("gorm:save_associations", false).Create(&user)
    db.Set("gorm:save_associations", false).Save(&user)
    
    type User struct {
      gorm.Model
      Name    string
      Company Company `gorm:"association_autoupdate:false"`
    }
    

## 跳过引用的保存

如果你不想保存关联的引用，那么你可以使用下面的技巧

```go
db.Set("gorm:association_save_reference", false).Save(&user)
db.Set("gorm:association_save_reference", false).Create(&user)
```

或者使用 GORM Tag

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"association_save_reference:false"`
}
```

## 关联模式

关联模式包含几个帮助方法，可以更方便的来管理关联

```go
// 开始使用关联模式
var user User
db.Model(&user).Association("Languages")
// `user` 是源，必须包含主键
// `Languages` 是关系中的源的字段名
// 只有在满足上面两个条件时，关联模式才能正常工作，请注意检查错误：
// db.Model(&user).Association("Languages").Error
```

### 查找关联

查找匹配的关联

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### 添加关联

为`many to many`，`has many`添加新的关联关系代替当前的关联关系`has one`，`belongs to`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
```

### 替换关联

使用新关联替换当前关联

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### 删除关联

删除关联的引用，不会删除关联本身

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### 清空关联

清空对关联的引用，不会删除关联本身

```go
db.Model(&user).Association("Languages").Clear()
```

### 关联的数量

返回关联的数量

```go
db.Model(&user).Association("Languages").Count()
```