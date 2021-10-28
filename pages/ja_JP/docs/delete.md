---
title: レコードの削除
layout: page
---

## レコードを削除

レコードを1件削除する場合は、主キーを指定する必要があります。主キーを指定しない場合、 [一括削除](#batch_delete)が実行されます。例:

```go
// Email's ID is `10`
db.Delete(&email)
// DELETE from emails where id = 10;

// Delete with additional conditions
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE from emails where id = 10 AND name = "jinzhu";
```

## 主キーを使用した削除

GORMでは主キーが数値の場合、インライン条件で主キーを指定してオブジェクトを削除することができます。詳細は [Query Inline Conditions](query.html#inline_conditions) をチェックしてください。

```go
db.Delete(&User{}, 10)
// DELETE FROM users WHERE id = 10;

db.Delete(&User{}, "10")
// DELETE FROM users WHERE id = 10;

db.Delete(&users, []int{1,2,3})
// DELETE FROM users WHERE id IN (1,2,3);
```

## 削除のフック処理

GORMでは削除時のフック処理に `BeforeDelete`, `AfterDelete`を利用することができます。これらのメソッドはレコードを削除する際に呼び出されます。 [Hooks](hooks.html)を参照してください。

```go
func (u *User) BeforeDelete(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to delete")
    }
    return
}
```

## <span id="batch_delete">一括削除</span>

主キーが指定されていない場合、GORMは指定された条件にマッチしたレコードの一括削除を実行します。

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### Global Deleteを防ぐ

何も条件を指定せずに一括削除を行った場合、GORMは削除処理を実行せず、`ErrMissingWhereClause`エラーを返します。

条件を指定する、SQLをそのまま実行する、あるいは `AllowGlobalUpdate` モードを有効にする必要があります。例:

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE FROM `users` WHERE 1=1

db.Exec("DELETE FROM users")
// DELETE FROM users

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// DELETE FROM users
```

### Returning Data From Deleted Rows

Return deleted data, only works for database support Returning, for example:

```go
// return all columns
var users = []User
DB.Clauses(clause.Returning{}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING *
// users => []User{{ID: 1, Name: "jinzhu", Role: "admin", Salary: 100}, {ID: 2, Name: "jinzhu.2", Role: "admin", Salary: 1000}}

// return specified columns
DB.Clauses(clause.Returning{Columns: []clause.Column{{Name: "name"}, {Name: "salary"}}}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING `name`, `salary`
// users => []User{{ID: 0, Name: "jinzhu", Role: "", Salary: 100}, {ID: 0, Name: "jinzhu.2", Role: "", Salary: 1000}}
```

## 論理削除

If your model includes a `gorm.DeletedAt` field (which is included in `gorm.Model`), it will get soft delete ability automatically!

When calling `Delete`, the record WON'T be removed from the database, but GORM will set the `DeletedAt`'s value to the current time, and the data is not findable with normal Query methods anymore.

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

If you don't want to include `gorm.Model`, you can enable the soft delete feature like:

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### Find soft deleted records

You can find soft deleted records with `Unscoped`

```go
db.Unscoped().Where("age = 20").Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### Delete permanently

You can delete matched records permanently with `Unscoped`

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```

### Delete Flag

Use unix second as delete flag

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string
  DeletedAt soft_delete.DeletedAt
}

// Query
SELECT * FROM users WHERE deleted_at = 0;

// Delete
UPDATE users SET deleted_at = /* current unix second */ WHERE ID = 1;
```

{% note warn %}
**INFO** when using unique field with soft delete, you should create a composite index with the unix second based `DeletedAt` field, e.g:

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string                `gorm:"uniqueIndex:udx_name"`
  DeletedAt soft_delete.DeletedAt `gorm:"uniqueIndex:udx_name"`
}
```
{% endnote %}

Use `1` / `0` as delete flag

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID    uint
  Name  string
  IsDel soft_delete.DeletedAt `gorm:"softDelete:flag"`
}

// Query
SELECT * FROM users WHERE is_del = 0;

// Delete
UPDATE users SET is_del = 1 WHERE ID = 1;
```
