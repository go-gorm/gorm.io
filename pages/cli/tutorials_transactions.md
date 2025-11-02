---
title: Transactions
layout: page
---

# Transactions

CLI-generated query methods and helpers accept any `*gorm.DB`, so they drop straight into your transaction logic.

## Wrap reads and writes in one callback

```go
err := db.Transaction(func(tx *gorm.DB) error {
  // Query method generated from interface + SQL comment
  order, err := generated.Query[Order](tx).GetForUpdate(ctx, orderID)
  if err != nil {
    return err
  }

  // Field helpers generated from models
  return gorm.G[Order](tx).
    Where(generated.Order.ID.Eq(order.ID)).
    Set(
      generated.Order.Status.Set("shipped"),
      generated.Order.ShippedAt.Set(time.Now()),
    ).
    Update(ctx)
})
```

Nothing special is required: pass the transactional `tx` everywhere and return an error to roll back.

## Compose multiple generated calls

```go
err := db.Transaction(func(tx *gorm.DB) error {
  repo := generated.Query[Invoice](tx)

  invoice, err := repo.GetByNumber(ctx, number)
  if err != nil {
    return err
  }

  if err := repo.MarkProcessing(ctx, invoice.ID); err != nil {
    return err
  }

  return gorm.G[Invoice](tx).
    Where(generated.Invoice.ID.Eq(invoice.ID)).
    Set(generated.Invoice.ProcessedAt.Set(time.Now())).
    Update(ctx)
})
```

You can mix generated interface methods and field helpers inside the same transaction; both respect the current `*gorm.DB` state.

Next: see how the helpers manage [Associations](tutorials_associations.html) or return to the [CLI overview](index.html).
