---
title: Associations
layout: page
---

## Otomatik Oluşturma/Güncelleme

GORM, referans objeyi ve bu referansın ilişkilerini [Upsert](create.html#upsert) metodu ile otomatik olarak kaydedebilir/güncelleyebilir.

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

Eğer ilişkili veriyi güncellemek istiyorsanız `FullSaveAssociations` modunu kullanmalısınız:

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## Otomatik Oluşturma/Güncellemeyi Atlama

`Select` veya `Omit` kullanarak oluşturma/güncelleme işleminin etkilediği ilişkileri/entityleri değiştirebilirsiniz:

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
// BillingAddress oluşturmadan user oluştur

db.Omit(clause.Associations).Create(&user)
// user oluştururken hiçbir ilişki oluşturma
```

{% note warn %}
**NOT:** Çoka çok ilişkiler için, GORM join tablosu referanslarından önce ilişkileri upsert(varsa güncelle, yoksa oluştur) edecektir, upsert adımını şu şekilde atlayabilirsiniz:

```go
db.Omit("Languages.*").Create(&user)
```

The following code will skip the creation of the association and its references

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## İlişkisel Alanlar(Fields) ve Select/Omit

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// user ile user'a ait BillingAddress ve ShippingAddress'i oluştur
// BillingAddress'i oluştururken sadece address1, address2 alanlarını kullan ve diğerlerini yoksay
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## İlişki Modu

İlişki modu, ilişkileri idare etmek için sıklıkla kullanılan yardımcı metodları içerir

```go
// İlişki modunu başlat
var user User
db.Model(&user).Association("Languages")
// `user` kaynak model olarak primary key'e sahip olmalıdır
// `Languages` ilişkinin field adıdır
// Eğer yukarıdaki şartlar sağlanırsa, ilişki modu(AssociationMode) başlar, veya hata döndürür
db.Model(&user).Association("Languages").Error
```

### İlişkileri Bul

Eşleşen ilişkileri bul

```go
db.Model(&user).Association("Languages").Find(&languages)
```

Belirli şartlara bağlı olarak ilişkileri bul

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### İlişki Ekle

`Çoka çok`, `bire çok`, ilişkilere yenisini eklemek; `bire bir`, `sahiplik` ilişkilerini değiştirmek için

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
```

### İlişkileri Değiştir

Şu anki ilişkileri yenisiyle değiştirmek için

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### İlişkileri Sil

Kaynak ve parametre arasında ilişki varsa siler, sadece referansı siler ve veritabanındaki objeleri silmez.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### İlişkileri Temizle

Kaynak & ilişki arasındaki tüm referansları siler, ilintili ilişkiyi silmez

```go
db.Model(&user).Association("Languages").Clear()
```

### İlişki Sayısı

Var olan ilişkilerin sayısını döndürür

```go
db.Model(&user).Association("Languages").Count()

// Şartlara uyan ilişki sayısı 
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Toplu Veri

İlişki modu toplu veri işlemlerini destekler:

```go
// Find all roles for all users
db.Model(&users).Association("Role").Find(&roles)

// Delete User A from all user's team
db.Model(&users).Association("Team").Delete(&userA)

// Get distinct count of all users' teams
db.Model(&users).Association("Team").Count()

// For `Append`, `Replace` with batch data, the length of the arguments needs to be equal to the data's length or else it will return an error
var users = []User{user1, user2, user3}
// e.g: we have 3 users, Append userA to user1's team, append userB to user2's team, append userA, userB and userC to user3's team
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Reset user1's team to userA，reset user2's team to userB, reset user3's team to userA, userB and userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_association_record">Delete Association Record</span>

By default, `Replace`/`Delete`/`Clear` in `gorm.Association` only delete the reference, that is, set old associations's foreign key to null.

You can delete those objects with `Unscoped` (it has nothing to do with `ManyToMany`).

How to delete is decided by `gorm.DB`.

```go
// Soft delete
// UPDATE `languages` SET `deleted_at`= ...
db.Model(&user).Association("Languages").Unscoped().Clear()

// Delete permanently
// DELETE FROM `languages` WHERE ...
db.Unscoped().Model(&item).Association("Languages").Unscoped().Clear()
```

## <span id="delete_with_select">Delete with Select</span>

You are allowed to delete selected has one/has many/many2many relations with `Select` when deleting records, for example:

```go
// delete user's account when deleting user
db.Select("Account").Delete(&user)

// delete user's Orders, CreditCards relations when deleting user
db.Select("Orders", "CreditCards").Delete(&user)

// delete user's has one/many/many2many relations when deleting user
db.Select(clause.Associations).Delete(&user)

// delete each user's account when deleting users
db.Select("Account").Delete(&users)
```

{% note warn %}
**NOTE:** Associations will only be deleted if the deleting records's primary key is not zero, GORM will use those primary keys as conditions to delete selected associations

```go
// DOESN'T WORK
db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{})
// will delete all user with name `jinzhu`, but those user's account won't be deleted

db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{ID: 1})
// will delete the user with name = `jinzhu` and id = `1`, and user `1`'s account will be deleted

db.Select("Account").Delete(&User{ID: 1})
// will delete the user with id = `1`, and user `1`'s account will be deleted
```
{% endnote %}

## <span id="tags">Association Tags</span>

| Tag              | Description                                                                                        |
| ---------------- | -------------------------------------------------------------------------------------------------- |
| foreignKey       | Specifies column name of the current model that is used as a foreign key to the join table         |
| references       | Specifies column name of the reference's table that is mapped to the foreign key of the join table |
| polymorphic      | Specifies polymorphic type such as model name                                                      |
| polymorphicValue | Specifies polymorphic value, default table name                                                    |
| many2many        | Specifies join table name                                                                          |
| joinForeignKey   | Specifies foreign key column name of join table that maps to the current table                     |
| joinReferences   | Specifies foreign key column name of join table that maps to the reference's table                 |
| constraint       | Relations constraint, e.g: `OnUpdate`,`OnDelete`                                                   |
