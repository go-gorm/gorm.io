---
title: マイグレーション
layout: page
---

## 自動マイグレーション

スキーマを最新に保つため、自動的に移行します。

**警告:**自動マイグレーションはテーブルや不足しているカラムとインデックス**のみ**生成します。データ保護のため、既存のカラム型の変更や未使用のカラムの削除は**しません**。

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// テーブル作成時にテーブルのサフィックスを追加します
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## その他マイグレーションツール

GORMの自動マイグレーションはほとんどの場合で、うまく機能します。しかし、よりしっかりしたマイグレーションツールを求める方のために、GORMは一般的なDBインターフェースも提供します。

```go
// `*sql.DB`を返します
db.DB()
```

詳しくは[一般的なインタフェース](/docs/generic_interface.html)を参照してください。

## スキーマメソッド

### HasTable

```go
// `User`モデルのテーブルが存在するかどうか確認します
db.HasTable(&User{})

// `usersテーブルが存在するかどうか確認します
db.HasTable("users")
```

### CreateTable

```go
// `User`モデルのテーブルを作成します
db.CreateTable(&User{})

// `users`テーブル作成時に、SQL文に`ENGINE=InnoDB`を付与します
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})
```

### DropTable

```go
// `User`モデルのテーブルを削除します
db.DropTable(&User{})

// `users`テーブルを削除します
db.DropTable("users")

// `User`モデルのテーブルと`products`テーブルを削除します
db.DropTableIfExists(&User{}, "products")
```

### ModifyColumn

カラムの型を指定した値に変更します

```go
// `User`モデルのdescriptionカラムのデータ型を`text`に変更します
db.Model(&User{}).ModifyColumn("description", "text")
```

### DropColumn

```go
// `User`モデルのdescriptionカラムを削除します
db.Model(&User{}).DropColumn("description")
```

### AddIndexes

```go
// `name`カラムのインデックスを`idx_user_name`という名前で追加します
db.Model(&User{}).AddIndex("idx_user_name", "name")

// `name`,`age`のインデックスを`idx_user_name_age`という名前で追加します
db.Model(&User{}).AddIndex("idx_user_name_age", "name", "age")

// ユニークインデックスを追加します
db.Model(&User{}).AddUniqueIndex("idx_user_name", "name")

// 複数カラムのユニークインデックスを追加します
db.Model(&User{}).AddUniqueIndex("idx_user_name_age", "name", "age")
```

### RemoveIndex

```go
// インデックスを削除します
db.Model(&User{}).RemoveIndex("idx_user_name")
```

### AddForeignKey

```go
// 外部キーを追加します
// パラメータ1 : 外部キー
// パラメータ2 : 対象のテーブル(id)
// パラメータ3 : ONDELETE
// パラメータ4 : ONUPDATE
db.Model(&User{}).AddForeignKey("city_id", "cities(id)", "RESTRICT", "RESTRICT")
```

### RemoveForeignKey

```go
db.Model(&User{}).RemoveForeignKey("city_id", "cities(id)")
```