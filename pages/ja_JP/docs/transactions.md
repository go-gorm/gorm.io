---
title: トランザクション
layout: page
---

GORMはデフォルトで1つの`create`, `update`, `delete`操作をトランザクション内で行います。これはデータベース上のデータ整合性を確保するためです。

If you want to treat multiple `create`, `update`, `delete` as one atomic operation, `Transaction` is made for that.

## トランザクション

トランザクション内で複数操作をまとめて実行するための、一般的なフローは以下の通りです。

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