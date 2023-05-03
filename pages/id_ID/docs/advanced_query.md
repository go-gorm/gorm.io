---
title: Kueri Lanjutan
layout: page
---

## <span id="smart_select">Bidang Pilih Pintar</span>

GORM mengijinkan pengambilan field secara spesifik dengan [`Select`](query.html), jika kamu sering menggunakan ini didalam aplikasi kamu, mungkin kamu hendak mendefinisikan struct yang lebih kecil untuk API yang mana dapat mengambil field secara otomatis, sebagai contoh:

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // ratusan bidang
}

type APIUser struct {
  ID   uint
  Name string
}

// Pilih bidang `id`, `name` secara otomatis saat proses kueri
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

{% note warn %}
**CATATAN** mode `QueryFields` akan memilih berdasarkan nama semua bidang untuk model saat ini
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  QueryFields: true,
})

db.Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... // Mode Sesi
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users`
```

## Penguncian (FOR UPDATE)

GORM mendukung berbagai jenis penguncian, misalnya:

```go
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`

db.Clauses(clause.Locking{
  Strength: "UPDATE",
  Options: "NOWAIT",
}).Find(&users)
// SELECT * FROM `users` FOR UPDATE NOWAIT
```

Rujuk ke [SQL mentahan dan pembuat SQL](sql_builder.html) untuk detail lebih lanjut

## Sub-Kueri

Sebuah sub-kueri dapat disarangkan dalam sebuah kueri, GORM dapat menghasilkan sub-kueri saat menggunakan objek `*gorm.DB` sebagai parameternya

```go
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">Dari Sub-Kueri</span>

GORM allows you using subquery in FROM clause with the method `Table`, for example:

```go
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Pengelompokan Kondisi</span>

Lebih mudah untuk menulis kueri SQL yang rumit dengan pengelompokan kondisi

```go
db.Where(
    db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## IN dengan Beberapa Kolom

Memilih IN dengan beberapa kolom

```go
db.Where("(name, age, role) IN ?", [][]interface{}{{"jinzhu", 18, "admin"}, {"jinzhu2", 19, "user"}}).Find(&users)
// SELECT * FROM users WHERE (name, age, role) IN (("jinzhu", 18, "admin"), ("jinzhu 2", 19, "user"));
```

## Argumen Bernama

GORM mendukung argumen bernama dengan [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) atau `map[string]interface{}{}`, misalnya:

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

Lihat ke [SQL mentahan dan pembuat SQL](sql_builder.html) untuk detail lebih lanjut

## Pencarian ke Map

GORM allows scanning results to `map[string]interface{}` or `[]map[string]interface{}`, don't forget to specify `Model` or `Table`, for example:

```go
result := map[string]interface{}{}
db.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
db.Table("users").Find(&results)
```

## FirstOrInit

Dapatkan catatan pertama yang cocok atau inisialisasi instance baru dengan kondisi yang diberikan (hanya berfungsi dengan kondisi struct atau map)

```go
// Pengguna tidak ditemukan, menginisiasi dengan kondisi yang diberikan
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"}

// Pengguna ditemukan dengan `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}

// Pengguna ditemukan dengan `name` = `jinzhu`
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

Initialize struct with more attributes if record not found, those `Attrs` won't be used to build the SQL query

```go
// Pengguna tidak ditemukan, menginisiasi dengan kondisi yang diberikan
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Pengguna tidak ditemukan, menginisiasi dengan kondisi yang diberikan
db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Pengguna ditemukan dengan `name` = `jinzhu`, atribut akan diabaikan
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

`Assign` atribut ke struct terlepas dari ditemukan atau tidak, atribut tersebut tidak akan digunakan untuk membuat kueri SQL dan data akhir tidak akan disimpan ke dalam database

```go
// Pengguna tidak ditemukan, menginisiasi dengan kondisi yang diberikan dan menambahkan atribut
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20}

// Pengguna ditemukan dengan `name` = `jinzhu`, memperbaruinya dengan atribut yang diberikan
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## FirstOrCreate

