---
title: Удалить
layout: страница
---

## Delete a Record

When deleting a record, the deleted value needs to have primary key or it will trigger a [Batch Delete](#batch_delete), for example:

```go
// Email's ID is `10`
db.Delete(&email)
// DELETE from emails where id = 10;

// Delete with additional conditions
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE from emails where id = 10 AND name = "jinzhu";
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

## <span id="batch_delete">Batch Delete</span>

The specified value has no priamry value, GORM will perform a batch delete, it will delete all matched records

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### Глобальное удаление

If you perform a batch delete without any conditions, GORM WON'T run it, and will return `ErrMissingWhereClause` error

You have to use some conditions or use raw SQL or enable `AllowGlobalUpdate` mode, for example:

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE FROM `users` WHERE 1=1

db.Exec("DELETE FROM users")
// DELETE FROM users

DB.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// DELETE FROM users
```

## Мягкое удаление

Если ваша модель включает в себя поле `gorm.DeletedAt` (которое включено в `gorm.Model`), она получит возможность магкого удаления автоматически!

При вызове метода `Delete`, запись не будет удалена из базы данных, GORM установит значение `DeletedAt`в текущее время, и данная запись больше не будет участвовать в обычном поиске.

```go
// user's ID is `111`
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Batch Delete
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Soft deleted records will be ignored when querying
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
