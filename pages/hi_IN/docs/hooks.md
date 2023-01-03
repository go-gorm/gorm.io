---
title: Hooks
layout: page
---

## Object Life Cycle

Hooks are functions that are called before or after creation/querying/updating/deletion.

If you have defined specified methods for a model, it will be called automatically when creating, updating, querying, deleting, and if any callback returns an error, GORM will stop future operations and rollback current transaction.

The type of hook methods should be `func(*gorm.DB) error`

## Hooks

### Creating an object

Available hooks for creating

```go
// begin transaction
BeforeSave
BeforeCreate
// save before associations
// insert into database
// save after associations
AfterCreate
AfterSave
// commit or rollback transaction
```

Code Example:

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

  if !u.IsValid() {
    err = errors.New("can't save invalid data")
  }
  return
}

func (u *User) AfterCreate(tx *gorm.DB) (err error) {
  if u.ID == 1 {
    tx.Model(u).Update("role", "admin")
  }
  return
}
```

{% note warn %}
**NOTE** Save/Delete operations in GORM are running in transactions by default, so changes made in that transaction are not visible until it is committed, if you return any error in your hooks, the change will be rollbacked
{% endnote %}

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
  if !u.IsValid() {
    return errors.New("rollback invalid user")
  }
  return nil
}
```

### Updating an object

Available hooks for updating

```go
// begin transaction
BeforeSave
BeforeUpdate
// save before associations
// update database
// save after associations
AfterUpdate
AfterSave
// commit or rollback transaction
```

Code Example:

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
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
// delete from database
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
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
  return
}
```

## Modify current operation

```go
func (u *User) BeforeCreate(tx *gorm.DB) error {
  // Modify current operation through tx.Statement, e.g:
  tx.Statement.Select("Name", "Age")
  tx.Statement.AddClause(clause.OnConflict{DoNothing: true})

  // tx is new session mode with the `NewDB` option
  // operations based on it will run inside same transaction but without any current conditions
  var role Role
  err := tx.First(&role, "name = ?", user.Role).Error
  // SELECT * FROM roles WHERE name = "admin"
  // ...
  return err
}
```
