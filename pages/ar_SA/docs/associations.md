---
title: Associations
layout: page
---

## Auto Create/Update

GORM will autosave associations and its reference using [Upsert](create.html#upsert) when creating/updating a record.

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db. Select("Name"). Create(&user)
// INSERT INTO "users" (name) VALUES ("jinzhu", 1, 2);

db. Omit("BillingAddress"). Create(&user)
// Skip create BillingAddress when creating a user

db. Omit(clause. Associations). Create(&user)
// Skip all associations when creating a user
```

## Skip Auto Create/Update

To skip the auto save when creating/updating, you can use `Select` or `Omit`, for example:

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db. Select("Name"). Create(&user)
// INSERT INTO "users" (name) VALUES ("jinzhu", 1, 2);

db. Omit("BillingAddress"). Create(&user)
// Skip create BillingAddress when creating a user

db. Omit(clause. Associations). Create(&user)
// Skip all associations when creating a user
```

## Association Mode

Association Mode contains some commonly used helper methods to handle relationships

```go
db. Model(&user). Association("Languages").
```

### Find Associations

Find matched associations

```go
db. Model(&user). Association("Languages"). Count()
```

### Append Associations

Append new associations for `many to many`, `has many`, replace current association for `has one`, `belongs to`

```go
db. Model(&user). Association("Languages").
```

### Replace Associations

Replace current associations with new ones

```go
db. Model(&user). Association("Languages").
```

### Delete Associations

Remove the relationship between source & arguments if exists, only delete the reference, won't delete those objects from DB.

```go
db. Model(&user). Association("Languages").
```

### Clear Associations

Remove all reference between source & association, won't delete those associations

```go
db. Model(&user). Association("Languages").
```

### Count Associations

Return the count of current associations

```go
db. Model(&user). Association("Languages"). Count()
```

### Batch Data

Association Mode supports batch data, e.g:

```go
// Find all roles for all users
db.Model(&users).Association("Role").Find(&roles)

// Delete User A from all users's team
db.Model(&users).Association("Team").Delete(&userA)

// Get unduplicated count of members in all user's team
db.Model(&users).Association("Team").Count()

// For `Append`, `Replace` with batch data, arguments's length need to equal to data's length or will returns error
var users = []User{user1, user2, user3}
// e.g: we have 3 users, Append userA to user1's team, append userB to user2's team, append userA, userB and userC to user3's team
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Reset user1's team to userA，reset user2's team to userB, reset user3's team to userA, userB and userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="tags">Association Tags</span>

| Tag              | Description                                     |
| ---------------- | ----------------------------------------------- |
| foreignKey       | Specifies foreign key                           |
| references       | Specifies references                            |
| polymorphic      | Specifies polymorphic type                      |
| polymorphicValue | Specifies polymorphic value, default table name |
| many2many        | Specifies join table name                       |
| jointForeignKey  | Specifies foreign key of jointable              |
| joinReferences   | Specifies references' foreign key of jointable  |
| constraint       | Relations constraint                            |
