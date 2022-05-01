---
title: 迁移
layout: page
---

## AutoMigrate

AutoMigrate 用于自动迁移您的 schema，保持您的 schema 是最新的。

{% note warn %}
**注意：** AutoMigrate 会创建表、缺失的外键、约束、列和索引。 如果大小、精度、是否为空可以更改，则 AutoMigrate 会改变列的类型。 出于保护您数据的目的，它 **不会** 删除未使用的列
{% endnote %}

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// 创建表时添加后缀
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

{% note warn %}
**注意** AutoMigrate 会自动创建数据库外键约束，您可以在初始化时禁用此功能，例如：
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

## Migrator 接口

GORM 提供了 Migrator 接口，该接口为每个数据库提供了统一的 API 接口，可用来为您的数据库构建独立迁移，例如：

SQLite 不支持 `ALTER COLUMN`、`DROP COLUMN`，当你试图修改表结构，GORM 将创建一个新表、复制所有数据、删除旧表、重命名新表。

一些版本的 MySQL 不支持 rename 列，索引。GORM 将基于您使用 MySQL 的版本执行不同 SQL

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
  GetTables() (tableList []string, err error)

  // Columns
  AddColumn(dst interface{}, field string) error
  DropColumn(dst interface{}, field string) error
  AlterColumn(dst interface{}, field string) error
  MigrateColumn(dst interface{}, field *schema.Field, columnType ColumnType) error
  HasColumn(dst interface{}, field string) bool
  RenameColumn(dst interface{}, oldName, field string) error
  ColumnTypes(dst interface{}) ([]ColumnType, error)

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

返回当前使用的数据库名

```go
db.Migrator().CurrentDatabase()
```

### 表

```go
// 为 `User` 创建表
db.Migrator().CreateTable(&User{})

// 将 "ENGINE=InnoDB" 添加到创建 `User` 的 SQL 里去
db.Set("gorm:table_options", "ENGINE=InnoDB").Migrator().CreateTable(&User{})

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

// Add name field
db.Migrator().AddColumn(&User{}, "Name")
// Drop name field
db.Migrator().DropColumn(&User{}, "Name")
// Alter name field
db.Migrator().AlterColumn(&User{}, "Name")
// Check column exists
db.Migrator().HasColumn(&User{}, "Name")

type User struct {
  Name    string
  NewName string
}

// Rename column to new name
db.Migrator().RenameColumn(&User{}, "Name", "NewName")
db.Migrator().RenameColumn(&User{}, "name", "new_name")

// ColumnTypes
db.Migrator().ColumnTypes(&User{}) ([]gorm.ColumnType, error)

type ColumnType interface {
    Name() string
    DatabaseTypeName() string                 // varchar
    ColumnType() (columnType string, ok bool) // varchar(64)
    PrimaryKey() (isPrimaryKey bool, ok bool)
    AutoIncrement() (isAutoIncrement bool, ok bool)
    Length() (length int64, ok bool)
    DecimalSize() (precision int64, scale int64, ok bool)
    Nullable() (nullable bool, ok bool)
    Unique() (unique bool, ok bool)
    ScanType() reflect.Type
    Comment() (value string, ok bool)
    DefaultValue() (value string, ok bool)
}
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

为 relation 创建外键

```go
type User struct {
  gorm.Model
  CreditCards []CreditCard
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}

// 为 user & credit_cards 创建 db 外键
db.Migrator().CreateConstraint(&User{}, "CreditCards")
db.Migrator().CreateConstraint(&User{}, "fk_users_credit_cards")
// ALTER TABLE `credit_cards` ADD CONSTRAINT `fk_users_credit_cards` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)

// 检查 user & credit_cards 的外键是否存在
db.Migrator().HasConstraint(&User{}, "CreditCards")
db.Migrator().HasConstraint(&User{}, "fk_users_credit_cards")

// 删除 user & credit_cards 的 db 外键
db.Migrator().DropConstraint(&User{}, "CreditCards")
db.Migrator().DropConstraint(&User{}, "fk_users_credit_cards")
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

GORM 会在自动迁移或建表时创建约束，请参阅 [约束](constraints.html) 或 [数据库索引](indexes.html) 以了解详情

## 其他迁移工具

GORM 的 AutoMigrate 适用于大多数的迁移，如果您需要更加个性化的迁移工具 ，GORM 提供的一个通用数据库接口可能对您有帮助。

```go
// returns `*sql.DB`
db.DB()
```

查看 [通用接口](generic_interface.html) 获取更多详情。
