---
title: Связи
layout: страница
---

## Авто Создание/Обновление

GORM будет автоматически сохранять ассоциации и их ссылки с помощью [Upsert](create.html#upsert) при создании/обновлении записи.

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

## Пропустить автоматическое создание/обновление

Чтобы пропустить автоматическое сохранение при создании/обновлении, вы можете использовать `Select` или `Omit`, например:

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
// Пропустить создание BillingAddress когда создается user

db.Omit(clause.Associations).Create(&user)
// Пропустить все связи при создании user
```

## Режим связи

Режим связи содержит некоторые часто используемые методы для управления отношениями

```go
// Начало режима связей
var user User
db.Model(&user).Association("Languages")
// `user` это исходная модель, должна содержать первичный ключ
// `Languages` это название поля для связи
// Если оба выше указанных условия совпадают, режим связи AssociationMode должен быть запущен успешно, или вернет ошибку
db.Model(&user).Association("Languages").Error
```

### Найти связи

Найти подходящие связи

```go
db.Model(&user).Association("Languages").Find(&languages)

// Найти с условиями
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)
```

### Добавить связи

Добавление новых связей `многие ко многим`, `один ко многим`, замена текущих связей для `имеет одну`, `принадлежит`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(CreditCard{Number: "411111111111"})
```

### Заменить связи

Заменить текущие связи новыми

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Удалить связи

Удалить связь между источником & аргументом, если таковые существуют, только удалить ссылку, не удалять эти объекты из БД.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Очистить связи

Удалить все связи между источником & связанной таблицей, не будут удалять эти записи в связанной таблице

```go
db.Model(&user).Association("Languages").Clear()
```

### Количество связей

Возвращает количество существующих связей

```go
db.Model(&user).Association("Languages").Count()
```

### Пакетные данные

Режим ассоциации поддерживает пакетные данные, например:

```go
// Find all roles for all users
db.Model(&users).Association("Role").Find(&roles)

// Delete User A from all users's team
db.Model(&users).Association("Team").Delete(&userA)

// Get unduplicated count of members in all user's team
db.Model(&users).Association("Team").Count()

// For `Append`, `Replace` with batch data, arguments's length need to equal to data's length or will returns error
var users = []User{user1, user2, user3}
// e.g: we have 3 users, Append userA to user1's team, append userB to user2's team, append userA, userB and userC to user3's team
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Reset user1's team to userA，reset user2's team to userB, reset user3's team to userA, userB and userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="tags">Теги связей</span>

| Тег              | Описание                                                                    |
| ---------------- | --------------------------------------------------------------------------- |
| foreignKey       | Определяет внешний ключ                                                     |
| references       | Указывает ссылки                                                            |
| polymorphic      | Определяет полиморфический тип                                              |
| polymorphicValue | Указывает значение полиморфического значения, название таблицы по умолчанию |
| many2many        | Указывает имя таблицы связи                                                 |
| jointForeignKey  | Определяет внешний ключ объединения                                         |
| joinReferences   | Определяет внешний ключ объединения                                         |
| constraint       | Ограничение связей                                                          |
