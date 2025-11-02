---
title: Associations
layout: page
---

# Associations

Field helpers make it easy to touch parents and related records in one builder. Here’s how the generated structs combine.

## Update parent fields and append children

```go
err := gorm.G[User](db).
  Where(generated.User.ID.Eq(userID)).
  Set(
    generated.User.Status.Set("active"),
    generated.User.Profiles.Update(
      generated.Profile.LastLogin.Set(time.Now()),
    ),
    generated.User.Devices.Create(
      generated.Device.Name.Set("iphone"),
      generated.Device.PushToken.Set(token),
    ),
  ).
  Update(ctx)
```

The generator emits helpers for each association (`Profiles`, `Devices`). Chain them inside the same `Set(...)` call alongside parent updates.

## Replace many-to-many links

```go
err := gorm.G[Team](db).
  Where(generated.Team.ID.Eq(teamID)).
  Set(
    generated.Team.Members.Unlink(),
    generated.Team.Members.CreateInBatch(newMembers),
  ).
  Update(ctx)
```

`Unlink` clears existing join rows, and `CreateInBatch` seeds the new slice—no manual join-table work needed.

## Create a parent with nested associations

```go
err := gorm.G[Order](db).
  Set(
    generated.Order.Number.Set(nextNumber()),
    generated.Order.Items.CreateInBatch([]models.OrderItem{
      {SKU: "sku-1", Quantity: 2},
      {SKU: "sku-2", Quantity: 1},
    }),
    generated.Order.Payments.Create(
      generated.Payment.Provider.Set("stripe"),
      generated.Payment.Status.Set("pending"),
    ),
  ).
  Create(ctx)
```

A single `Create(ctx)` call inserts the parent and cascades through the generated association helpers.

Return to [Transactions](tutorials_transactions.html) or the [CLI overview](index.html).
