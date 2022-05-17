---
title: Связи
layout: страница
---

## Автоматические Create/Update

GORM будет автоматически сохранять связи и их ссылки с помощью [Upsert](create.html#upsert) при создании/обновлении записи.

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

Если понадобится обновить данные связей, то следует использовать режим `FullSaveAssociations`:

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## Пропуск автоматических Create/Update

Чтобы пропустить автоматическое сохранение при `create` / `update`, можно воспользоваться `Select` либо `Omit`, пример:

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
// Пропустить создание <i>BillingAddress</i> при создании <i>user</i>

db.Omit(clause.Associations).Create(&user)
// Пропуск всех связей при создании <i>user</i>
```

{% note warn %}
**Примечание:** Для связей `many2many` GORM будет вставлять связи перед созданием ссылок на `join` таблицу, если понадобится пропустить вставку связей, то сделать это можно следующим образом:

```go
db.Omit("Languages.*").Create(&user)
```

Следующий код пропустит создание связи и ее ссылок

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## Выбрать/пропускать поля ассоциации

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// Create user and his BillingAddress, ShippingAddress
// When creating the BillingAddress only use its address1, address2 fields and omit others
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## Типы ассоциаций

Режим связывания включает некоторые часто используемые вспомогательные методы для обработки отношений

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source model, it must contains primary key
// `Languages` is a relationship's field name
// If the above two requirements matched, the AssociationMode should be started successfully, or it should return error
db.Model(&user).Association("Languages").Error
```

### Поиск связей

Поиск подходящей ассоциации

```go
db.Model(&user).Association("Languages").Find(&languages)
```

Поиск ассоциаций с условиями

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### Добавление связей

Добавление новых связей для `многие-ко-многим` `много`, заменяет текущие связи `один`, `принадлежит`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
```

### Замена связей

Замена текущих связей новыми

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Удаление связей

Удаление связи между источником и связанными аргументами приводит к удалению ссылки, но сами объекты из БД не удаляются.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Очистка связей

Удаляет все ссылки между источником и связью, не удаляя связь

```go
db.Model(&user).Association("Languages").Clear()
```

### Подсчет связей

Возвращает количество существующих связей

```go
db.Model(&user).Association("Languages").Count()

// Count with conditions
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Пакетная обработка

Режим связывания поддерживает пакетную обработку, пример:

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

## <span id="delete_with_select">Удаление связанных(ассоциируемых) записей</span>

Вы можете удалять указанные связи `has one` / `has many` / `many2many` по выборке `Select` при удалении записей, например:

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
/ DOESN'T WORK
db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{})
// will delete all user with name `jinzhu`, but those user's account won't be deleted

db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{ID: 1})
// will delete the user with name = `jinzhu` and id = `1`, and user `1`'s account will be deleted

db.Select("Account").Delete(&User{ID: 1})
// will delete the user with id = `1`, and user `1`'s account will be deleted
```
{% endnote %}

## <span id="tags">Теги связей(ассоциаций)</span>

| Тег              | Описание                                                                                                     |
| ---------------- | ------------------------------------------------------------------------------------------------------------ |
| foreignKey       | Указывает имя столбца текущей модели, которая используется в качестве внешнего ключа для соединяемой таблицы |
| references       | Задает имя столбца связанной таблицы, сопоставленной с внешним ключом объединенной таблицы                   |
| polymorphic      | Задает полиморфный тип, например название модели                                                             |
| polymorphicValue | Указывает полиморфное значение, название таблицы по умолчанию                                                |
| many2many        | Указывает имя таблицы связи                                                                                  |
| joinForeignKey   | Задает имя столбца внешнего ключа объединяемой таблицы, которое сопоставляется с текущей таблицей            |
| joinReferences   | Задает имя столбца внешнего ключа объединяемой таблицы, которое сопоставляется с связанной таблицей          |
| constraint       | Правила связей, например: `OnUpdate`,`OnDelete`                                                              |
