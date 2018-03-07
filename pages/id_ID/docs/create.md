---
title: Membuat
layout: page
---
## Buat Catatan

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

db.NewRecord(user) // => returns `true` as primary key is blank

db.Create(&user)

db.NewRecord(user) // => return `false` after `user` created
```

## Nilai Bawaan

Anda dapat menetapkan nilai bidang bawaan dengan label, sebagai contoh:

```go
jenis hewan struct {
    ID int64
    Nama string `gorm:" default: 'galeone' "`
    Umur int64
}
```

Kemudian memasukkan SQL akan mengecualikan bidang tersebut yang tidak memiliki nilai atau memiliki [nilai nol](https://tour.golang.org/basics/12), setelah memasukkan record ke dalam database, gorm akan memuat nilai field tersebut dari database.

```go
var animal = Hewan {Umur: 99, Nama: ""}
db.Create (& amp; hewan)
// INSERT INTO nilai hewan ("usia") ('99 ');
// PILIH nama dari hewan WHERE ID = 111; // kunci utama yang kembali adalah 111
// heean.Nama = & gt; 'galeone'
```

** Perhatikan </ strong> semua bidang yang memiliki nilai nol, seperti `` 0 </ code>, <code> '' </ code>, <code> false </ code> atau lainnya <a href = "https: //tour.golang.org/basics/12 "> nilai nol ​​</a> tidak akan disimpan ke dalam database namun akan menggunakan nilai defaultnya, Anda ingin menghindari hal ini, pertimbangkan untuk menggunakan tipe pointer atau pemindai / penilai, misal:</p>

<pre><code class="go">// Gunakan nilai pointer ketik User struct {   gorm.Model   Nama string   Umur * int `gorm:" default: 18 "` }

 // Gunakan pemindai / penilai ketik User struct {   gorm.Model   Nama string   Umur sql.NullInt64 `gorm:" default: 18 "` }
``</pre> 

## Menetapkan Nilai Bidang Dalam Hooks

Jika Anda ingin memperbarui nilai bidang di hook `BeforeCreate`, Anda bisa menggunakan `scope.SetColumn`, misalnya:

```go
func (user *User) BeforeCreate(scope *gorm.Scope) error {
  scope.SetColumn("ID", uuid.New())
  return nil
}
```

## Pilihan Membuat Tambahan

```go
// Add extra SQL option for inserting SQL
db.Set("gorm:insert_option", "ON CONFLICT").Create(&product)
// INSERT INTO products (name, code) VALUES ("name", "code") ON CONFLICT;
```