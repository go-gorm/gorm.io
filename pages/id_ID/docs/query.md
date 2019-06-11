---
title: Pertanyaan
layout: page
---

## Pertanyaan

```go
// Dapatkan rekaman pertama, pesan menurut kunci utama db.Pertama(&pengguna)
//// PILIH * DARI pengguna MEMESAN Oleh BATAS id 1;

// Dapatkan satu rekaman, tidak ada perintah ditentukan db.Mengambil(&pengguna) 
//// PILIH *DARI BATAS pengguna LIMIT 1;

// Dapatkan rekaman terakhir, pesan menurut kunci utama 
db.Terakhir (& pengguna)
//// PILIH * DARI pesanan pengguna OLEH Batas id DESC 1;

// Dapatkan semua rekaman
db. Temukan (&pengguna)
//// PILIH * DARI pengguna;

// Dapatkan rekaman dengan kunci utama (hanya bekerja untuk kunci utama bilangan bulat) 
db.Pertama(&Pengguna, 10)
//// PILIH * DARI DIMANA id pengguna= 10;
```

### Dimana

#### SQL biasa

```go
// Dapatkan rekaman pertama yang cocok
db. Dimana ("nama =?", "Jinzhu").Pertama (&pengguna)
//// PILIH * DARI DI MANA nama pengguna= 'jinzhu' batas 1;

// Dapatkan semua rekaman yang cocok
db.Dimana ("nama =?", "Jinzhu").Temukan (& pengguna)
//// PILIH * DARI DI MANA nama pengguna = 'jinzhu';

// <>
db.Dimana ("nama <>?", "Jinzhu").Temukan (&pengguna)

// DI
db. Dimana ("nama dalam (?)", []tali{"jinzhu", "jinzhu 2"}).Temukan(&pengguna)

// SEPERTI
db. Dimana ("nama SEPERTI?", "%jin%").Temukan(&pengguna)

// DAN
db.Di mana("nama = ? DAN usia >=? "," Jinzhu "," 22 ").Temukan(&pengguna)

// Waktu
db.Dimana("diperbarui_at > ? ", minggulalu).Temukan (&pengguna)

// ANTARA
db.Dimana("dibuat _di ANTARA? DAN ?", Minggulalu, hari ini).Temukan(&pengguna)
```

#### Struktur & Peta

```go
// Struktur
db.Dimana(&Pengguna{Nama: "jinzhu", Umur: 20}).Pertama(&pengguna)
//// PILIH * DARI DIMANA nama pengguna = "jinzhu" DAN umur = 20 batas 1;

// Peta
db.Di mana(peta[string]antarmuka{}{"nama": "jinzhu", "umur": 20}).Temukan(&pengguna)
//// PILIH * DARI DIMANA nama pengguna = "jinzhu" DAN usia = 20;

// Irisan kunci utama
db.Dimana ([]int64{20, 21, 22}).Temukan(&pengguna)
//// PILIH * DARI Di mana id pengguna DI (20, 21, 22);
```

