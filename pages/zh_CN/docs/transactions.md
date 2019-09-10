---
title: 事务
layout: page
---

GORM 默认会将单个的 `create`, `update`, `delete`操作封装在事务内进行处理，以确保数据的完整性。

如果你想把多个 `create`, `update`, `delete` 操作作为一个原子操作，`Transaction` 就是用来完成这个的。

## 事务

要在事务中执行一系列操作，通常您可以参照下面的流程来执行。

```go
// 开启事务
tx := db.Begin()

// 在事务中执行具体的数据库操作 (事务内的操作使用 'tx' 执行，而不是 'db')
tx.Create(...)

// ...

// 如果发生错误则执行回滚
tx.Rollback()

// 或者（未发生错误时）提交事务
tx.Commit()
```

## 一个具体的例子

```go
func CreateAnimals(db *gorm.DB) error {
  // 注意，当你在一个事务中应使用 tx 作为数据库句柄
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