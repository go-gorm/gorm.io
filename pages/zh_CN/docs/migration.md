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

  // Views
  CreateView(name string, option ViewOption) error
  DropView(name string) error

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

// 添加 name 字段
db.Migrator().AddColumn(&User{}, "Name")
// 删除 name 字段
db.Migrator().DropColumn(&User{}, "Name")
// 修改 name 字段
db.Migrator().AlterColumn(&User{}, "Name")
// 检查 name 字段是否存在
db.Migrator().HasColumn(&User{}, "Name")

type User struct {
  Name    string
  NewName string
}

// 字段重命名
db.Migrator().RenameColumn(&User{}, "Name", "NewName")
db.Migrator().RenameColumn(&User{}, "name", "new_name")

// 字段类型
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

### Views

Create views by `ViewOption`. About `ViewOption`:

- `Query` is a [subquery](https://gorm.io/docs/advanced_query.html#SubQuery), which is required.
- If `Replace` is true, exec `CREATE OR REPLACE` otherwise exec `CREATE`.
- If `CheckOption` is not empty, append to sql, e.g. `WITH LOCAL CHECK OPTION`.

{% note warn %}
**NOTE** SQLite currently does not support `Replace` in `ViewOption`
{% endnote %}

```go
qyery := db.Model(&User{}).Where("age > ?", 20)

// Create View
db.Migrator().CreateView("users_pets", gorm.ViewOption{Query: query})
// CREATE VIEW `users_view` AS SELECT * FROM `users` WHERE age > 20

// Create or Replace View
db.Migrator().CreateView("users_pets", gorm.ViewOption{Query: query, Replace: true})
// CREATE OR REPLACE VIEW `users_pets` AS SELECT * FROM `users` WHERE age > 20

// Create View With Check Option
db.Migrator().CreateView("users_pets", gorm.ViewOption{Query: query, CheckOption: "WITH CHECK OPTION"})
// CREATE VIEW `users_pets` AS SELECT * FROM `users` WHERE age > 20 WITH CHECK OPTION

// Drop View
db.Migrator().DropView("users_pets")
// DROP VIEW IF EXISTS "users_pets"
```

### Constraints

```go
type UserIndex struct {
  Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
}

// Create constraint
db.Migrator().CreateConstraint(&User{}, "name_checker")

// Drop constraint
db.Migrator().DropConstraint(&User{}, "name_checker")

// Check constraint exists
db.Migrator().HasConstraint(&User{}, "name_checker")
```

Create foreign keys for relations

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

// create database foreign key for user & credit_cards
db.Migrator().CreateConstraint(&User{}, "CreditCards")
db.Migrator().CreateConstraint(&User{}, "fk_users_credit_cards")
// ALTER TABLE `credit_cards` ADD CONSTRAINT `fk_users_credit_cards` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)

// check database foreign key for user & credit_cards exists or not
db.Migrator().HasConstraint(&User{}, "CreditCards")
db.Migrator().HasConstraint(&User{}, "fk_users_credit_cards")

// drop database foreign key for user & credit_cards
db.Migrator().DropConstraint(&User{}, "CreditCards")
db.Migrator().DropConstraint(&User{}, "fk_users_credit_cards")
```

### Indexes

```go
type User struct {
  gorm.Model
  Name string `gorm:"size:255;index:idx_name,unique"`
}

// Create index for Name field
db.Migrator().CreateIndex(&User{}, "Name")
db.Migrator().CreateIndex(&User{}, "idx_name")

// Drop index for Name field
db.Migrator().DropIndex(&User{}, "Name")
db.Migrator().DropIndex(&User{}, "idx_name")

// Check Index exists
db.Migrator().HasIndex(&User{}, "Name")
db.Migrator().HasIndex(&User{}, "idx_name")

type User struct {
  gorm.Model
  Name  string `gorm:"size:255;index:idx_name,unique"`
  Name2 string `gorm:"size:255;index:idx_name_2,unique"`
}
// Rename index name
db.Migrator().RenameIndex(&User{}, "Name", "Name2")
db.Migrator().RenameIndex(&User{}, "idx_name", "idx_name_2")
```

## 约束

GORM creates constraints when auto migrating or creating table, see [Constraints](constraints.html) or [Database Indexes](indexes.html) for details

## 其他迁移工具

GORM's AutoMigrate works well for most cases, but if you are looking for more serious migration tools, GORM provides a generic DB interface that might be helpful for you.

```go
// returns `*sql.DB`
db.DB()
```

Refer to [Generic Interface](generic_interface.html) for more details.
