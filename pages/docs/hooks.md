---
title: Hooks
layout: page
---

## Object Life Cycle

Hooks are functions that are called before or after creation/querying/updating/deletion.

If you have defiend specified methods for a model, it will be called automatically when creating, updating, querying, deleting, and if any callback returns an error, GORM will stop future operations and rollback current transaction.

## Hooks

### Creating an object

Available hooks for creating

```go
// begin transaction
BeforeSave
BeforeCreate
// save before associations
// update timestamp `CreatedAt`, `UpdatedAt`
// save self
// reload fields that have default value and its value is blank
// save after associations
AfterCreate
AfterSave
// commit or rollback transaction
```

Code Example:

```go
func (u *User) BeforeSave() (err error) {
	if u.IsValid() {
		err = errors.New("can't save invalid data")
	}
	return
}

func (u *User) AfterCreate(scope *gorm.Scope) (err error) {
	if u.ID == 1 {
    scope.DB().Model(u).Update("role", "admin")
  }
	return
}
```

**NOTE** Save/Delete operations in GORM are running in transactions by default, so changes made in that transaction are not visible until it is commited.
If you would like access those changes in your hooks, you could accept current tranaction as argument in your hooks, for example:

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
	tx.Model(u).Update("role", "admin")
	return
}
```

### Updating an object

Available hooks for updating

```go
// begin transaction
BeforeSave
BeforeUpdate
// save before associations
// update timestamp `UpdatedAt`
// save self
// save after associations
AfterUpdate
AfterSave
// commit or rollback transaction
```

Code Example:

```go
func (u *User) BeforeUpdate() (err error) {
	if u.readonly() {
		err = errors.New("read only user")
	}
	return
}

// Updating data in same transaction
func (u *User) AfterUpdate(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("verfied", true)
  }
	return
}
```

### Deleting an object

Available hooks for deleting

```go
// begin transaction
BeforeDelete
// delete self
AfterDelete
// commit or rollback transaction
```

Code Example:

```go
// Updating data in same transaction
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
	return
}
```

### Querying an object

Available hooks for querying

```go
// load data from database
// Preloading (eager loading)
AfterFind
```

Code Example:

```go
func (u *User) AfterFind() (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
	return
}
```
