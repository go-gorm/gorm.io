---
title: Области
layout: страница
---

Область применения позволяет легко повторно использовать логику

## Запрос

```go
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
  return db.Where("amount > ?", 1000)
}

func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode = ?", "card")
}

func PaidWithCod(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode = ?", "cod")
}

func OrderStatus(status []string) func (db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    return db.Scopes(AmountGreaterThan1000).Where("status IN (?)", status)
  }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Найти все заказы по кредитной карте с суммой более 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Найти все заказы с наложенным платежом и суммой более 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Найти все оплаченные и отгруженные заказы с суммой более 1000
```

## Нумерация страниц

```go
func Paginate(r *http.Request) func(db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    page, _ := strconv.Atoi(r.Query("page"))
    if page == 0 {
      page = 1
    }

    pageSize, _ := strconv.Atoi(r.Query("page_size"))
    switch {
    case pageSize > 100:
      pageSize = 100
    case pageSize <= 0:
      pageSize = 10
    }

    offset := (page - 1) * perPasge
    return db.Offset(offset).Limit(pageSize)
  }
}

db.Scopes(Paginate(r)).Find(&users)
db.Scopes(Paginate(r)).Find(&articles)
```

## Обновления

```go
func CurOrganization(r *http.Request) func(db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    org := r.Query("org")

    if org != "" {
      var organization Organization
      if db.Session(&Session{}).First(&organization, "name = ?", org).Error == nil {
        return db.Where("organization_id = ?", org.ID)
      }
    }

    db.AddError("invalid organization")
    return db
  }
}

db.Scopes(CurOrganization(r)).Save(&articles)
```
