---
title: Metode Rantai
layout: page
---

## Method Chaining

Gorm menerapkan metode antarmuka rantai, jadi anda bisa menulis kode seperti ini:

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

Permintaan tidak akan dihasilkan sampai metode langsung, yang bisa berguna dalam beberapa kasus.

Seperti Anda bisa mengekstrak pembungkusnya untuk menangani beberapa logika umum

## Metode Langsung

Metode segera adalah metode tersebut yang akan menghasilkan query SQL dan mengirimkannya ke database, Biasanya metode CRUD tersebut, seperti:

`Create`, `First`, `Find`, `Take`, `Save`, `UpdateXXX`, `Delete`, `Scan`, `Row`, `Rows`...

Berikut adalah contoh metode langsung berdasarkan rantai di atas:

```go
tx.Find(&user)
```

Menghasilkan

```sql
PILIH * DARI pengguna yang bernama = 'jinzhu' DAN umur = 30 DAN aktif = 1;
```

## Cakupan

Ruang lingkup dibangun berdasarkan metode rantai teori.

Dengan itu, Anda bisa mengekstrak beberapa logika generik, untuk menulis lebih banyak perpustakaan dapat digunakan kembali.

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

## Metode Langsung Ganda

Bila menggunakan beberapa metode langsung dengan GORM, kemudian segera metode akan digunakan kembali sebelum kondisi kueri metode langsung (tidak termasuk dalam kondisi dalamgaris)

```go
db.Where("name LIKE ?", "jinzhu%").Find(&users, "id IN (?)", []int{1, 2, 3}).Count(&count)
```

Generates

```sql
SELECT * FROM users WHERE name LIKE 'jinzhu%' AND id IN (1, 2, 3)

SELECT count(*) FROM users WHERE name LIKE 'jinzhu%'
```

## Thread Safety

Semua Metode Rantai akan mengkloning dan membuat objek DB baru (berbagi satu kolam koneksi), GORM aman untuk digunakan bersamaan oleh beberapa goroutines.