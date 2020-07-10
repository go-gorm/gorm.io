---
title: Delete
layout: page
---

## Delete Record

Delete a record

```go
Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db. Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
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

## Batch Delete

If we havn't specify a record having priamry key value, GORM will perform a batch delete all matched records

```go
db. Where("email LIKE ?", "%jinzhu%"). Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db. Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### Block Global Delete

If you perform a batch delete without any conditions, GORM WON'T run it, and will returns `ErrMissingWhereClause` error

You can use conditions like `1 = 1` to force the global delete

```go
db. Unscoped(). Delete(&order)
// DELETE FROM orders WHERE id=10;
```

## Soft Delete

If you don't want to include `gorm. Model`, you can enable the soft delete feature like:

When calling `Delete`, the record WON'T be removed from the database, but GORM will set the `DeletedAt`'s value to the current time, and the data is not findable with normal Query methods anymore.

```go
db. Unscoped(). Where("age = 20"). Find(&users)
// SELECT * FROM users WHERE age = 20;
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
