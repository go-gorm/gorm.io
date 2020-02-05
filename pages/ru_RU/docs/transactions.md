---
title: Транзакции
layout: страница
---

GORM выполняет одиночный `create`, `update`, `delete` в транзакциях по умолчанию, чтобы гарантировать целостность данных базы данных.

Если вы хотите обработать несколько `create`, `update`, `delete` в качестве одной операции, `Transaction` сделана для этого.

## Транзакции

Для выполнения набора операций в рамках транзакции, выполняйте запросы как указано ниже.

```go
func CreateAnimals(db *gorm.DB) error {
  return db.Transaction(func(tx *gorm.DB) error {
    // выполните операции с БД в транзакции (используйте 'tx' вместо 'db')
    if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
      // возвращение ошибки приведет к откату транзакции
      return err
    }

    if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
      return err
    }

    // возврат nil совершит коммит транзакции
    return nil
  })
}
```

## Транзакции вручную

```go
// начало транзакции
tx := db.Begin()

// выполните операции с БД в транзакции (используйте 'tx' вместо 'db')
tx.Create(...)

// ...

// откат транзакции в случае ошибки
tx.Rollback()

// или коммит транзакции
tx.Commit()
```

## Конкретный пример

```go
func CreateAnimals(db *gorm.DB) error {
  // ВНИМАНИЕ! Используйте tx в качестве хендлера в транзакции
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