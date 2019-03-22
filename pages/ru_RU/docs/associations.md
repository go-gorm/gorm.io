---
title: Связи
layout: page
---
## Авто Создание/Обновление

GORM будет автоматически сохранять связь и ее ссылку при создании/обновлении записи. Если связь имеет основной ключ, GORM вызовет `Update` записи, чтобы сохранить ее, иначе модель будет создана.

```go
user := User{
    Name:            "jinzhu",
    BillingAddress:  Address{Address1: "Billing Address - Address 1"},
    ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
    Emails:          []Email{
        {Email: "jinzhu@example.com"},
        {Email: "jinzhu-2@example@example.com"},
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

## Отключение авто обновления

Если связанная модель уже существует в базе данных и вы не хотите ее обновлять.

Вы можете использовать настройки БД, установив `gorm:association_autoupdate` в `false`

```go
// Не обновлять связь, с основным ключом, но сохранить ссылку
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
```

или используйте GORM теги, `gorm:"association_autoupdate:false"`

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // Don't update associations having primary key, but will save reference
  Company    Company `gorm:"association_autoupdate:false"`
}
```

## Отключение авто создания

Несмотря на то, что вы отключили `AutoUpdating`, связи без первичного ключа все еще будут создаваться и их ссылка будет сохранена.

Для отключения авто создания, вы можете установить параметр БД `gorm:association_autocreate` в `false`

```go
// Не создавать связи без первичного ключ
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)
```

или используйте GORM тег, `gorm:"association_autocreate:false"`

    type User struct {
      gorm.Model
      Name       string
      // Don't create associations w/o primary key, WON'T save its reference
      Company1   Company `gorm:"association_autocreate:false"`
    }
    

## Отключение авто создания/обновления

Чтобы отключить вместе `AutoCreate` и `AutoUpdate`, вы можете использовать эти две настройки вместе

```go
db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
```

Или использовать `gorm:save_associations`

    db.Set("gorm:save_associations", false).Create(&user)
    db.Set("gorm:save_associations", false).Save(&user)
    
    type User struct {
      gorm.Model
      Name    string
      Company Company `gorm:"association_autoupdate:false"`
    }
    

## Отключение сохранения ссылки

Если вы даже не хотите сохранять ссылку связи при обновлении/сохранении данных, вы можете использовать настройку ниже

```go
db.Set("gorm:association_save_reference", false).Save(&user)
db.Set("gorm:association_save_reference", false).Create(&user)
```

или использовать тег

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"association_save_reference:false"`
}
```

## Связь моделей

GORM поддерживает следующие методы для получения связей модели.

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source, must contains primary key
// `Languages` is source's field name for a relationship
// AssociationMode can only works if above two conditions both matched, check it ok or not:
// db.Model(&user).Association("Languages").Error
```

### Find Associations

Find matched associations

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### Append Associations

Append new associations for `many to many`, `has many`, replace current associations for `has one`, `belongs to`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
```

### Replace Associations

Replace current associations with new ones

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

Return the count of current associations

```go
db.Model(&user).Association("Languages").Count()
```