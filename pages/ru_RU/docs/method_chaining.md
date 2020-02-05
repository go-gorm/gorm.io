---
title: Цепочка вызовов
layout: страница
---

## Цепочка вызовов

Gorm реализует метод цепочки интерфейса, так что вы можете писать код так:

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

Запрос не будет сгенерирован до тех пор, пока не будет применен немедленный метод, что может быть полезно в некоторых случаях.

Как вы можете извлечь обертку для обработки какой-либо общей логики

## Немедленные методы

Немедленные методы - это те методы, которые сгенерируют SQL запрос и отправляют его в базу данных, обычно это такие CRUD методы, как:

`Create`, `First`, `Find`, `Take`, `Save`, `UpdateXXX`, `Delete`, `Scan`, `Row`, `Rows`...

Вот пример немедленных методов, основанный на вышеупомянутой цепи:

```go
tx.Find(&user)
```

Генерирует

```sql
SELECT * FROM users where name = 'jinzhu' AND age = 30 AND active = 1;
```

## Области

Область строится на основе теории цепи метода.

С ним можно извлечь некоторые общие логики, чтобы написать более многоразовые библиотеки.

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
    return db.Scopes(AmountGreaterThan1000).Where("status IN (?)", status)
  }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Найти все заказы по кредитной карте и суммой более 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Найти все заказы с полатой по наложенному платежу и суммой более 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Найти все оплаченные и отправленные заказы с суммой более 1000
```

## Несколько немедленных методов

При использовании нескольких немедленных методов с GORM, поздний немедленный метод будет повторно использован перед условиями запроса немедленных методов (исключая условия внутреннего доступа)

```go
db.Where("name LIKE ?", "jinzhu%").Find(&users, "id IN (?)", []int{1, 2, 3}).Count(&count)
```

Генерирует

```sql
SELECT * FROM users WHERE name LIKE 'jinzhu%' AND id IN (1, 2, 3)

SELECT count(*) FROM users WHERE name LIKE 'jinzhu%'
```

## Безопасность

Все методы цепочки будут клонировать и создавать новый объект DB (делится одним пулом подключения), GORM безопасен для одновременного использования несколькими потоками.