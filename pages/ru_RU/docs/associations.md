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


## Режим связывания

Режим связывания включает некоторые часто используемые вспомогательные методы для обработки отношений

```go
// Начало режима связывания
var user User
db.Model(&user).Association("Languages")
// где <i>user</i> главная модель, она должна содержать первичный ключ
// а <i>Languages</i> является полем отношения
// Если два вышеуказанных требования совпадают, то режим связывания должен успешно запуститься либо вернуть ошибку
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

// Подсчет с условиями
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Пакетная обработка

Режим связывания поддерживает пакетную обработку, пример:

```go
// Поиск всех <i>Role</i> по всем <i>users</i>
db.Model(&users).Association("Role").Find(&roles)

// Удаление <i>userA</i> из всех <i>users.Team</i>
db.Model(&users).Association("Team").Delete(&userA)

// Получение количества неповторяющихся <i>users</i> членов во всех <i>users.Team</i>
db.Model(&users).Association("Team").Count()

// Для добавления и замены пакетными данными, необходимо чтобы аргумент размерности соответствовал размеру данных, в противном случае вернётся ошибка
var users = []User{user1, user2, user3}
// т.е.: есть у нас 3 <i>users</i>, добавляем <i>userA</i> к <i>user1.Team</i>, добавляем <i>userB</i> к <i>user2.Team</i>, добавляем <i>userA</i>, <i>userB</i> и <i>userC</i> к <i>user3.Team</i>
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Сброс <i>user1.Team</i> до userA, сброс <i>user2.Team</i> к <i>userB</i>, сброс <i>user3.Team</i> к <i>userA</i>, <i>userB</i> и <i>userC</i>
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_with_select">Delete по Select</span>

Вы можете удалять указанные связи `has one` / `has many` / `many2many` по выборке `Select` при удалении записей, например:

```go
// удаление <i>user.Account</i> при удалении <i>user</i>
db.Select("Account").Delete(&user)

// удаление <i>user.Orders</i>, <i>user.CreditCards</i> отношения при удалении <i>user</i>
db.Select("Orders", "CreditCards").Delete(&user)

// удаления связей <i>user</i> <i>has one</i>/<i>many</i>/<i>many2many</i> при удалении <i>user</i>
db.Select(clause.Associations).Delete(&user)

// удаление <i>user.Account</i> при удалении <i>users</i>
db.Select("Account").Delete(&users)
```

## <span id="tags">Теги для связей</span>

| Тег              | Описание                                                      |
| ---------------- | ------------------------------------------------------------- |
| foreignKey       | Определяет внешний ключ                                       |
| references       | Указывает ссылки                                              |
| polymorphic      | Определяет полиморфный тип                                    |
| polymorphicValue | Указывает полиморфное значение, название таблицы по умолчанию |
| many2many        | Указывает имя таблицы связи                                   |
| joinForeignKey   | Определяет внешний ключ `join` таблицы                        |
| joinReferences   | Определяет внешний `join` таблицы                             |
| constraint       | Правила связей, например: `OnUpdate`,`OnDelete`               |
