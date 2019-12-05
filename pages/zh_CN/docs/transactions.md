---
title: 事务
layout: page
---

GORM 默认会将单个的 `create`, `update`, `delete`操作封装在事务内进行处理，以确保数据的完整性。

如果你想把多个 `create`, `update`, `delete` 操作作为一个原子操作，`Transaction` 就是用来完成这个的。

## 事务

要在事务中执行一系列操作，通常您可以参照下面的流程来执行。

```go
func CreateAnimals(db *gorm.DB) error {
  return db.Transaction(func(tx *gorm.DB) error {
    // do some database operations in the transaction (use 'tx' from this point, not 'db')
    if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
      // return any error will rollback
      return err
    }

    if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
      return err
    }

    // return nil will commit
    return nil
  })
}
```

## Transactions by manual

```go
// begin a transaction
tx := db.Begin()

// do some database operations in the transaction (use 'tx' from this point, not 'db')
tx.Create(...)

// ...

// rollback the transaction in case of error
tx.Rollback()

// Or commit the transaction
tx.Commit()
```

## A Specific Example

```go
func CreateAnimals(db *gorm.DB) error {
  // Note the use of tx as the database handle once you are within a transaction
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