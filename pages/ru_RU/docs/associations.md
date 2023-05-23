---
title: Связи
layout: страница
---

## Автоматические Create/Update

GORM будет автоматически сохранять связи и их ссылки с помощью [Upsert](create.html#upsert) при создании/обновлении записи.

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Платежный адрес - Адрес 1"},
  ShippingAddress: Address{Address1: "Адрес доставки - Адрес 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "RU"},
    {Name: "EN"},
  },
}

db.Create(&user)
// BEGIN TRANSACTION;
// INSERT INTO "addresses" (address1) VALUES ("Платежный адрес - Адрес 1"), ("Адрес доставки - Адрес 1") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "languages" ("name") VALUES ('RU'), ('EN') ON DUPLICATE KEY DO NOTHING;
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
  Name:            "jenya",
  BillingAddress:  Address{Address1: "Платежный адрес - Адрес 1", Address2: "адрес2"},
  ShippingAddress: Address{Address1: "Адрес доставки - Адрес 1", Address2: "адрес2"},
}

// Создать пользователя его платежный адрес и адрес доставки
// При создании BillingAddress используйте только его поля address1, address2 и опускайте другие
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## Типы ассоциаций

Режим связывания включает некоторые часто используемые вспомогательные методы для обработки отношений

```go
// Старт режима ассоциаций
var user User
db.Model(&user).Association("Languages")
// `пользователь` - это исходная модель, она должна содержать первичный ключ
// `Languages` - это имя связанного поля
// Если два вышеуказанных требования совпадают, AssociationMode должен быть запущен успешно, иначе он должен возвратить ошибку
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

// Количество с учетом условий
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Пакетная обработка

Режим связывания поддерживает пакетную обработку, пример:

```go
// Найти все роли для всех пользователей
db.Model(&users).Association("Role").Find(&roles)

// Удалить пользователя A из всех команд, в которых пользователь состоит
db.Model(&users).Association("Team").Delete(&userA)

// Получить distinct количество всех команд пользователя
db.Model(&users).Association("Team").Count()

// Для `Append`, `Replace` с пакетными данными длина аргументов должна быть равна длине данных, иначе будет возвращена ошибка
var users = []User{user1, user2, user3}

// Например: у нас есть 3 пользователя, добавляем UserA в команду user1, UserB в команду user2, добавляем UserA, UserB и UserC в команду user3
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})

// Сбросить команду UserA у пользователя user1, сбросить команду UserB у пользователя user2, сбросить команды UserA, UserB и UserC у пользователя user3
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_association_record">Удаление связей</span>

По умолчанию, `Replace`/`Delete`/`Clear` в `gorm.Association` удаляет только ссылку, то есть устанавливает для внешнего ключа значение null.

Вы можете удалить эти объекты с помощью `Unscoped` (это не имеет ничего общего с `ManyToMany`).

Способ удаления определяется в `gorm.DB`.

```go
// Мягкое удаление
// UPDATE `languages` SET `deleted_at`= ...
db.Model(&user).Association("Languages").Unscoped().Clear()

// Удалить безвозвратно
// DELETE FROM `languages` WHERE ...
db.Unscoped().Model(&item).Association("Languages").Unscoped().Clear()
```

## <span id="delete_with_select">Удалить с помощью Select</span>

Вам разрешено удалять выбранные has one/has many/many2many отношения с помощью `Select` при удалении записей, например:

```go
// удалить учетную запись пользователя при удалении пользователя
db.Select("Account").Delete(&user)

// удалить заказы пользователя, связи с кредитными картами при удалении пользователя
db.Select("Orders", "CreditCards").Delete(&user)

// удалить пользователя имеет отношение one/many/many2many при удалении пользователя
db.Select(clause.Associations).Delete(&user)

// удалить учетную запись каждого пользователя при удалении пользователей
db.Select("Account").Delete(&users)
```

{% note warn %}
**ПРИМЕЧАНИЕ:** Ассоциации будут удалены только в том случае, если первичный ключ удаляемых записей не равен нулю, GORM будет использовать эти первичные ключи в качестве условий для удаления выбранных связей

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

## <span id="tags">Теги связей</span>

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
