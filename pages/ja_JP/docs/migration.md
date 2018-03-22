---
title: Migration
layout: page
---
## 自動マイグレーション

スキーマを最新に保つため、自動的に移行します。

**警告:**自動マイグレーションはテーブルや不足しているカラムとインデックス**のみ**生成します。データ保護のため、既存のカラム型を変更したり未使用のカラムを削除**しません**。

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// テーブル作成時にテーブルのサフィックスを追加します
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## その他マイグレーションツール

GORM's AutoMigrate works well for mostly cases, but if you are looking more seriously migration tools, GORM provides genric DB interface which might be helpful for you.

```go
// returns `*sql.DB`
db.DB()
```

Refer [Generic Interface](/docs/generic_interface.html) for more details.

## Schema Methods

### Has Table

```go
// Check model `User`'s table exists or not
db.HasTable(&User{})

// Check table `users` exists or not
db.HasTable("users")
```

### Create Table

```go
// Create table for model `User`
db.CreateTable(&User{})

// will append "ENGINE=InnoDB" to the SQL statement when creating table `users`
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})
```

### Drop table

```go
// Drop model `User`'s table
db.DropTable(&User{})

// Drop table `users`
db.DropTable("users")

// Drop model's `User`'s table and table `products`
db.DropTableIfExists(&User{}, "products")
```

### ModifyColumn

Modify column's type to given value

```go
// change column description's data type to `text` for model `User`
db.Model(&User{}).ModifyColumn("description", "text")
```

### DropColumn

```go
// Drop column description from model `User`
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