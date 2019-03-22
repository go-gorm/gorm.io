---
title: Миграции
layout: страница
---
## Автоматические миграции

Автоматически мигрирует схему, чтобы сохранить обновление схемы актуальными.

**ВНИМАНИЕ:** AutoMigrate будет **ТОЛЬКО** создавать таблицы, недостающие столбцы и отсутствующие индексы, и **НЕ БУДЕТ** изменить тип существующего столбца или удалить неиспользуемые столбцы для защиты ваших данных.

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// Добавит суфикс таблицы когда добавляется таблица
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## Другие инструменты миграции

GORM AutoMigrate работает хорошо для большинства случаев, но если вы ищете более серьезные инструменты миграции, GORM предоставляет общий интерфейс DB, который может быть полезен для вас.

```go
// вернет `*sql.DB`
db.DB()
```

Подробнее см. [Общий интерфейс](/docs/generic_interface.html).

## Методы схемы

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