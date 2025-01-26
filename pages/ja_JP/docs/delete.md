---
title: レコードの削除
layout: page
---

## レコードを削除

レコードを1件削除する場合は、主キーを指定する必要があります。主キーを指定しない場合、 [一括削除](#batch_delete)が実行されます。例:

```go
// Email の ID は `10`
db.Delete(&email)
// DELETE from emails where id = 10;

// 条件を追加して削除
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

GORMでは `BeforeDelete` と `AfterDelete` のフックが利用できます。これらのメソッドはレコードを削除する際に呼び出されます。詳細については [Hooks](hooks.html) を参照してください。

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
db.Where("email LIKE ?", "%jinzhu%").Delete(&Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(&Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

大量のレコードを効率的に削除するには、プライマリキーのスライスを `Delete` メソッドに渡します。

```go
var users = []User{{ID: 1}, {ID: 2}, {ID: 3}}
db.Delete(&users)
// DELETE FROM users WHERE id IN (1,2,3);

db.Delete(&users, "name LIKE ?", "%jinzhu%")
// DELETE FROM users WHERE name LIKE "%jinzhu%" AND id IN (1,2,3); 
```

### Global Deleteを防ぐ

何も条件を指定せずに一括削除を行った場合、GORMは削除処理を実行せず、`ErrMissingWhereClause`エラーを返します。

条件を指定する、SQLをそのまま実行する、あるいは `AllowGlobalUpdate` モードを有効にする必要があります。例:

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

### 削除されたレコードのデータを返却する

Returningをサポートしているデータベースであれば、削除されたデータを取得することができます。例：

```go
// 全カラムを返す
var users []User
DB.Clauses(clause.Returning{}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING *
// users => []User{{ID: 1, Name: "jinzhu", Role: "admin", Salary: 100}, {ID: 2, Name: "jinzhu.2", Role: "admin", Salary: 1000}}

// 特定のカラムを返す
DB.Clauses(clause.Returning{Columns: []clause.Column{{Name: "name"}, {Name: "salary"}}}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING `name`, `salary`
// users => []User{{ID: 0, Name: "jinzhu", Role: "", Salary: 100}, {ID: 0, Name: "jinzhu.2", Role: "", Salary: 1000}}
```

## 論理削除

(`gorm.Model`にも含まれている) `gorm.DeletedAt` フィールドがモデルに含まれている場合、そのモデルは自動的に論理削除されるようになります。

`Delete` メソッドを実行した際、レコードはデータベースから物理削除されません。代わりに、`DeletedAt` フィールドに現在の時刻が設定され、そのレコードは通常のクエリ系のメソッドでは検索できなくなります。

```go
// user の ID が `111`
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// 一括削除
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// 論理削除されたレコードはクエリの際に無視される
db.Where("age = 20").Find(&user)
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

モデルに `gorm.Model` を含めたくない場合は、以下のようにすることで論理削除機能を有効にできます。

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

`Unscoped`を用いることで、レコードを物理削除できます。

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```

### 削除フラグ

デフォルトでは、`gorm.Model` は `*time.Time` を `DeletedAt` フィールドの値として使用します。 `gorm.io/plugin/soft_delete` を使用することで、他のデータ形式の対応も可能です。

{% note warn %}
**INFO** DeletedAt フィールドに一意の複合インデックスを作成するには、`gorm.io/plugin/soft_delete` プラグインのヘルパーによるUNIX秒/フラグといった、ほかのデータ形式を使用しなければなりません。

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string                `gorm:"uniqueIndex:udx_name"`
  DeletedAt soft_delete.DeletedAt `gorm:"uniqueIndex:udx_name"`
}
```
{% endnote %}

#### UNIX秒

UNIX秒を削除フラグとして使用

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

ミリ秒 `milli` またはナノ秒 `nano` を値として指定することもできます。例:

```go
type User struct {
  ID    uint
  Name  string
  DeletedAt soft_delete.DeletedAt `gorm:"softDelete:milli"`
  // DeletedAt soft_delete.DeletedAt `gorm:"softDelete:nano"`
}

// Query
SELECT * FROM users WHERE deleted_at = 0;

// Delete
UPDATE users SET deleted_at = /* current unix milli second or nano second */ WHERE ID = 1;
```

#### `1` / `0` を削除フラグとして使用

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

#### 混在モード

混在モードではデータが削除されているか否かを `0` と `1`、またはUNIX秒でマークし、同時に削除日時を保存することができます。

```go
type User struct {
  ID        uint
  Name      string
  DeletedAt time.Time
  IsDel     soft_delete.DeletedAt `gorm:"softDelete:flag,DeletedAtField:DeletedAt"` // use `1` `0`
  // IsDel     soft_delete.DeletedAt `gorm:"softDelete:,DeletedAtField:DeletedAt"` // use `unix second`
  // IsDel     soft_delete.DeletedAt `gorm:"softDelete:nano,DeletedAtField:DeletedAt"` // use `unix nano second`
}

// Query
SELECT * FROM users WHERE is_del = 0;

// Delete
UPDATE users SET is_del = 1, deleted_at = /* current unix second */ WHERE ID = 1;
```
