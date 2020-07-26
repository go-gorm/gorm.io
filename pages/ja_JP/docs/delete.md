---
title: Delete
layout: page
---

## Delete Record

レコードを削除する

```go
// Delete an existing record, email's primary key value is 10
db.Delete(&email)
// DELETE from emails where id=10;

// DELETE with inline condition
db.Delete(&Email{}, 20)
// DELETE from emails where id=20;

// DELETE with additional conditions
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE FROM emails WHERE id=10 AND name = 'jinzhu'
```

## Delete Hooks

GORMは `BeforeDelete`, `AfterDelete`をフックします。これらのメソッドはレコードを削除する際に呼び出されます。 [Hooks](hooks.html)を参照してください。

```go
func (u *User) BeforeDelete(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to delete")
    }
    return
}
```

## Batch Delete

If we havn't specify a record having priamry key value, GORM will perform a batch delete all matched records

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### Block Global Delete

何も条件を付けずにバッチ削除を行った場合、GORMは実行せず、`ErrMissingWhereClause`エラーを返します。

`1 = 1` のような条件を使用して、グローバルデリートを強制できます。

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE `users` WHERE 1=1
```

## Soft Delete

モデルに`gorm.DeletedAt`フィールド (`gorm.Model`にも含まれています。) が含まれている場合、そのモデルは自動的に論理削除機能を取得します!

When calling `Delete`, the record WON'T be removed from the database, but GORM will set the `DeletedAt`'s value to the current time, and the data is not findable with normal Query methods anymore.

```go
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

`Unscoped`で一致したレコードを永久に削除できます。

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```
