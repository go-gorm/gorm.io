---
title: Удаление
layout: страница
---
## Удаление записи

**ВНИМАНИЕ** При удалении записи, необходимо убедиться, что ее первичный ключ не пуст, и GORM будет использовать первичный ключ для удаления записи, если поле первичного ключа пусто, GORM удалит все записи для модели

```go
// Удаление существующей записи
db.Delete(&email)
//// DELETE from emails where id=10;

// Добавление SQL опции при удалении
db.Set("gorm:delete_option", "OPTION (OPTIMIZE FOR UNKNOWN)").Delete(&email)
//// DELETE from emails where id=10 OPTION (OPTIMIZE FOR UNKNOWN);
```

## Пакетное удаление

Удаление всех подходящих записей

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
//// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
//// DELETE from emails where email LIKE "%jinzhu%";
```

## Мягкое удаление

If a model has a `DeletedAt` field, it will get a soft delete ability automatically! When calling `Delete`, the record will not be permanently removed from the database; rather, the `DeletedAt`'s value will be set to the current time

```go
db.Delete(&user)
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Batch Delete
db.Where("age = ?", 20).Delete(&User{})
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Soft deleted records will be ignored when query them
db.Where("age = 20").Find(&user)
//// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;

// Find soft deleted records with Unscoped
db.Unscoped().Where("age = 20").Find(&users)
//// SELECT * FROM users WHERE age = 20;
```

## Delete record permanently

    // Delete record permanently with Unscoped
    db.Unscoped().Delete(&order)
    //// DELETE FROM orders WHERE id=10;