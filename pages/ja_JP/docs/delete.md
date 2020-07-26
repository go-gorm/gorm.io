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

もし、レコードが持つ主キーの値を指定しなかった場合、GORMはバッチ削除を実行し、指定した条件に一致したすべてのレコードを削除します。

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### Block Global Delete

何も条件を付けずにバッチ削除を行った場合、GORMは実行せず、`ErrMissingWhereClause`エラーを返します。

`1 = 1` のような条件を使用して、全削除を強制できます。

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE `users` WHERE 1=1
```

## Soft Delete

モデルに`gorm.DeletedAt`フィールド (`gorm.Model`にも含まれています。) が含まれている場合、そのモデルは自動的に論理削除機能を取得します!

`Delete`メソッドを呼び出しても、 レコードはデータベースから削除されません。代わりに、GORMは`DeletedAt`フィールドの値に現在の時刻を設定し、そのレコードは通常のクエリメソッドでは検索できなくなります。

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

モデルに`gorm.Model`を含めたくない場合、以下のようにして論理削除機能を有効にできます。

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### Find soft deleted records

`Unscoped`を用いることで、論理削除したレコードを見つけることができます。

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
