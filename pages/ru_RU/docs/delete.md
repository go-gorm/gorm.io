---
title: Delete
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

GORM позволяет удалять объекты по первичному ключу (ключам) с помощью встроенного условия, оно работает с числами, подробности смотрите в [Query Inline Conditions](query.html#inline_conditions)

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

Первичный ключ не указан и GORM выполнит пакетное удаление, при этом будут удалены все совпадающие записи

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(&Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(&Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

Чтобы эффективно удалить большое количество записей, передайте фрагмент с первичными ключами методу `Delete`.

```go
var users = []User{{ID: 1}, {ID: 2}, {ID: 3}}
db.Delete(&users)
// DELETE FROM users WHERE id IN (1,2,3);

db.Delete(&users, "name LIKE ?", "%jinzhu%")
// DELETE FROM users WHERE name LIKE "%jinzhu%" AND id IN (1,2,3); 
```

### Запрет глобального удаления

Если вы выполните пакетное удаление без каких-либо условий, GORM НЕ запустит его и вернет ошибку `ErrMissingWhereClause`

Вы должны использовать некоторые условия, или использовать необработанный SQL, или включить режим `AllowGlobalUpdate`, например:

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Delete(&[]User{{Name: "jinzhu1"}, {Name: "jinzhu2"}}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE FROM `users` WHERE 1=1

db.Exec("DELETE FROM users")
// DELETE FROM users

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// DELETE FROM users
```

### Возврат данных при удалении строк

Возвращает удаленные данные, работает только для базы данных поддерживающих Возврат, например:

```go
// вернуть все колонки
var users []User
DB.Clauses(clause.Returning{}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING *
// users => []User{{ID: 1, Name: "jinzhu", Role: "admin", Salary: 100}, {ID: 2, Name: "jinzhu.2", Role: "admin", Salary: 1000}}

// вернуть требуемые колонки
DB.Clauses(clause.Returning{Columns: []clause.Column{{Name: "name"}, {Name: "salary"}}}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING `name`, `salary`
// users => []User{{ID: 0, Name: "jinzhu", Role: "", Salary: 100}, {ID: 0, Name: "jinzhu.2", Role: "", Salary: 1000}}
```

## Мягкое удаление

Если ваша модель включает в себя поле `gorm.DeletedAt` (которое включено в `gorm.Model`), она автоматически получит возможность мягкого удаления!

При вызове `Delete` запись НЕ будет удалена из базы данных, но GORM установит значение `DeletedAt` на текущее время, и данные больше не будут доступны для поиска обычными методами запроса.

```go
// ID пользователя равно `111`
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Пакетное удаление
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Автоматически удаленные записи будут проигнорированы при запросе
db.Where("age = 20").Find(&user)
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

Если вы не хотите включать `gorm.Model`, вы можете включить функцию мягкого удаления следующим образом:

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### Найти записи после мягкого удаления

Вы можете найти автоматически удаленные записи с помощью `Unscoped`

```go
db.Unscoped().Where("age = 20").Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### Безвозвратное удаление

Вы можете навсегда удалить совпадающие записи с помощью `Unscoped`

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```

### Флаги удаления

По умолчанию `gorm.Model` использует `*time.Time` в качестве значения для поля `DeletedAt`, и оно обеспечивает поддержку других форматов данных с помощью плагина `gorm.io/plugin/soft_delete `

{% note warn %}
**ИНФОРМАЦИЯ** при создании уникального составного индекса для поля DeletedAt вы должны использовать другой формат данных, например unix second/flag с плагином `gorm.io/plugin/soft_delete`, например:

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string                `gorm:"uniqueIndex:udx_name"`
  DeletedAt soft_delete.DeletedAt `gorm:"uniqueIndex:udx_name"`
}
```
{% endnote %}

#### Unix Second

Используйте unix second в качестве флага удаления

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string
  DeletedAt soft_delete.DeletedAt
}

// Запрос
SELECT * FROM users WHERE deleted_at = 0;

// Удаление
UPDATE users SET deleted_at = /* current unix second */ WHERE ID = 1;
```

Вы также можете указать, что в качестве значения следует использовать `milli` или `nano` секунды, например:

```go
type User struct {
  ID    uint
  Name  string
  DeletedAt soft_delete.DeletedAt `gorm:"softDelete:milli"`
  // DeletedAt soft_delete.DeletedAt `gorm:"softDelete:nano"`
}

// Запрос
SELECT * FROM users WHERE deleted_at = 0;

// Удаление
UPDATE users SET deleted_at = /* current unix milli second or nano second */ WHERE ID = 1;
```

#### Использование `1` / `0`, как флагов на удаление

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID    uint
  Name  string
  IsDel soft_delete.DeletedAt `gorm:"softDelete:flag"`
}

// Запрос
SELECT * FROM users WHERE is_del = 0;

// Удаление
UPDATE users SET is_del = 1 WHERE ID = 1;
```

#### Смешанный режим

Смешанный режим может использовать `0`, `1` или секунды unix, чтобы пометить данные как удаленные или нет, и одновременно сохранить время удаления.

```go
type User struct {
  ID        uint
  Name      string
  DeletedAt time.Time
  IsDel     soft_delete.DeletedAt `gorm:"softDelete:flag,DeletedAtField:DeletedAt"` // использовать `1` `0`
  // IsDel     soft_delete.DeletedAt `gorm:"softDelete:,DeletedAtField:DeletedAt"` // использовать `unix second`
  // IsDel     soft_delete.DeletedAt `gorm:"softDelete:nano,DeletedAtField:DeletedAt"` // использовать `unix nano second`
}

// Запрос
SELECT * FROM users WHERE is_del = 0;

// Удаление
UPDATE users SET is_del = 1, deleted_at = /* current unix second */ WHERE ID = 1;
```
