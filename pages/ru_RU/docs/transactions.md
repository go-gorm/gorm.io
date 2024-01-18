---
title: Транзакции
layout: страница
---

## Отключить транзакцию по умолчанию

GORM выполняет операции записи (создания/обновления/удаления) внутри транзакции, чтобы обеспечить целостность данных, вы можете отключить транзакции в процессе инициализации, если они не требуются, что приводит к приросту производительности примерно в +30%

```go
// Глобальное отключение
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})

// Режим сессии
tx := db.Session(&Session{SkipDefaultTransaction: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)
```

## Транзакция

Для выполнения ряда операций в рамках транзакции, общий шаблон выполнения приводится ниже.

```go
db.Transaction(func(tx *gorm.DB) error {
  // выполняем операции с БД в транзакции (используйте 'tx' вмсето 'db')
  if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
    // возврат любой ошибки, откатит транзакцию
    return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
    return err
  }

  // возврат nil сделает фиксацию всей транзакции
  return nil
})
```

### Вложенные транзакции

GORM поддерживает вложенные транзакции, вы можете откатить подмножество операций, выполняемых в рамках более крупной транзакции, например:

```go
db.Transaction(func(tx *gorm.DB) error {
  tx.Create(&user1)

  tx.Transaction(func(tx2 *gorm.DB) error {
    tx2.Create(&user2)
    return errors.New("rollback user2") // Rollback user2
  })

  tx.Transaction(func(tx3 *gorm.DB) error {
    tx3.Create(&user3)
    return nil
  })

  return nil
})

// Commit user1, user3
```

## Control the transaction manually

Gorm supports calling transaction control functions (commit / rollback) directly, for example:

```go
// начало транзакции
tx := db.Begin()

// выполнить операции с БД в транзакции (используйте 'tx' вместо 'db')
tx.Create(...)

// ...

// откатить транзакцию в случае ошибки
tx.Rollback()

// фиксация транзакции
tx.Commit()
```

### Конкретный пример

```go
func CreateAnimals(db *gorm.DB) error {
  // Используйте tx как объект БД пока вы в транзакции
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

## SavePoint, RollbackTo

GORM provides `SavePoint`, `RollbackTo` to save points and roll back to a savepoint, for example:

```go
tx := db.Begin()
tx.Create(&user1)

tx.SavePoint("sp1")
tx.Create(&user2)
tx.RollbackTo("sp1") // Rollback user2

tx.Commit() // Commit user1
```
