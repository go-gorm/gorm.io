---
title: Settings
layout: page
---

GORM 提供了 `Set`, `Get`, `InstanceSet`, `InstanceGet` 方法来允许用户传值给 [勾子](hooks.html) 或其他方法

GORM uses this for some features, like pass creating table options when migrating table. Gorm 中有一些特性用了这种机制，如迁移表格时传递表格选项。

```go
// 创建表时添加表后缀
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## Set / Get

使用 `Set` / `Get` 传递设置到钩子方法，例如：

```go
type User struct {
  gorm.Model
  CreditCard CreditCard
  // ...
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.Get("my_value")
  // ok => true
  // myValue => 123
}

type CreditCard struct {
  gorm.Model
  // ...
}

func (card *CreditCard) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.Get("my_value")
  // ok => true
  // myValue => 123
}

myValue := 123
db.Set("my_value", myValue).Create(&User{})
```


## InstanceSet / InstanceGet

Use `InstanceSet` / `InstanceGet` pass settings to current `*Statement`'s hooks methods, for example:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard
  // ...
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.InstanceGet("my_value")
  // ok => true
  // myValue => 123
}

type CreditCard struct {
  gorm.Model
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
