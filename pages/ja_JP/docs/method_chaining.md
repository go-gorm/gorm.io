---
title: メソッドチェーン
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

は

```sql
SELECT * FROM users where name = 'jinzhu' AND age = 30 AND active = 1;

を生成します
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
        return db.Scopes(AmountGreaterThan1000).Where("status IN (?)", status)
    }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Find all credit card orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Find all COD orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Find all paid, shipped orders that amount greater than 1000
```

## 複数の即時メソッド

GORMで複数の即時メソッドを扱う場合、後方の即時メソッドは前方の即時メソッドのクエリ条件を再利用します(インライン条件は除きます)

```go
db.Where("name LIKE ?", "jinzhu%").Find(&users, "id IN (?)", []int{1, 2, 3}).Count(&count)
```

生成

```sql
SELECT * FROM users WHERE name LIKE 'jinzhu%' AND id IN (1, 2, 3)

SELECT count(*) FROM users WHERE name LIKE 'jinzhu%'
```

## スレッドセーフ

全てのチェーンメソッドは複製され新規DBオブジェクトを作成します(1つのコネクションプールを共有します)。GORMは複数のgoroutineでの並行利用に対して安全です。