---
title: 迁移
layout: page
---

## 自动迁移

自动迁移你的模型，使之保持最新状态。

**警告：** 自动迁移 **只会** 创建表、缺失的列、缺失的索引， **不会** 更改现有列的类型或删除未使用的列，以此来保护您的数据。

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// 创建表时添加表后缀
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## 其它迁移工具

GORM 的自动迁移在大多数情况下都会正常工作，但如果你在需求更严格的迁移工具， GORM 提供了通用 DB interface ，这可能对你有帮助。

```go
// 返回 `*sql.DB`
db.DB()
```

参考 [通用 Interface](/docs/generic_interface.html) 获取详情。

## 模型方法

### Has Table

```go
// 检查模型 User 的表是否存在
db.HasTable(&User{})

// 检查表 users 是否存在
db.HasTable("users")
```

### Create Table

```go
// 为模型 `User` 创建表
db.CreateTable(&User{})

// 创建表时会追加 “ENGINE=InnoDB” 到 SQL 语句中。
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})
```

### Drop table

```go
// 删除模型 `User` 的表
db.DropTable(&User{})

// 删除表 `users`
db.DropTable("users")

// 删除模型 `User` 的表和表 `products`
db.DropTableIfExists(&User{}, "products")
```

### ModifyColumn

修改列类型为给定的值

```go
// 修改模型 `User` 的 description 列的类型为 `text` 
db.Model(&User{}).ModifyColumn("description", "text")
```

### DropColumn

```go
// 删除模型 `User` 的 description 列
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