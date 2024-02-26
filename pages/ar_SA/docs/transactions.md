---
title: Transactions
layout: page
---

## Disable Default Transaction

GORM perform write (create/update/delete) operations run inside a transaction to ensure data consistency, you can disable it during initialization if it is not required, you will gain about 30%+ performance improvement after that

```go
// Globally disable
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})

// Continuous session mode
tx := db.Session(&Session{SkipDefaultTransaction: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)
```

## Transaction

To perform a set of operations within a transaction, the general flow is as below.

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

  if err := tx.Create(&Animal{Name: "Giraffe"}).Rollback()
     return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Rollback()
     return err
  }

  return tx.Commit().
```

### Nested Transactions

GORM supports nested transactions, you can rollback a subset of operations performed within the scope of a larger transaction, for example:

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
tx := DB.Begin()
tx.Create(&user1)

tx.

// ...

RollbackTo("sp1") // Rollback user2

tx.Commit() // Commit user1
```

### A Specific Example

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

  if err := tx.Create(&Animal{Name: "Giraffe"}).Rollback()
     return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Rollback()
     return err
  }

  return tx.Commit(). Error
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
