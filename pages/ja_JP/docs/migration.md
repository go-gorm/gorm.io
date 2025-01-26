---
title: Migration
layout: page
---

## Auto Migration

スキーマ定義のマイグレーションを自動で行い、スキーマを最新の状態に保ちます。

{% note warn %}
**注意:** AutoMigrate はテーブル、外部キー、制約、カラム、インデックスを作成します。 カラムのサイズまたは精度が変更されていた場合、および非 null 型からnull 許容型に変更されていた場合、既存のカラムの型が変更されます。 しかし、データを守るために、使われなくなったカラムの削除は**実行されません**。
{% endnote %}

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// Add table suffix when creating tables
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

{% note warn %}
**注意** AutoMigrate はデータベースの外部キー制約を自動的に作成します。初期化時にこの機能を無効にすることができます。例：
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

## Migrator Interface

GORMは、データベースに依存しないスキーママイグレーションを構築するために使用できる、各データベースのための統一されたAPIインタフェースを含むmigratorインタフェースを提供します。例：

SQLiteは`ALTER COLUMN`, `DROP COLUMN`をサポートしていませんが、GORMは変更しようとしているテーブルを新しいテーブルとして作成し、すべてのデータをコピーし、古いテーブルを削除し、新しいテーブルの名前を変更します。

MySQLは、いくつかのバージョンではカラム名変更、インデックス変更をサポートしていませんが、GORMは使用しているMySQLのバージョンに応じて異なるSQLを実行します。

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

### CurrentDatabase

使用中のデータベース名を取得できます

```go
db.Migrator().CurrentDatabase()
```

### Tables

```go
// `User` テーブルを作成する
db.Migrator().CreateTable(&User{})

// `User` テーブル作成時のSQLに "ENGINE=InnoDB" を追加する
db.Set("gorm:table_options", "ENGINE=InnoDB").Migrator().CreateTable(&User{})

// `User` テーブルが存在するかどうかをチェックする
db.Migrator().HasTable(&User{})
db.Migrator().HasTable("users")

// テーブルが存在する場合はDropする（外部キー制約は無視するか削除する）
db.Migrator().DropTable(&User{})
db.Migrator().DropTable("users")

// テーブル名を新しいものに変更する
db.Migrator().RenameTable(&User{}, &UserInfo{})
db.Migrator().RenameTable("users", "user_infos")
```

### Columns

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

### Views

Create views by `ViewOption`. About `ViewOption`:

- `Query` is a [subquery](https://gorm.io/docs/advanced_query.html#SubQuery), which is required.
- If `Replace` is true, exec `CREATE OR REPLACE` otherwise exec `CREATE`.
- If `CheckOption` is not empty, append to sql, e.g. `WITH LOCAL CHECK OPTION`.

{% note warn %}
**NOTE** SQLite currently does not support `Replace` in `ViewOption`
{% endnote %}

```go
query := db.Model(&User{}).Where("age > ?", 20)

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

## 制約

GORM creates constraints when auto migrating or creating table, see [Constraints](constraints.html) or [Database Indexes](indexes.html) for details

## Atlas Integration

[Atlas](https://atlasgo.io) is an open-source database migration tool that has an official integration with GORM.

While GORM's `AutoMigrate` feature works in most cases, at some point you may need to switch to a [versioned migrations](https://atlasgo.io/concepts/declarative-vs-versioned#versioned-migrations) strategy.

Once this happens, the responsibility for planning migration scripts and making sure they are in line with what GORM expects at runtime is moved to developers.

Atlas can automatically plan database schema migrations for developers using the official [GORM Provider](https://github.com/ariga/atlas-provider-gorm).  After configuring the provider you can automatically plan migrations by running:
```bash
atlas migrate diff --env gorm
```

To learn how to use Atlas with GORM, check out the [official documentation](https://atlasgo.io/guides/orms/gorm).



## Other Migration Tools

To use GORM with other Go-based migration tools, GORM provides a generic DB interface that might be helpful for you.

```go
// returns `*sql.DB`
db.DB()
```

Refer to [Generic Interface](generic_interface.html) for more details.
