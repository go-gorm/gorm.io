---
title: Предзагрузка данных (Жадная загрузка)
layout: страница
---

## Preload

```go
// struct User и Order 
type User struct {
  gorm.Model
  Username string
  Orders Order
}
type Order struct {
  gorm.Model
  UserID uint
  Price float64
}
// Значение функции Preload должно быть названием поля основного struct
db.Preload("Orders").Find(&users)
//// SELECT * FROM users;
//// SELECT * FROM orders WHERE user_id IN (1,2,3,4);

db.Preload("Orders", "state NOT IN (?)", "cancelled").Find(&users)
//// SELECT * FROM users;
//// SELECT * FROM orders WHERE user_id IN (1,2,3,4) AND state NOT IN ('cancelled');

db.Where("state = ?", "active").Preload("Orders", "state NOT IN (?)", "cancelled").Find(&users)
//// SELECT * FROM users WHERE state = 'active';
//// SELECT * FROM orders WHERE user_id IN (1,2) AND state NOT IN ('cancelled');

db.Preload("Orders").Preload("Profile").Preload("Role").Find(&users)
//// SELECT * FROM users;
//// SELECT * FROM orders WHERE user_id IN (1,2,3,4); // has many
//// SELECT * FROM profiles WHERE user_id IN (1,2,3,4); // has one
//// SELECT * FROM roles WHERE id IN (4,5,6); // belongs to
```

## Авто предзагрузка

Всегда автоматически загружать ассоциации

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"PRELOAD:false"` // не предзагружать
  Role       Role                           // предзагружать
}

db.Set("gorm:auto_preload", true).Find(&users)
```

## Вложенная предзагрузка

```go
db.Preload("Orders.OrderItems").Find(&users)
db.Preload("Orders", "state = ?", "paid").Preload("Orders.OrderItems").Find(&users)
```

## Предзагрузка пользовательского SQL

Вы можете настроить предзагрузку пользовательского SQL, с помощью `func(db *gorm.DB) *gorm.DB`, например:

```go
db.Preload("Orders", func(db *gorm.DB) *gorm.DB {
  return db.Order("orders.amount DESC")
}).Find(&users)
//// SELECT * FROM users;
//// SELECT * FROM orders WHERE user_id IN (1,2,3,4) order by orders.amount DESC;
```