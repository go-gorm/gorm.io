---
title: Delete
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

Если модель имеет поле `DeletedAt`, она автоматически получит возможность мягкого удаления! При вызове `Delete`запись не будет навсегда удалена из базы данных; вместо этого, значение поля `DeletedAt` будет установлено на текущее unix время

```go
db.Delete(&user)
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Пакетное удаление
db.Where("age = ?", 20).Delete(&User{})
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Мягко удаленные записи будут проигнорированы при выборке
db.Where("age = 20").Find(&user)
//// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;

// Поиск мягко удаленных записей производится с использованием Unscoped метода
db.Unscoped().Where("age = 20").Find(&users)
//// SELECT * FROM users WHERE age = 20;
```

## Удалить запись навсегда

    // Удалить запись навсегда через Unscoped метод
    db.Unscoped().Delete(&order)
    //// DELETE FROM orders WHERE id=10;