---
title: Delete
layout: page
---

## Delete Record

**Warning** レコードを削除する際、主キーが値を持っているかを確認してください。GORMはレコードを削除する際に主キーを使うので、主キーが空の場合、GORMはそのモデルの全レコードを削除してしまいます。

```go
// 存在するレコードを削除する
db.Delete(&email)
//// DELETE from emails where id=10;

// 削除する際にSQLオプションを追加する
db.Set("gorm:delete_option", "OPTION (OPTIMIZE FOR UNKNOWN)").Delete(&email)
//// DELETE from emails where id=10 OPTION (OPTIMIZE FOR UNKNOWN);
```

## Batch Record

条件に合致するすべてのレコードを削除する

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
//// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
//// DELETE from emails where email LIKE "%jinzhu%";
```

## Soft Delete

モデルに`DeletedAt` フィールドがある場合、自動的にソフトデリート機能が使えるようになります。 このとき`Delete`した場合、レコードはデータベースから物理削除されるのではなく、 `DeletedAt`に現在の時間がセットされます。

```go
db.Delete(&user)
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Batch Delete
db.Where("age = ?", 20).Delete(&User{})
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// ソフトデリートされたレコードはクエリ実行時に無視されます
db.Where("age = 20").Find(&user)
//// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;

// Unscopedを使うことでソフトデリートされたレコードを取得できます。
db.Unscoped().Where("age = 20").Find(&users)
//// SELECT * FROM users WHERE age = 20;
```

## Delete record permanently

    // Delete record permanently with Unscoped
    db.Unscoped().Delete(&order)
    //// DELETE FROM orders WHERE id=10;