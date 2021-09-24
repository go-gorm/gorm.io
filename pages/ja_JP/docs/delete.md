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

## 論理削除

モデルに `gorm.DeletedAt` フィールド ( `gorm.Model`に含まれている) が存在している場合、削除時は自動的にSoft Deleteが実行されるようになります!

`Delete`メソッドを呼び出しても、 レコードはデータベースから削除されません。代わりに、GORMは`DeletedAt`フィールドの値に現在の時刻を設定し、そのレコードは通常のクエリメソッドでは検索できなくなります。

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

モデルに`gorm.Model`を含めたくない場合、以下のようにして論理削除機能を有効にできます。

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### 論理削除されたレコードを取得する

`Unscoped`を用いることで、論理削除されたレコードを取得することができます。

```go
db.Unscoped().Where("age = 20").Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### 完全な削除（物理削除）

`Unscoped`を用いることで、条件に一致したレコードを物理削除できます。

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```

### 削除フラグ

UNIXタイムスタンプを削除フラグとして使用する

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
**INFO** ユニークなフィールドがあるテーブルで論理削除を使用する場合、UNIXタイムを利用した `DeletedAt` フィールドとの複合インデックスを作成するとよいでしょう。例:

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string                `gorm:"uniqueIndex:udx_name"`
  DeletedAt soft_delete.DeletedAt `gorm:"uniqueIndex:udx_name"`
}
```
{% endnote %}

`1` / `0` を削除フラグとして使用する

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
