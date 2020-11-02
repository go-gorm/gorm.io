---
title: Удалить
layout: страница
---

## Удалить запись

При удалении записи, удаляемое значение должно иметь первичный ключ или сработает [пакетное удаление](#batch_delete), например:

```go
// ID в struct Email равно `10`
db.Delete(&email)
// DELETE from emails where id = 10;

// Удаление по условию
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE from emails where id = 10 AND name = "jinzhu";
```

## Удалить с помощью первичного ключа

GORM позволяет удалять объекты, используя первичный ключ(и) в строковом состоянии, работает с числами, смотрите [Запрос Inline Conditions](query.thml#inline_conditions) для получения подробностей

```go
db.Delete(&User{}, 10)
// DELETE FROM users WHERE id = 10;

db.Delete(&User{}, "10")
// DELETE FROM users WHERE id = 10;

db.Delete(&users, []int{1,2,3})
// DELETE FROM users WHERE id IN (1,2,3);
```

## Хуки удаления

GORM поддерживает хуки `BeforeDelete (перед удалением)`, `AfterDelete (после удаления)`, эти методы будут вызваны при удалении записи, смотрите [Хуки](hooks.html) для подробностей

```go
func (u *User) BeforeDelete(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to delete")
    }
    return
}
```

## <span id="batch_delete">Пакетное удаление</span>

Указанное условие не является первичным ключем. GORM будет выполнять пакетное удаление, он удалит все соответствующие записи

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### Глобальное удаление

Если вы выполняете пакетное удаление без условий, GORM не выполнит его и вернет ошибку `ErrMissingWhereClause`

Вы должны использовать любые условия, использовать raw SQL или включить режим `AllowGlobalUpdate` , например:

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE FROM `users` WHERE 1=1

db.Exec("DELETE FROM users")
// DELETE FROM users

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// DELETE FROM users
```

## Мягкое удаление

Если ваша модель включает в себя поле `gorm.DeletedAt` (которое включено в `gorm.Model`), она получит возможность магкого удаления автоматически!

При вызове метода `Delete`, запись не будет удалена из базы данных, GORM установит значение `DeletedAt`в текущее время, и данная запись больше не будет участвовать в обычном поиске.

```go
// ID пользователя `111`
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Пакетное удаление
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Записи удаленные магким удалением, будут пропущены при обычном запросе
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
