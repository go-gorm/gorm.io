---
title: Migrasi
layout: halaman
---
## Migrasi Otomatis

Secara otomatis skema Anda berpindah tempat, untuk memperbarui skema Anda sampai saat ini.

**PERINGATAN:** AutoMigrate akan **HANYA** membuat tabel, kolom yang hilang dan indeks yang hilang, dan **TIDAK AKAN** mengubah jenis kolom yang sudah ada atau menghapus kolom yang tidak dipakai untuk melindungi data anda.

```go
db.AutoMigrate(&Pengguna{})

db.AutoMigrate(&Pengguna{}, &Produk{}, &Pesanan{})

// Tambahkan tabel akhiran ketika membuat tabel
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&Pengguna{})
```

## Peralatan Migari Lainnya

Migrasi Otomatis GORM bekerja dengan baik untuk sebagian besar kasus, tetapi jika Anda mencari alat migrasi yang lebih serius, GORM menyediakan antarmuka genric DB yang mungkin bisa membantu Anda.

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
// Membuat tabel untuk model `Pengguna`
db.CreateTable(&Pengguna{})

// akan menambahkan "ENGINE=InnoDB" ke pernyataan SQL ketika membuat tabel `pengguna`
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&Pengguna{})
```

### Penurunan tabel

```go
// Penurunan model tabel `Pengguna`
db.DropTable(&Pengguna{})

// Penurunan `Pengguna`
db.DropTable("pengguna")

// Penurunan model tabel `Pengguna` dan tabel `produk`
db.DropTableIfExists(&Pengguna{}, "produk")
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
// Tambahkan indeks untuk `nama` kolom dengan nama yang diberikan`idx_user_name`
db.Model(&Pengguna{}).AddIndex("idx_user_name", "nama")

// Tambahkan indeks untuk `nama`, `umur` kolom dengan nama yang diberikan `idx_user_name_age`
db.Model(&Pengguna{}).AddIndex("idx_user_name_age", "nama", "umur")

// Tambahkan indeks unik
db.Model(&Pengguna{}).AddUniqueIndex("idx_user_name", "nama")

// Tambahkan indeks unik untuk kolom banyak
db.Model(&Pengguna{}).AddUniqueIndex("idx_user_name_age", "nama", "umur")
```

### Hapus Indeks

```go
// Hapus indeks
db.Model(&Pengguna{}).RemoveIndex("idx_user_name")
```

### Add Foreign Key

```go
// Add foreign key
// 1st param : foreignkey field
// 2nd param : destination table(id)
// 3rd param : ONDELETE
// 4th param : ONUPDATE
db.Model(&User{}).AddForeignKey("city_id", "cities(id)", "RESTRICT", "RESTRICT")
```

### Remove ForeignKey

```go
db.Model(&User{}).RemoveForeignKey("city_id", "cities(id)")
```