---
title: 设置
layout: page
---

GORM 提供了 `Set`, `Get`, `InstanceSet`, `InstanceGet` 方法来允许用户传值给 [勾子](hooks.html) 或其他方法

Gorm 中有一些特性用到了这种机制，如迁移表格时传递表格选项。

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

使用 `InstanceSet` / `InstanceGet` 传递设置到 `*Statement` 的钩子方法，例如：

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

// 在创建关联时，GORM 创建了一个新 `*Statement`，所以它不能读取到其它实例的设置
func (card *CreditCard) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.InstanceGet("my_value")
  // ok => false
  // myValue => nil
}

myValue := 123
db.InstanceSet("my_value", myValue).Create(&User{})
```
