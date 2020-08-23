---
title: Удалить
layout: страница
---

## Удалить запись

Удалить запись

```go
// Удалить существующую запись в таблице emails, где первичный ключ равен 10, переданный в переменной email
db.Delete(&email)
// DELETE from emails where id=10;

// УДАЛИТЬ с помощью передаваемых значений
db.Delete(&Email{}, 20)
// DELETE from emails where id=20;

// УДАЛИТЬ с помощью дополнительных условий
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE FROM emails WHERE id=10 AND name = 'jinzhu'
```

## Хуки удаления

GORM поддерживает хуки `BeforeDelete (перед удалением)`, `AfterDelete (после удаления)`, эти методы будут вызваны при удалении записи, смотрите [Хуки](hooks.html) для подробностей

```go
func (u *User) BeforeDelete(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("пользователь с ролью admin не может быть удален")
    }
    return
}
```

## Пакетное удаление

Если мы не указали первичный ключ, GORM выполнит пакетное удаление всех совпадающих записей

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### Глобальное удаление

Если вы выполняете пакетное удаление без условий, GORM не выполнит его и вернет ошибку `ErrMissingWhereClause`

You have to use some conditions or use raw SQL or enable `AllowGlobalUpdate` mode, for example:

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE `users` WHERE 1=1

DB.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// UPDATE users SET `name` = "jinzhu"
```

## Мягкое удаление

Если ваша модель включает в себя поле `gorm.DeletedAt` (которое включено в `gorm.Model`), она получит возможность магкого удаления автоматически!

При вызове метода `Delete`, запись не будет удалена из базы данных, GORM установит значение `DeletedAt`в текущее время, и данная запись больше не будет участвовать в обычном поиске.

```go
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Пакетное удаление
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Мягкое удаление записей, будет проигнорировано при получении записей из БД
db.Where("age = 20").Find(&user)
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

Если вы не хотите использовать `gorm.Model`, вы можете включить мягкое удаление:

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### Найти мягко удаленные записи

Вы можете найти мягко удаленные записи с помощью `Unscoped`

```go
db.Unscoped().Where("age = 20").Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### Удалить безвозвратно

Вы можете удалить записи навсегда с помощью `Unscoped`

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```
