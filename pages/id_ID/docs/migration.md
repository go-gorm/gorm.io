---
title: Migration
layout: halaman
---
## Auto Migration

Secara otomatis skema Anda berpindah tempat, untuk memperbarui skema Anda sampai saat ini.

**WARNING:** AutoMigrate will **ONLY** create tables, missing columns and missing indexes, and **WON'T** change existing column's type or delete unused columns to protect your data.

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// Add table suffix when create tables
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})
```

## Other Migration Tools

Migrasi Otomatis GORM bekerja dengan baik untuk sebagian besar kasus, tetapi jika Anda mencari alat migrasi yang lebih serius, GORM menyediakan antarmuka genric DB yang mungkin bisa membantu Anda.

```go
// returns `*sql.DB`
db.DB()
```

Refer [Generic Interface](/docs/generic_interface.html) for more details.

## Schema Methods

### Has Table

```go
// Check model `User`'s table exists or not
db.HasTable(&User{})

// Check table `users` exists or not
db.HasTable("users")
```

### Create Table

```go
// Create table for model `User`
db.CreateTable(&User{})

// will append "ENGINE=InnoDB" to the SQL statement when creating table `users`
db.Set("gorm:table_options", "ENGINE=InnoDB").CreateTable(&User{})
```

### Drop table

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
// Drop column description from model `User`
db.Model(&User{}).DropColumn("description")
```

### Add Indexes

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

### Remove Index

```go
// Remove index
db.Model(&User{}).RemoveIndex("idx_user_name")
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