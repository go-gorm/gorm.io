---
title: Миграции
layout: страница
---

## Автоматические миграции

Автоматически мигрирует схему, чтобы сохранить обновление схемы актуальными.

**ВНИМАНИЕ:** AutoMigrate будет **ТОЛЬКО** создавать таблицы, недостающие столбцы и отсутствующие индексы, и **НЕ БУДЕТ** изменять тип существующего столбца или удалять неиспользуемые столбцы для защиты ваших данных.

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

Подробнее см. [Общий интерфейс](generic_interface.html).

## Методы схемы

### Has Table

```go
// Проверить существует или нет модель таблицы `User`'s
db.HasTable(&User{})

// Проверить существует или нет таблица `users`
db.HasTable("users")
```

### Создание таблиц

```go
// Создать таблицу для модели `User`
db.CreateTable(&User{})

// добавит "ENGINE=InnoDB" в запрос при создании таблицы `users`
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})
```

### Удалить таблицу

```go
// Удалить модель `User`'s table
db.DropTable(&User{})

// Удалить таблицу `users`
db.DropTable("users")

// Удалить таблицу модели `User`'s и таблицу `products`
db.DropTableIfExists(&User{}, "products")
```

### Изменить столбец

Изменить тип столбца на заданное значение

```go
// изменяет тип колонки description на `text` для модели `User`
db.Model(&User{}).ModifyColumn("description", "text")
```

### Удаление столбца

```go
// Удаляет столбец description для модели `User`
db.Model(&User{}).DropColumn("description")
```

### Добавить индексы

```go
// Добавление индекса для столбца `name` с названием `idx_user_name`
db.Model(&User{}).AddIndex("idx_user_name", "name")

// Добавление индекса для столбцов `name`, `age` с названием `idx_user_name_age`
db.Model(&User{}).AddIndex("idx_user_name_age", "name", "age")

// Добавление уникального индекса
db.Model(&User{}).AddUniqueIndex("idx_user_name", "name")

// Добавление составного уникального индекса
db.Model(&User{}).AddUniqueIndex("idx_user_name_age", "name", "age")
```

### Удаление индекса

```go
// Удаление индекса
db.Model(&User{}).RemoveIndex("idx_user_name")
```

### Добавить внешний ключ

```go
// Добавление внешнего ключа
// 1ый параметр : foreignkey field "поле внешнего ключа"
// 2ой параметр : destination table(id) "таблица названичения"
// 3ий параметр : ONDELETE "при удалении"
// 4ый параметр : ONUPDATE "при обновлении"
db.Model(&User{}).AddForeignKey("city_id", "cities(id)", "RESTRICT", "RESTRICT")
```

### Удалить внешний ключ

```go
db.Model(&User{}).RemoveForeignKey("city_id", "cities(id)")
```
