---
title: Gen Transaction
layout: page
---

The process of using transaction functions is as follows

```go
q := query.Use(db)

q.Transaction(func(tx *query.Query) error {
  if _, err := tx.User.WithContext(ctx).Where(tx.User.ID.Eq(100)).Delete(); err != nil {
    return err
  }
  if err := tx.Article.WithContext(ctx).Create(&model.Article{Name: "modi"}); err != nil {
    return err
  }
  return nil
})
```

`q.Transaction` wraps GORM's transaction: the callback receives a `*query.Query`
bound to the transaction; returning an error (or panicking) rolls back, returning
`nil` commits. Isolation can be set with the standard `*sql.TxOptions`:

```go
err := q.Transaction(func(tx *query.Query) error {
	// tx.User, tx.Order, ... share the transaction connection
	return nil
}, &sql.TxOptions{Isolation: sql.LevelReadCommitted, ReadOnly: true})
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

  tx.Transaction(func(tx3 *query.Query) error {
    tx3.User.WithContext(ctx).Create(&user3)
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

// check tx.Error — a failed BEGIN leaves the transaction unusable
if tx.Error != nil {
  return tx.Error
}
defer tx.Rollback() // no-op after Commit

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
    if tx.Error != nil {
        return tx.Error
    }
    // Panic policy: on a panic we roll back and re-panic so the caller sees it;
    // on a returned error we roll back and report it normally.
    defer func() {
        if r := recover(); r != nil {
            _ = tx.Rollback()
            panic(r)
        }
    }()
    defer func() {
        if err != nil {
            _ = tx.Rollback()
        }
    }()

    if err = tx.User.WithContext(ctx).Create(users...); err != nil {
        return
    }
    return tx.Commit()
}
```

`q.Begin` also accepts `*sql.TxOptions`. It returns a `*query.QueryTx`, which
embeds the full `*query.Query`, so all DAOs are available on `tx` (`tx.User`,
`tx.Order`, …), plus `Commit` / `Rollback` / `SavePoint` / `RollbackTo`.

## SavePoint/RollbackTo

GEN provides `SavePoint`, `RollbackTo` to save points and roll back to a savepoint, for example:

```go
tx := q.Begin()
txCtx := tx.WithContext(ctx)

txCtx.User.Create(&user1)

tx.SavePoint("sp1")
txCtx.User.Create(&user2)
tx.RollbackTo("sp1") // Rollback user2

tx.Commit() // Commit user1
```

