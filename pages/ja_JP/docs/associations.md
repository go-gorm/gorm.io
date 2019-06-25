---
title: Associations
layout: page
---

## Auto Create/Update

GORM はレコードの作成・更新時に関連および関連先を自動的に保存します。もし関連に主キーが含まれる場合、GORM は関連先の `Update` を保存時にコールし、そうでなければ作成します。

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

## Skip AutoUpdate

関連がすでにデータベースに存在する場合、更新したくないでしょう。

そのような場合は `gorm:association_autoupdate` を `false` に設定することができます。

```go
// 主キーがあっても関連を更新しませんが、参照は保存します
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
```

あるいは `gorm:"association_autoupdate:false"` タグを使用します。

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // Don't update associations having primary key, but will save reference
  Company    Company `gorm:"association_autoupdate:false"`
}
```

## Skip AutoCreate

自動更新を無効にしたにもかかわらず、主キーなしの関連付けを作成しなければならず、その参照も保存されます。

これを無効にするには、DB設定のgorm:association_autocreateをfalseに設定します

```go
// 主キーがあっても関連を更新しませんが、参照は保存します
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
```

または、GORMタグのgorm:"association_autocreate:false"を使用します。

    type User struct {
      gorm.Model
      Name       string
      // Don't create associations w/o primary key, WON'T save its reference
      Company1   Company `gorm:"association_autocreate:false"`
    }
    

## Skip AutoCreate/Update

`AutoCreate`と`AutUpdate`の両方を無効にしたい場合には、両方の設定を`false`にします。

```go
db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
```

もしくは、`gorm:save_associations`タグを使用します。

    db.Set("gorm:save_associations", false).Create(&user)
    db.Set("gorm:save_associations", false).Save(&user)
    
    type User struct {
      gorm.Model
      Name    string
      Company Company `gorm:"save_associations:false"`
    }
    

## Skip Save Reference

If you don't even want to save association's reference when updating/saving data, you could use below tricks

```go
db.Set("gorm:association_save_reference", false).Save(&user)
db.Set("gorm:association_save_reference", false).Create(&user)
```

or use tag

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"association_save_reference:false"`
}
```

## Association Mode

Associationモードには、リレーションを簡単に操作するためのいくつかのヘルパーメソッドがあります。

```go
// Associationモードを開始します
var user User 
db.Model(&user).Association("Languages")
// `user` は、ソースであり、主キーを持っている必要があります。 
// `Languages` は、リレーションのためのソースのフィールド名です。 
// Associationモードは、この2つの条件が満たされた時に動作します。
// これをチェックするためにはこのように書きます。
db.Model(&user).Association("Languages").Error
```

### Find Associations

条件に当てはまるassciationを見つけます。

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### Append Associations

`many to many`, `has many`の場合、新しいassociationを追加し、`has one`, `belogs to`の場合、現在のassociationと置き換えます。

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
```

### Replace Associations

現在のassociationを、新しいものと置き換えます。

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Delete Associations

Remove relationship between source & argument objects, only delete the reference, won't delete those objects from DB.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Clear Associations

Remove reference between source & current associations, won't delete those associations

```go
db.Model(&user).Association("Languages").Clear()
```

### Count Associations

現在のassociation数を数えて返します。

```go
db.Model(&user).Association("Languages").Count()
```