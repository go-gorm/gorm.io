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
    // 在事务中做一些数据库操作 (这里应该使用 'tx' ，而不是 'db')
    if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
      // 返回任意 err ，整个事务都会 rollback
      return err
    }

    if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
      return err
    }

    // 返回 nil 提交事务
    return nil
  })
}
```

## 事务（手动控制）

```go
// 开启事务
tx := db.Begin()

// 在事务中做一些数据库操作 (这里应该使用 'tx' ，而不是 'db')
tx.Create(...)

// ...

// 有错误时，手动调用事务的 Rollback()
tx.Rollback()

// 无错误时，手动调用事务的 Commit()
tx.Commit()
```

## 一个具体的例子

```go
func CreateAnimals(db *gorm.DB) error {
  // 请注意，事务一旦开始，你就应该使用 tx 作为数据库句柄
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