**Perhatikan**Ketika query dengan struct, GORM hanya akan query dengan bidang tersebut memiliki nilai non-nol, Itu berarti jika nilai bidang anda adalah `0`, `''`,`Salah`atau lainnya[nilai nol](https://tour.golang.org/basics/12),itu tidak akan digunakan untuk membangun kondisi query, sebagai contoh:

```go
db.Di mana (&pengguna{Nama: "jinzhu", Umur: 0}).Temukan (& pengguna)
//// PILIH * DARI DI MANA nama pengguna = "jinzhu";
```

Anda bisa mempertimbangkan untuk menggunakan jenis pointer atau pemindai / penilai untuk menghindari hal ini.

```go
// Gunakan nilai petunjuk
ketik Pengguna
struct {
   gorm. Model
   Nama string
   Umur * int
}

// Gunakan pemindai/penilai
ketik struct pengguna{
   gorm.Model
   Nama string
   Umur sql.NullInt64
}
```

### Tidak

Bekerja mirip seperti `Di mana`

```go
db.Tidak("nama", "jinzhu").Pertama(&pengguna)
//// PILIH * DARI DI MANA nama pengguna <> "jinzhu" BATAS 1;

// Tidak masuk
db.Not ("nama", []string {"jinzhu", "jinzhu 2"}).Temukan(&pengguna)
//// PILIH * DARI DI MANA nama pengguna tidak masuk ("jinzhu", "jinzhu 2");

// Tidak dalam irisan kunci utama
db.Tidak ([]int64 {1,2,3})Pertama(&pengguna)
//// PILIH * DARI DI MANA id pengguna TIDAK DI (1,2,3);

db.Tidak([]int64{}).Pertama(&pengguna)
//// PILIH * DARI pengguna;

// SQL Sederhana
db.Tidak("nama = ?", "jinzhu").pertama(&pengguna)
//// PILIH * DARI DI MANA pengguna tidak (nama = "jinzhu");

// Struct
db.tidak(pengguna{Nama: "jinzhu"}).Pertama(&pengguna)
//// PILIH * DARI DI MANA nama pengguna <> "jinzhu";
```

### Atau

```go
db.Where("role = ?", "admin").Or("role = ?", "super_admin").Find(&users)
//// SELECT * FROM users WHERE role = 'admin' OR role = 'super_admin';

// Struct
db.Where("name = 'jinzhu'").Or(User{Name: "jinzhu 2"}).Find(&users)
//// SELECT * FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2';

// Map
db.Where("name = 'jinzhu'").Or(map[string]interface{}{"name": "jinzhu 2"}).Find(&users)
//// SELECT * FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2';
```

### Kondisi di barisan

Bekerja mirip seperti`Dimana`.

When using with [Multiple Immediate Methods](/docs/method_chaining.html#Multiple-Immediate-Methods), won't pass those conditions to later immediate methods.

```go
// Get by primary key (only works for integer primary key)
db.First(&user, 23)
//// SELECT * FROM users WHERE id = 23 LIMIT 1;
// Get by primary key if it were a non-integer type
db.First(&user, "id = ?", "string_primary_key")
//// SELECT * FROM users WHERE id = 'string_primary_key' LIMIT 1;

// Plain SQL
db.Find(&user, "name = ?", "jinzhu")
//// SELECT * FROM users WHERE name = "jinzhu";

db.Find(&users, "name <> ? AND age > ?", "jinzhu", 20)
//// SELECT * FROM users WHERE name <> "jinzhu" AND age > 20;

// Struct
db.Find(&users, User{Age: 20})
//// SELECT * FROM users WHERE age = 20;

// Map
db.Find(&users, map[string]interface{}{"age": 20})
//// SELECT * FROM users WHERE age = 20;
```

### Pilihan Pertanyaan Tambahan

```go
// Add extra SQL option for selecting SQL
db.Set("gorm:query_option", "FOR UPDATE").First(&user, 10)
//// SELECT * FROM users WHERE id = 10 FOR UPDATE;
```

## FirstOrInit

Dapatkan catatan pertama yang cocok, atau inisialisasi yang baru dengan kondisi tertentu (hanya bekerja dengan struktur, kondisi peta)

```go
// Unfound
db.FirstOrInit(&user, User{Name: "non_existing"})
//// user -> User{Name: "non_existing"}

// Found
db.Where(User{Name: "Jinzhu"}).FirstOrInit(&user)
//// user -> User{Id: 111, Name: "Jinzhu", Age: 20}
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
//// user -> User{Id: 111, Name: "Jinzhu", Age: 20}
```

### Attrs

Inisialisasi struktur dengan argumen jika catatan tidak ditemukan

```go
// Unfound
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
//// SELECT * FROM USERS WHERE name = 'non_existing';
//// user -> User{Name: "non_existing", Age: 20}

db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
//// SELECT * FROM USERS WHERE name = 'non_existing';
//// user -> User{Name: "non_existing", Age: 20}

// Found
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 30}).FirstOrInit(&user)
//// SELECT * FROM USERS WHERE name = jinzhu';
//// user -> User{Id: 111, Name: "Jinzhu", Age: 20}
```

### Menetapkan

Menetapkan argumen untuk struktur tanpa peduli itu ditemukan atau tidak

```go
// Unfound
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
//// user -> User{Name: "non_existing", Age: 20}

// Found
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 30}).FirstOrInit(&user)
//// SELECT * FROM USERS WHERE name = jinzhu';
//// user -> User{Id: 111, Name: "Jinzhu", Age: 30}
```

## FirstOrCreate

Dapatkan catatan pertama yang cocok, atau membuat yang baru dengan kondisi tertentu (hanya bekerja dengan struktur, kondisi peta)

```go
// Unfound
db.FirstOrCreate(&user, User{Name: "non_existing"})
//// INSERT INTO "users" (name) VALUES ("non_existing");
//// user -> User{Id: 112, Name: "non_existing"}

// Found
db.Where(User{Name: "Jinzhu"}).FirstOrCreate(&user)
//// user -> User{Id: 111, Name: "Jinzhu"}
```

### Attrs

Menetapkan struktur dengan argumen jika catatan tidak ditemukan dan buat dengan nilai-nilai tersebut

```go
// Unfound
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
//// SELECT * FROM users WHERE name = 'non_existing';
//// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
//// user -> User{Id: 112, Name: "non_existing", Age: 20}

// Found
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 30}).FirstOrCreate(&user)
//// SELECT * FROM users WHERE name = 'jinzhu';
//// user -> User{Id: 111, Name: "jinzhu", Age: 20}
```

### Assign

Menetapkannya untuk mencatat tanpa peduli itu ditemukan atau tidak, dan simpan kembali ke basisdata.

```go
// Unfound
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
//// SELECT * FROM users WHERE name = 'non_existing';
//// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
//// user -> User{Id: 112, Name: "non_existing", Age: 20}

// Found
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 30}).FirstOrCreate(&user)
//// SELECT * FROM users WHERE name = 'jinzhu';
//// UPDATE users SET age=30 WHERE id = 111;
//// user -> User{Id: 111, Name: "jinzhu", Age: 30}
```

## Pertanyaan Lanjutan

### SubQuery

SubQuery with `*gorm.expr`

```go
db.Where("amount > ?", DB.Table("orders").Select("AVG(amount)").Where("state = ?", "paid").QueryExpr()).Find(&orders)
// SELECT * FROM "orders"  WHERE "orders"."deleted_at" IS NULL AND (amount > (SELECT AVG(amount) FROM "orders"  WHERE (state = 'paid')));
```

### Pilih

Tentukan bidang yang ingin anda ambil kembali dari basisdata, secara default, akan memilih semua bidang

```go
db.Select("name, age").Find(&users)
//// SELECT name, age FROM users;

db.Select([]string{"name", "age"}).Find(&users)
//// SELECT name, age FROM users;

db.Table("users").Select("COALESCE(age,?)", 42).Rows()
//// SELECT COALESCE(age,'42') FROM users;
```

### Urutan

Tentukan urutan ketika mengambil catatan dari basisdata, menetapkan urutan ulang (argumen kedua) ke `benar` untuk menimpa kondisi yang didefinisikan

```go
db.Order("age desc, name").Find(&users)
//// SELECT * FROM users ORDER BY age desc, name;

// Multiple orders
db.Order("age desc").Order("name").Find(&users)
//// SELECT * FROM users ORDER BY age desc, name;

// ReOrder
db.Order("age desc").Find(&users1).Order("age", true).Find(&users2)
//// SELECT * FROM users ORDER BY age desc; (users1)
//// SELECT * FROM users ORDER BY age; (users2)
```

### Batas

Tentukan jumlah maksimum dari catatan untuk mengambil kembali

```go
db.Limit(3).Find(&users)
//// SELECT * FROM users LIMIT 3;

// Cancel limit condition with -1
db.Limit(10).Find(&users1).Limit(-1).Find(&users2)
//// SELECT * FROM users LIMIT 10; (users1)
//// SELECT * FROM users; (users2)
```

### Offset

Tentukan jumlah dari catatan untuk melewati sebelum memulai untuk mengembalikan catatan

```go
db.Offset(3).Find(&users)
//// SELECT * FROM users OFFSET 3;

// Cancel offset condition with -1
db.Offset(10).Find(&users1).Offset(-1).Find(&users2)
//// SELECT * FROM users OFFSET 10; (users1)
//// SELECT * FROM users; (users2)
```

### Hitungan

Dapatkan seberapa banyak catatan untuk sebuah model

```go
db.Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Find(&users).Count(&count)
//// SELECT * from USERS WHERE name = 'jinzhu' OR name = 'jinzhu 2'; (users)
//// SELECT count(*) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'; (count)

db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
//// SELECT count(*) FROM users WHERE name = 'jinzhu'; (count)

db.Table("deleted_users").Count(&count)
//// SELECT count(*) FROM deleted_users;
```

**CATATAN** Ketika menggunakan `Hitungan` dalam rantai pertanyaan, itu harus menjadi yang terakhir, karena akan menimpa `PILIH` kolom

### Kelompok & Memiliki

```go
rows, err := db.Table("orders").Select("date(created_at) as date, sum(amount) as total").Group("date(created_at)").Rows()
for rows.Next() {
    ...
}

rows, err := db.Table("orders").Select("date(created_at) as date, sum(amount) as total").Group("date(created_at)").Having("sum(amount) > ?", 100).Rows()
for rows.Next() {
    ...
}

type Result struct {
    Date  time.Time
    Total int64
}
db.Table("orders").Select("date(created_at) as date, sum(amount) as total").Group("date(created_at)").Having("sum(amount) > ?", 100).Scan(&results)
```

### Gabung

Specify Joins conditions

```go
rows, err := db.Table("users").Select("users.name, emails.email").Joins("left join emails on emails.user_id = users.id").Rows()
for rows.Next() {
    ...
}

db.Table("users").Select("users.name, emails.email").Joins("left join emails on emails.user_id = users.id").Scan(&results)

// multiple joins with parameter
db.Joins("JOIN emails ON emails.user_id = users.id AND emails.email = ?", "jinzhu@example.org").Joins("JOIN credit_cards ON credit_cards.user_id = users.id").Where("credit_cards.number = ?", "411111111111").Find(&user)
```

## Pluck

Permintaan kolom tunggal dari sebuah model sebagai peta, jika anda ingin permintaan kolom ganda, anda harus menggunakan [`Pindai`](#Scan) sebagai gantinya

```go
var ages []int64
db.Find(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Requesting more than one column? Do it like this:
db.Select("name, age").Find(&users)
```

## Pindai

Pindai hasil ke dalam struktur lain.

```go
type Result struct {
    Name string
    Age  int
}

var result Result
db.Table("users").Select("name, age").Where("name = ?", 3).Scan(&result)

// Raw SQL
db.Raw("SELECT name, age FROM users WHERE name = ?", 3).Scan(&result)
```
