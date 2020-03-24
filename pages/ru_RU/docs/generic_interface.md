---
title: Нативный интерфейс базы данных sql.DB
layout: страница
---

GORM предоставляет метод `DB`, который возвращает нативный интерфейс базы данных [*sql.DB](http://golang.org/pkg/database/sql/#DB) из текущего `*gorm.DB` соединения

```go
// Получение нативного объекта базы данных sql.DB для использования его функций
db.DB()

// Пинг
db.DB().Ping()
```

**NOTE** If the underlying database connection is not a `*sql.DB`, like in a transaction, it will return `nil`

## Пул подключений

```go
// SetMaxIdleConns устанавливает максимальное количество соединений в пуле соединений.
db.DB().SetMaxIdleConns(10)

// SetMaxOpenConns устанавливает максимальное количество открытых соединений к базе данных.
db.DB().SetMaxOpenConns(100)

// SetConnMaxLifetime устанавливает максимальное количество времени, за которое подключение может быть повторно использовано.
db.DB().SetConnMaxLifetime(time.Hour)
```