---
title: Method Chaining
layout: page
---

## Method Chaining

Gorm implements method chaining interface, so you could write code like this:

```go
db, err := gorm.Open("postgres", "user=gorm dbname=gorm sslmode=disable")

// create a new relation
tx := db.Where("name = ?", "jinzhu")

// add more filter
if someCondition {
    tx = tx.Where("age = ?", 20)
} else {
    tx = tx.Where("age = ?", 30)
}

if yetAnotherCondition {
    tx = tx.Where("active = ?", 1)
}
```

Query won't be generated until a immediate method, which could be useful in some cases.

Like you could extract a wrapper to handle some common logic

## Immediate Methods

Immediate methods are those methods that will generate SQL query and send it to database, usually it is those CRUD methods, like:

`Create`, `First`, `Find`, `Take`, `Save`, `UpdateXXX`, `Delete`, `Scan`, `Row`, `Rows`...


Here is an immediate methods example based on above chain:

```go
tx.Find(&user)
```

Generates

```sql
SELECT * FROM users where name = 'jinzhu' AND age = 30 AND active = 1;
```

## Scopes

Scope is build based on the method chaining theory.

With it, you could extract some generic logics, to write more reusable libraries.

```go
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
	return db.Where("amount > ?", 1000)
}

func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
	return db.Where("pay_mode_sign = ?", "C")
}

func PaidWithCod(db *gorm.DB) *gorm.DB {
	return db.Where("pay_mode_sign = ?", "C")
}

func OrderStatus(status []string) func (db *gorm.DB) *gorm.DB {
	return func (db *gorm.DB) *gorm.DB {
		return db.Scopes(AmountGreaterThan1000).Where("status in (?)", status)
	}
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Find all credit card orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Find all COD orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Find all paid, shipped orders that amount greater than 1000
```

## Multiple Immediate Methods

When using multiple immediate methods with GORM, later immediate method will reuse before immediate methods's query conditions (excluding inline conditions)

```go
db.Where("name LIKE ?", "jinzhu%").Find(&users, "id IN (?)", []int{1, 2, 3}).Count(&count)
```

Generates

```sql
SELECT * FROM users WHERE name LIKE 'jinzhu%' AND id IN (1, 2, 3)

SELECT count(*) FROM users WHERE name LIKE 'jinzhu%'
```

## Thread Safety

All Chain Methods will clone and create a new DB object (shares one connection pool), GORM is safe for concurrent use by multiple goroutines.
