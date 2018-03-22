---
title: Migration
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

GORMの自動マイグレーションはたいていうまく機能しますが、よりしっかりしたマイグレーションツールを求めるのであれば、GORMはあなたに役立つであろう一般的なDBインタフェースを提供します。

```go
// `*sql.DB`を返します
db.DB()
```

詳しくは[一般的なインタフェース](/docs/generic_interface.html)を参照してください。

## スキーマメソッド

### Has Table

```go
// `User`モデルのテーブルが存在するかどうか確認します
db.HasTable(&User{})

// `usersテーブルが存在するかどうか確認します
db.HasTable("users")
```

### Create Table

```go
// `User`モデルのテーブルを作成します
db.CreateTable(&User{})

// `users`テーブル作成時に、SQL文に`ENGINE=InnoDB`を付与します
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})
```

### Drop table

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

### Add Indexes

```go
// Add index for columns `name` with given name `idx_user_name`
db.Model(&User{}).AddIndex("idx_user_name", "name")

// Add index for columns `name`, `age` with given name `idx_user_name_age`
db.Model(&User{}).AddIndex("idx_user_name_age", "name", "age")

// Add unique index
db.Model(&User{}).AddUniqueIndex("idx_user_name", "name")

// Add unique index for multiple columns
db.Model(&User{}).AddUniqueIndex("idx_user_name_age", "name", "age")
```

### Remove Index

```go
// Remove index
db.Model(&User{}).RemoveIndex("idx_user_name")
```

### Add Foreign Key

```go
// Add foreign key
// 1st param : foreignkey field
// 2nd param : destination table(id)
// 3rd param : ONDELETE
// 4th param : ONUPDATE
db.Model(&User{}).AddForeignKey("city_id", "cities(id)", "RESTRICT", "RESTRICT")
```

### Remove ForeignKey

```go
db.Model(&User{}).RemoveForeignKey("city_id", "cities(id)")
```