title: Transactions
---

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

### A Specific Example

```go
func CreateAnimals(db *gorm.DB) err {
  tx := db.Begin()
  // Note the use of tx as the database handle once you are within a transaction

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
