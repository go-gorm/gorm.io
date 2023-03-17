---
title: Gen Transaction
layout: page
---

使用事务：

```go
q := query.Use(db)

q.Transaction(func(tx *query.Query) error {
  if _, err := tx.User.WithContext(ctx).Where(tx.User.ID.Eq(100)).Delete(); err != nil {
    return err
  }
  if _, err := tx.Article.WithContext(ctx).Create(&model.User{Name:"modi"}); err != nil {
    return err
  }
  return nil
})
```

## 嵌套事务

GORM 支持嵌套事务，您可以回滚较大事务内执行的一部分操作，例如：

```go
q := query.Use(db)

q.Transaction(func(tx *query.Query) error {
  tx.User.WithContext(ctx).Create(&user1)

  tx.Transaction(func(tx2 *query.Query) error {
    tx2.User.WithContext(ctx).Create(&user2)
    return errors.New("rollback user2") // Rollback user2
  })

  tx.Transaction(func(tx3 *query.Query) error {
    tx3.User.WithContext(ctx).Create(&user3)
    return nil
  })

  return nil
})

// Commit user1, user3
```

## 手动事务

```go
// 开始事务
tx := db.Begin()

// 在事务中执行一些 db 操作（从这里开始，您应该使用 'tx' 而不是 'db'）
tx.Create(...)

// ...

// 遇到错误时回滚事务
tx.Rollback()

// 否则，提交事务
tx.Commit()
```

例如:

```go
q := query.Use(db)

func doSomething(ctx context.Context, users ...*model.User) (err error) {
    tx := q.Begin()
    defer func() {
        if recover() != nil || err != nil {
            _ = tx.Rollback()
        }
    }()

    err = tx.User.WithContext(ctx).Create(users...)
    if err != nil {
        return
    }
    return tx.Commit()
}
```

## SavePoint/RollbackTo

GORM 提供了 `SavePoint`、`Rollbackto` 方法，来提供保存点以及回滚至保存点功能，例如：

```go
tx := q.Begin()
txCtx = tx.WithContext(ctx)

txCtx.User.Create(&user1)

tx.SavePoint("sp1")
txCtx.Create(&user2)
tx.RollbackTo("sp1") // Rollback user2

tx.Commit() // Commit user1
```

