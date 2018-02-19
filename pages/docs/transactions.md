---
title: Transactions
layout: page
---

GORM perform single `create`, `update`, `delete` operations in transactions by default to ensure database data integrity.

If you want to tread multiple `create`, `update`, `delete` as one atomic operation, `Transaction` is made for that.

## Transactions

To perform a set of operations within a transaction, the general flow is as below.

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
func CreateAnimals(db *gorm.DB) err {
  // Note the use of tx as the database handle once you are within a transaction
  tx := db.Begin()
  defer func() {
    if r := recover(); r != nil {
      tx.Rollback()
    }
  }()

  if tx.Error != nil {
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
