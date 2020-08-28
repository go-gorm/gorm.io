---
title: Миграция
layout: страница
---

## Авто миграция

Автоматически переносит вашу схему, чтобы поддерживать обновление вашей схемы.

**NOTE:** AutoMigrate will create tables, missing foreign keys, constraints, columns and indexes, and will change existing column's type if it's size, precision, nullable changed, it **WON'T** delete unused columns to protect your data.

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// Добавляет суффикс таблицы при создании таблицы
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

**ПРИМЕЧАНИЕ** AutoMigrate создает ограничения внешних ключей автоматически, вы можете отключить эту функцию во время инициализации, например:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

## Интерфейс Мигратора

GORM предоставляет интерфейс миграции, который содержит единый интерфейс API для каждой базы данных, которые могут быть использованы для построения независимой от баз данных миграции, например:

SQLite не поддерживает `ALTER COLUMN`, `DROP COLUMN`, GORM создаст новую таблицу аналогичную той, которую вы пытаетесь изменить, скопирует все данные, сбросит старую таблицу, переименовав новую таблицу

MySQL не поддерживает переименование столбца, индекса для некоторых версий, GORM будет выполнять разные SQL, основанные на версии MySQL, которую вы используете

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

Возвращает имя текущей используемой базы данных

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

GORM создает ограничения при автоматическом переносе или создании таблицы, смогтрите [Ограничения](constraints.html) или [Индексы баз данных](indexes.html) для подробностей

## Другие инструменты миграции

GORM AutoMigrate хорошо работает для большинства случаев, но если вы ищете более серьезные инструменты миграции, GORM предоставляет универсальный интерфейс базы данных, который может быть полезным для вас.

```go
// returns `*sql.DB`
db.DB()
```

Смотрите [Общий интерфейс](generic_interface.html) для подробностей.
