---
title: Transaction
layout: page
---

To perform a set of operations within a transaction, the general flow is as below.

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

## Nested Transactions

GEN supports nested transactions, you can rollback a subset of operations performed within the scope of a larger transaction, for example:

```go
q := query.Use(db)

q.Transaction(func(tx *query.Query) error {
  tx.User.WithContext(ctx).Create(&user1)

  tx.Transaction(func(tx2 *query.Query) error {
    tx2.User.WithContext(ctx).Create(&user2)
    return errors.New("rollback user2") // Rollback user2
  })

  tx.Transaction(func(tx2 *query.Query) error {
    tx2.User.WithContext(ctx).Create(&user3)
    return nil
  })

  return nil
})

// Commit user1, user3
```

## Transactions by manual

```go
q := query.Use(db)

// begin a transaction
tx := q.Begin()

// do some database operations in the transaction (use 'tx' from this point, not 'db')
tx.User.WithContext(ctx).Create(...)

// ...

// rollback the transaction in case of error
tx.Rollback()

// Or commit the transaction
tx.Commit()
```

For example:

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

GEN provides `SavePoint`, `RollbackTo` to save points and roll back to a savepoint, for example:

```go
tx := q.Begin()
txCtx = tx.WithContext(ctx)

txCtx.User.Create(&user1)

tx.SavePoint("sp1")
txCtx.Create(&user2)
tx.RollbackTo("sp1") // Rollback user2

tx.Commit() // Commit user1
```

