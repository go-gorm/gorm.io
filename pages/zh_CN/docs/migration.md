---
title: 迁移
layout: page
---

## AutoMigrate

AutoMigrate 用于自动迁移您的 schema，保持您的 schema 是最新的。

{% note warn %}
**NOTE:** AutoMigrate will create tables, missing foreign keys, constraints, columns and indexes, and will change existing column's type if it's size, precision, nullable changed, it **WON'T** delete unused columns to protect your data.
{% endnote %}

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// 创建表时添加后缀
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

{% note warn %}
**NOTE** AutoMigrate creates database foreign key constraints automatically, you can disable this feature during initialization, for example:
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

## Migrator 接口

GORM provides migrator interface, which contains unified API interfaces for each database that could be used to build your database-independent migrations, for example:

SQLite doesn't support `ALTER COLUMN`, `DROP COLUMN`, GORM will create a new table as the one you are trying to change, copy all data, drop the old table, rename the new table

MySQL doesn't support rename column, index for some versions, GORM will perform different SQL based on the MySQL version you are using

```go
type Migrator interface {
  // AutoMigrate
  AutoMigrate(dst ...interface{}) error

  // Database
  CurrentDatabase() string
  FullDataTypeOf(*schema.Field) clause.Expr

  // Tables
  CreateTable(dst ...interface{}) error
  DropTable(dst ...interface{}) error
  HasTable(dst interface{}) bool
  RenameTable(oldName, newName interface{}) error

  // Columns
  AddColumn(dst interface{}, field string) error
  DropColumn(dst interface{}, field string) error
  AlterColumn(dst interface{}, field string) error
  HasColumn(dst interface{}, field string) bool
  RenameColumn(dst interface{}, oldName, field string) error
  MigrateColumn(dst interface{}, field *schema.Field, columnType *sql.ColumnType) error
  ColumnTypes(dst interface{}) ([]*sql.ColumnType, error)

  // Constraints
  CreateConstraint(dst interface{}, name string) error
  DropConstraint(dst interface{}, name string) error
  HasConstraint(dst interface{}, name string) bool

  // Indexes
  CreateIndex(dst interface{}, name string) error
  DropIndex(dst interface{}, name string) error
  HasIndex(dst interface{}, name string) bool
  RenameIndex(dst interface{}, oldName, newName string) error
}
```

### 当前数据库

Returns current using database name

```go
db.Migrator().CurrentDatabase()
```

### 表

```go
// 为 `User` 创建表
db.Migrator().CreateTable(&User{})

// 将 "ENGINE=InnoDB" 添加到创建 `User` 的 SQL 里去
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})

// 检查 `User` 对应的表是否存在
db.Migrator().HasTable(&User{})
db.Migrator().HasTable("users")

// 如果存在表则删除（删除时会忽略、删除外键约束)
db.Migrator().DropTable(&User{})
db.Migrator().DropTable("users")

// 重命名表
db.Migrator().RenameTable(&User{}, &UserInfo{})
db.Migrator().RenameTable("users", "user_infos")
```

### 列

```go
type User struct {
  Name string
}

// 添加 name 字段
db.Migrator().AddColumn(&User{}, "Name")
// 删除 name 字段
db.Migrator().DropColumn(&User{}, "Name")
// 修改 name 字段
db.Migrator().AlterColumn(&User{}, "Name")
// 检查字段是否存在
db.Migrator().HasColumn(&User{}, "Name")

type User struct {
  Name    string
  NewName string
}

// 重命名字段
db.Migrator().RenameColumn(&User{}, "Name", "NewName")
db.Migrator().RenameColumn(&User{}, "name", "new_name")

// 获取字段类型
db.Migrator().ColumnTypes(&User{}) ([]*sql.ColumnType, error)
```

### 约束

```go
type UserIndex struct {
  Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
}

// 创建约束
db.Migrator().CreateConstraint(&User{}, "name_checker")

// 删除约束
db.Migrator().DropConstraint(&User{}, "name_checker")

// 检查约束是否存在
db.Migrator().HasConstraint(&User{}, "name_checker")
```

### 索引

```go
type User struct {
  gorm.Model
  Name string `gorm:"size:255;index:idx_name,unique"`
}

// 为 Name 字段创建索引
db.Migrator().CreateIndex(&User{}, "Name")
db.Migrator().CreateIndex(&User{}, "idx_name")

// 为 Name 字段删除索引
db.Migrator().DropIndex(&User{}, "Name")
db.Migrator().DropIndex(&User{}, "idx_name")

// 检查索引是否存在
db.Migrator().HasIndex(&User{}, "Name")
db.Migrator().HasIndex(&User{}, "idx_name")

type User struct {
  gorm.Model
  Name  string `gorm:"size:255;index:idx_name,unique"`
  Name2 string `gorm:"size:255;index:idx_name_2,unique"`
}
// 修改索引名
db.Migrator().RenameIndex(&User{}, "Name", "Name2")
db.Migrator().RenameIndex(&User{}, "idx_name", "idx_name_2")
```

## 约束

GORM creates constraints when auto migrating or creating table, checkout [Constraints](constraints.html) or [Database Indexes](indexes.html) for details

## 其他迁移工具

GORM's AutoMigrate works well for most cases, but if you are looking for more serious migration tools, GORM provides a generic DB interface that might be helpful for you.

```go
// returns `*sql.DB`
db.DB()
```

Refer [Generic Interface](generic_interface.html) for more details.
