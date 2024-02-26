---
title: Settings
layout: page
---

GORM provides `Set`, `Get`, `InstanceSet`, `InstanceGet` methods allow users pass values to [hooks](hooks.html) or other methods

GORM uses this for some features, like pass creating table options when migrating table.

```go
// Add table suffix when creating tables
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## Set / Get

Use `Set` / `Get` pass settings to hooks methods, for example:

```go
type User struct {
  gorm. Model
  CreditCard CreditCard
  // ...
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.InstanceGet("my_value")
  // ok => true
  // myValue => 123
}

type CreditCard struct {
  gorm. Model
  // ...
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.InstanceGet("my_value")
  // ok => true
  // myValue => 123
}

type CreditCard struct {
  gorm.
```


## InstanceSet / InstanceGet

Use `InstanceSet` / `InstanceGet` pass settings to current `*Statement`'s hooks methods, for example:

```go
type User struct {
  gorm. Model
  CreditCard CreditCard
  // ...
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.InstanceGet("my_value")
  // ok => true
  // myValue => 123
}

type CreditCard struct {
  gorm. Model
  // ...
}

// When creating associations, GORM creates a new `*Statement`, so can't read other instance's settings
func (card *CreditCard) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.InstanceGet("my_value")
  // ok => false
  // myValue => nil
}

myValue := 123
db.InstanceSet("my_value", myValue).Create(&User{})
```
