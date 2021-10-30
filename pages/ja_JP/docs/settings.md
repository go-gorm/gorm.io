---
title: 値の受け渡し
layout: page
---

GORMには `Set`, `Get`, `InstanceSet`, `InstanceGet` メソッドがあり、これらを使うことで [hooks](hooks.html) や他のメソッドに値を受け渡すことができます。

GORMは、マイグレーション時にテーブルの作成オプションを渡す場合など、いくつかの機能でこれを使用します。

```go
// Add table suffix when creating tables
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## Set / Get

`Set` / `Get` を使用して hookメソッドに設定を受け渡すことができます。例：

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

`InstanceSet` / `InstanceGet` を使用して、現在の `*Statement` のhookメソッドに設定を受け渡すことができます。

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

// アソシエーション作成時に、GORMは新しい `*Statement` を作成します。そのため、他のインスタンスの設定を取得できません。
func (card *CreditCard) BeforeCreate(tx *gorm.DB) error {
  myValue, ok := tx.InstanceGet("my_value")
  // ok => false
  // myValue => nil
}

myValue := 123
db.InstanceSet("my_value", myValue).Create(&User{})
```