Get first matched record or create a new one with given conditions (only works with struct, map conditions), `RowsAffected` returns created/updated record's count

```go
// User not found, create a new record with give conditions
result := db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}
// result.RowsAffected // => 1

// Found user with `name` = `jinzhu`
result := db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age": 18}
// result.RowsAffected // => 0
```

Buat struct dengan lebih banyak atribut jika catatan tidak ditemukan, `Attrs` tersebut tidak akan digunakan untuk membuat kueri SQL

```go
// Pengguna tidak ditemukan, membuat catatan baru dengan kondisi dan atribut yang diberikan
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Pengguna ditemukan dengan `name` = `jinzhu`, atribut akan diabaikan
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

`Assign` atribut ke catatan, terlepas itu ditemukan atau tidak dan menyimpannya kembali ke database.

```go
// Pengguna tidak ditemukan, membuat catatan baru dengan kondisi dan atribut yang diberikan
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Pengguna ditemukan dengan `name` = `jinzhu`, perbarui dengan atribut yang diberikan
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "jinzhu", Age: 20}
```

## Optimizer/Indeks Hints

Optimizer hints memungkinkan untuk mengontrol pengoptimal kueri untuk memilih rencana eksekusi kueri tertentu, GORM mendukungnya dengan `gorm.io/hints`, misalnya:

```go
import "gorm.io/hints"

db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Indeks hints memungkinkan melewatkan petunjuk indeks ke database jika perencana kueri bingung.

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```

Rujuk ke [Optimizer Hints/Indeks/Komentar](hints.html) untuk detail lebih lanjut

## Pengulangan

GORM mendukung pengulangan melalui baris

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Rows()
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows merupakan metode dari `gorm.DB`, dapat digunakan untuk memindai suatu baris ke sebuah struct
  db.ScanRows(rows, &user)

  // lakukan sesuatu
}
```

## FindInBatches

Meng-kueri dan memproses dalam suatu batch

```go
// ukuran batch 100
result := db.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // pemroses batch menemukan catatan
  }

  tx.Save(&results)

  tx.RowsAffected // jumlah catatan di batch ini

  batch // Batch 1, 2, 3

  // mengembalikan eror dan memberhentikan batch berikutnya
  return nil
})

result.Error // mengembalikan eror
result.RowsAffected // catatan yang diproses dihitung di semua batch
```

## Hook Kueri

GORM memungkinkan hook `AfterFind` untuk kueri, itu akan dipanggil saat meminta catatan, lihat [Hooks](hooks.html) untuk detailnya

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.Role == "" {
    u.Role = "user"
  }
  return
}
```

## <span id="pluck">Pluck</span>

Kueri satu kolom dari database dan pindai menjadi irisan, jika Anda ingin membuat kueri beberapa kolom, gunakan `Select` dengan [`Scan`](query.html#scan) sebagai gantinya

```go
var ages []int64
db.Model(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Pluck berbeda
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Meminta lebih dari satu kolom, gunakan `Scan` atau `Find` seperti ini:
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```

## Scopes

`Scopes` memungkinkan Anda menentukan kueri yang umum digunakan yang dapat dirujuk sebagai pemanggilan metode

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
    return db.Where("status IN (?)", status)
  }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Cari semua kartu kredit dengan jumlah lebih dari 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Cari semua pesanan COD dengan jumlah lebih dari 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Cari semua pesanan dibayar dan dikirim dengan jumlah lebih dari 1000
```

Rujuk ke [Scopes](scopes.html) untuk detail lebih lanjut

## <span id="count">Count</span>

Dapatkan jumlah catatan yang sesuai

```go
var count int64
db.Model(&User{}).Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu'; (count)

db.Table("deleted_users").Count(&count)
// SELECT count(1) FROM deleted_users;

// Count with Distinct
db.Model(&User{}).Distinct("name").Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db.Table("deleted_users").Select("count(distinct(name))").Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Hitung dalam kelompok
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

db.Model(&User{}).Group("name").Count(&count)
count // => 3
```
