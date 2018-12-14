---
title: Delete
layout: page
---
## Delete Record

**WARNING** When deleting a record, you need to ensure its primary field has value, and GORM will use the primary key to delete the record, if the primary key field is blank, GORM will delete all records for the model

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

モデルが`DeletedAt` フィールドを持っている場合、自動的にソフトデリートの機能を有することになります。 その場合、`Delete`を実行したとしてもデータベースから消えることはありません。`DeletedAt`フィールドに現在時刻がセットされるだけです。

```go
db.Delete(&user)
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// バッチデリート
db.Where("age = ?", 20).Delete(&User{})
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// ソフトデリートされたレコードはクエリ実行時に無視されます
db.Where("age = 20").Find(&user)
//// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;

// Unscopedを使うことでソフトデリートされたレコードを取得できます。
db.Unscoped().Where("age = 20").Find(&users)
//// SELECT * FROM users WHERE age = 20;

// Unscopedを使うことでソフトデリートされたレコードを完全に削除できます。
db.Unscoped().Delete(&order)
//// DELETE FROM orders WHERE id=10;
```