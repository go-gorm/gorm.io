---
title: Gen Delete
layout: page
---

#### Delete

##### Delete record

```go
e := query.Use(db).Email

// Email's ID is `10`
e.WithContext(ctx).Where(e.ID.Eq(10)).Delete()
// DELETE from emails where id = 10;

// Delete with additional conditions
e.WithContext(ctx).Where(e.ID.Eq(10), e.Name.Eq("modi")).Delete()
// DELETE from emails where id = 10 AND name = "modi";

result, err := e.WithContext(ctx).Where(e.ID.Eq(10), e.Name.Eq("modi")).Delete()

result.RowsAffected // affect rows number
err                 // error
```

##### Delete with primary key

GEN allows to delete objects using primary key(s) with inline condition, it works with numbers.

```go
u.WithContext(ctx).Where(u.ID.In(1,2,3)).Delete()
// DELETE FROM users WHERE id IN (1,2,3);
```

##### Batch Delete

The specified value has no primary value, GEN will perform a batch delete, it will delete all matched records

```go
e := query.Use(db).Email

e.WithContext(ctx).Where(e.Name.Like("%modi%")).Delete()
// DELETE from emails where email LIKE "%modi%";
```

##### Soft Delete

If your model includes a `gorm.DeletedAt` field (which is included in `gorm.Model`), it will get soft delete ability automatically!

When calling `Delete`, the record WON’T be removed from the database, but GORM will set the `DeletedAt`‘s value to the current time, and the data is not findable with normal Query methods anymore.

```go
// Batch Delete
u.WithContext(ctx).Where(u.Age.Eq(20)).Delete()
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Soft deleted records will be ignored when querying
users, err := u.WithContext(ctx).Where(u.Age.Eq(20)).Find()
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

If you don’t want to include `gorm.Model`, you can enable the soft delete feature like:

```go
type User struct {
    ID      int
    Deleted gorm.DeletedAt
    Name    string
}
```

##### Find soft deleted records

You can find soft deleted records with `Unscoped`

```go
users, err := db.WithContext(ctx).Unscoped().Where(u.Age.Eq(20)).Find()
// SELECT * FROM users WHERE age = 20;
```

##### Delete permanently

You can delete matched records permanently with `Unscoped`

```go
o.WithContext(ctx).Unscoped().Where(o.ID.Eq(10)).Delete()
// DELETE FROM orders WHERE id=10;
```

###### Delete Associations

Remove the relationship between source & arguments if exists, only delete the reference, won’t delete those objects from DB.

```go
u := query.Use(db).User

u.Languages.Model(&user).Delete(&languageZH, &languageEN)

u.Languages.Model(&user).Delete([]*Language{&languageZH, &languageEN}...)
```

###### Delete with Select

You are allowed to delete selected has one/has many/many2many relations with `Select` when deleting records, for example:

```go
u := query.Use(db).User

// delete user's account when deleting user
u.Select(u.Account).Delete(&user)

// delete user's Orders, CreditCards relations when deleting user
db.Select(u.Orders.Field(), u.CreditCards.Field()).Delete(&user)

// delete user's has one/many/many2many relations when deleting user
db.Select(field.AssociationsFields).Delete(&user)
```