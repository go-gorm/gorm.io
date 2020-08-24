---
title: Delete
layout: page
---

## Delete a Record

When deleting a record, the deleted value needs to have primary key or it will trigger a [Batch Delete](#batch_delete), for example:

```go
// Email's ID is `10`
db.Delete(&email)
// DELETE from emails where id = 10;

// Delete with additional conditions
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE from emails where id = 10 AND name = "jinzhu";
```

## Delete Hooks

GORM allows hooks `BeforeDelete`, `AfterDelete`, those methods will be called when deleting a record, refer [Hooks](hooks.html) for details

```go
func (u *User) BeforeDelete(tx *gorm.DB) (err error) {
    if u. Role == "admin" {
        return errors. New("admin user not allowed to delete")
    }
    return
}
```

## <span id="batch_delete">Batch Delete</span>

The specified value has no priamry value, GORM will perform a batch delete, it will delete all matched records

```go
db. Where("email LIKE ?", "%jinzhu%"). Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db. Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### Block Global Delete

If you perform a batch delete without any conditions, GORM WON'T run it, and will return `ErrMissingWhereClause` error

You have to use some conditions or use raw SQL or enable `AllowGlobalUpdate` mode, for example:

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE FROM `users` WHERE 1=1

db.Exec("DELETE FROM users")
// DELETE FROM users

DB.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// DELETE FROM users
```

## Soft Delete

If you don't want to include `gorm. Model`, you can enable the soft delete feature like:

When calling `Delete`, the record WON'T be removed from the database, but GORM will set the `DeletedAt`'s value to the current time, and the data is not findable with normal Query methods anymore.

```go
// user's ID is `111`
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Batch Delete
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Soft deleted records will be ignored when querying
db.Where("age = 20").Find(&user)
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

If you don't want to include `gorm. Model`, you can enable the soft delete feature like:

```go
type User struct {
  ID      int
  Deleted gorm. DeletedAt
  Name    string
}
```

### Find soft deleted records

You can find soft deleted records with `Unscoped`

```go
db. Unscoped(). Where("age = 20"). Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### Delete permanently

You can delete matched records permanently with `Unscoped`

```go
db. Unscoped(). Delete(&order)
// DELETE FROM orders WHERE id=10;
```
