---
title: Method Chaining
layout: page
---
## メソッドチェーン

Gormはメソッドチェーンのインタフェースを実装しているため、このようなコードを書くことができます:

```go
db, err := gorm.Open("postgres", "user=gorm dbname=gorm sslmode=disable")

// 新規リレーションを作成します
tx := db.Where("name = ?", "jinzhu")

// さらにフィルタを追加します
if someCondition {
    tx = tx.Where("age = ?", 20)
} else {
    tx = tx.Where("age = ?", 30)
}

if yetAnotherCondition {
    tx = tx.Where("active = ?", 1)
}
```

クエリは即時メソッドまで生成されず、それはいくつかの場面で有効です。

共通ロジックを扱うためのラッパーへ抽出するといったような場面で。

## 即時メソッド

即時メソッドはSQLクエリを生成してデータベースに送信するメソッドのことです。たいていはCRUDメソッドのことであり、

`Create`, `First`, `Find`, `Take`, `Save`, `UpdateXXX`, `Delete`, `Scan`, `Row`, `Rows`... 等を指します。

上記チェーンに基づく即時メソッドの例を示します:

```go
tx.Find(&user)
```

Generates

```sql
SELECT * FROM users where name = 'jinzhu' AND age = 30 AND active = 1;
```

## スコープ

スコープはメソッドチェーンの理論に基づいて構築されます。

これにより、汎用ロジックへの抽出が可能になり、より再利用しやすいライブラリを記述することができます。

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
// クレジットカードの注文かつ1000件以上の注文を取得します

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// CODによる注文かつ1000件以上の注文を取得します

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// 支払い済みで発送済みの注文かつ1000件以上の注文を取得します
```

## 複数の即時メソッド

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