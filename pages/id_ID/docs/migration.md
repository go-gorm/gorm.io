---
title: Migrasi
layout: page
---
## Migrasi Otomatis

Secara otomatis skema Anda berpindah tempat, untuk memperbarui skema Anda sampai saat ini.

**PERINGATAN:** AutoMigrate akan **HANYA** membuat tabel, kolom yang hilang dan indeks yang hilang, dan **TIDAK AKAN** mengubah jenis kolom yang sudah ada atau menghapus kolom yang tidak dipakai untuk melindungi data anda.

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// Add table suffix when create tables
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## Peralatan Migari Lainnya

GORM's AutoMigrate works well for most cases, but if you are looking for more serious migration tools, GORM provides generic DB interface which might be helpful for you.

```go
// kembali `*sql.DB`
db.DB()
```

Lihat [ Antarmuka Generik](/docs/generic_interface.html) untuk rincian lebih lanjut.

## Metode Skema

### Memiliki Tabel

```go
// Periksa model tabel `Pengguna`ada atau tidak
db.HasTable(&Pengguna{})
```

### Membuat Tabel

```go
// Create table for model `User`
db.CreateTable(&User{})

// will append "ENGINE=InnoDB" to the SQL statement when creating table `users`
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})
```

### Penurunan tabel

```go
// Drop model `User`'s table
db.DropTable(&User{})

// Drop table `users`
db.DropTable("users")

// Drop model's `User`'s table and table `products`
db.DropTableIfExists(&User{}, "products")
```

### ModifikasiKolom

Ubah jenis kolom untuk diberi nilai

```go
// ubah tipe data deskripsi kolom ke `text` untuk model` User`
db.Model (&Pengguna{}).ModifikasiKolom("deskripsi", "teks")
```

### DropColumn

```go
// Deskripsi penurunan kolom dari model `Pengguna`
db.Model(&Pengguna{}).DropColumn("deskripsi")
```

### Tambahkan Indeks

```go
// Add index for columns `name` with given name `idx_user_name`
db.Model(&User{}).AddIndex("idx_user_name", "name")

// Add index for columns `name`, `age` with given name `idx_user_name_age`
db.Model(&User{}).AddIndex("idx_user_name_age", "name", "age")

// Add unique index
db.Model(&User{}).AddUniqueIndex("idx_user_name", "name")

// Add unique index for multiple columns
db.Model(&User{}).AddUniqueIndex("idx_user_name_age", "name", "age")
```

### Hapus Indeks

```go
// Remove index
db.Model(&User{}).RemoveIndex("idx_user_name")
```

### Tambahkan Kunci Asing

```go
// Add foreign key
// 1st param : foreignkey field
// 2nd param : destination table(id)
// 3rd param : ONDELETE
// 4th param : ONUPDATE
db.Model(&User{}).AddForeignKey("city_id", "cities(id)", "RESTRICT", "RESTRICT")
```

### Hapus Kunci Asing

```go
db.Model(&User{}).RemoveForeignKey("city_id", "cities(id)")
```