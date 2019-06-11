---
title: Транзакции
layout: страница
---

GORM выполняет одиночный `create`, `update`, `delete` в транзакциях по умолчанию, чтобы гарантировать целостность данных базы данных.

Если вы хотите обработать несколько `create`, `update`, `delete` в качестве одной операции, `Transaction` сделана для этого.

## Транзакции

Для выполнения набора операций в рамках транзакции, выполняйте запросы как указано ниже.

```go
// начать транзакцию
tx := db.Begin()

// работа с базой Данных в транзакции (используйте 'tx', не 'db')
tx.Create(...)

// ...

// откат транзакции в случае ошибки
tx.Rollback()

// Или фиксировать транзакцию
tx.Commit()
```

## Конкретный пример

```go
func CreateAnimals(db *gorm.DB) error {
  // Используете только tx в качестве объекта БД пока вы в транзакции
  tx := db.Begin()
  defer func() {
    if r := recover(); r != nil {
      tx.Rollback()
    }
  }()

  if err := tx.Error; err != nil {
    return err
  }

  if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  return tx.Commit().Error
}
```
