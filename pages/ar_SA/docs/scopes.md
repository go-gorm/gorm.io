---
title: Scopes
layout: page
---

Scopes allow you to easily re-use commonly logic

## Query

```go
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
  return db. Where("amount > ?", 1000)
}

func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
  return db. Where("pay_mode = ?", "card")
}

func PaidWithCod(db *gorm.DB) *gorm.DB {
  return db. Where("pay_mode = ?", "cod")
}

func OrderStatus(status []string) func (db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    return db. Scopes(AmountGreaterThan1000). Where("status IN (?)", status)
  }
}

db. Scopes(AmountGreaterThan1000, PaidWithCreditCard). Find(&orders)
// Find all credit card orders and amount greater than 1000

db. Scopes(AmountGreaterThan1000, PaidWithCod). Find(&orders)
// Find all COD orders and amount greater than 1000

db. Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})). Find(&orders)
// Find all paid, shipped orders that amount greater than 1000
```

## Pagination

```go
func CurOrganization(r *http. Request) func(db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    org := r.
```

## Updates

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
