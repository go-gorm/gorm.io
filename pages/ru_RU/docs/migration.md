---
title: Миграция
layout: страница
---

## Авто миграция

Автоматически переносит вашу схему, чтобы поддерживать обновление вашей схемы.

{% note warn %}
**NOTE:** AutoMigrate will create tables, missing foreign keys, constraints, columns and indexes, and will change existing column's type if it's size, precision, nullable changed, it **WON'T** delete unused columns to protect your data.
{% endnote %}

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// Добавляет суффикс таблицы при создании таблицы
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

## Интерфейс Мигратора

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

### CurrentDatabase

Returns current using database name

```go
db.Migrator().CurrentDatabase()
```

### Таблицы

```go
// Создать таблицу для `User`
db.Migrator().CreateTable(&User{})

// Добавить "ENGINE=InnoDB" в создание таблицы SQL для `User`
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})

// Проверить существует ли таблица для `User` или нет
db.Migrator().HasTable(&User{})
db.Migrator().HasTable("users")

// Drop таблицу если существует (будет игнорировать или удалять внешние ключи при drop)
db.Migrator().DropTable(&User{})
db.Migrator().DropTable("users")

// Переименовать таблицу
db.Migrator().RenameTable(&User{}, &UserInfo{})
db.Migrator().RenameTable("users", "user_infos")
```

### Столбцы

```go
type User struct {
  Name string
}

// Добавить новый столбец
db.Migrator().AddColumn(&User{}, "Name")
// Drop столбца
db.Migrator().DropColumn(&User{}, "Name")
// Alter столбца Name
db.Migrator().AlterColumn(&User{}, "Name")
// Проверка на существование столбца
db.Migrator().HasColumn(&User{}, "Name")

type User struct {
  Name    string
  NewName string
}

// Переименование столбца
db.Migrator().RenameColumn(&User{}, "Name", "NewName")
db.Migrator().RenameColumn(&User{}, "name", "new_name")

// Тип столбца ColumnTypes
db.Migrator().ColumnTypes(&User{}) ([]*sql.ColumnType, error)
```

### Ограничения

```go
type UserIndex struct {
  Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
}

// Добавить ограничения
db.Migrator().CreateConstraint(&User{}, "name_checker")

// Удалить ограничения
db.Migrator().DropConstraint(&User{}, "name_checker")

// Проверить существование ограничения
db.Migrator().HasConstraint(&User{}, "name_checker")
```

### Индексы

```go
type User struct {
  gorm.Model
  Name string `gorm:"size:255;index:idx_name,unique"`
}

// Создать индекс на колонке Name
db.Migrator().CreateIndex(&User{}, "Name")
db.Migrator().CreateIndex(&User{}, "idx_name")

// Удалить индекс на колонке Name
db.Migrator().DropIndex(&User{}, "Name")
db.Migrator().DropIndex(&User{}, "idx_name")

// Проверка существования индекса
db.Migrator().HasIndex(&User{}, "Name")
db.Migrator().HasIndex(&User{}, "idx_name")

type User struct {
  gorm.Model
  Name  string `gorm:"size:255;index:idx_name,unique"`
  Name2 string `gorm:"size:255;index:idx_name_2,unique"`
}
// Изменить имя индекса
db.Migrator().RenameIndex(&User{}, "Name", "Name2")
db.Migrator().RenameIndex(&User{}, "idx_name", "idx_name_2")
```

## Ограничения

GORM creates constraints when auto migrating or creating table, checkout [Constraints](constraints.html) or [Database Indexes](indexes.html) for details

## Другие инструменты миграции

GORM's AutoMigrate works well for most cases, but if you are looking for more serious migration tools, GORM provides a generic DB interface that might be helpful for you.

```go
// returns `*sql.DB`
db.DB()
```

Refer [Generic Interface](generic_interface.html) for more details.
