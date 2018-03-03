---
title: Declaring Models
layout: page
---
## Declaring Models

Models usually just normal Golang structs, basic Go types, pointer of them and [`sql.Scanner`](https://golang.org/pkg/database/sql/#Scanner), [`driver.Valuer`](https://golang.org/pkg/database/sql/driver/#Valuer) interfaces are supported.

Model Example:

```go
type User struct {
  gorm.Model
  Name         string
  Age          sql.NullInt64
  Birthday     *time.Time
  Email        string  `gorm:"type:varchar(100);unique_index"`
  Role         string  `gorm:"size:255"` // set field size to 255
  MemberNumber *string `gorm:"unique;not null"` // set member number to unique and not null
  Num          int     `gorm:"AUTO_INCREMENT"` // set num to auto incrementable
  Address      string  `gorm:"index:addr"` // create index with name `addr` for address
  IgnoreMe     int     `gorm:"-"` // ignore this field
}
```

## Struct tags

Tanda opsional untuk digunakan saat mendeklarasikan model, berikut adalah tanda yang didukung GORM.

### Supported Struct tags

| Label           | Keterangan                                                                     |
| --------------- | ------------------------------------------------------------------------------ |
| Kolom           | Menentukan nama kolom                                                          |
| Jenis           | Menentukan tipe data kolom                                                     |
| Ukuran          | Menentukan ukuran kolom, bawaan 255                                            |
| Kunci_Utama     | Menentukan kolom sebagai kunci utama                                           |
| UNIK            | Menentukan kolom sebagai unik                                                  |
| BAWAAN          | Menentukan nilai kolom bawaan                                                  |
| KESEKSAMAAN     | Menentukan keseksamaan kolom                                                   |
| NOT NULL        | Specifies column as NOT NULL                                                   |
| AUTO_INCREMENT  | Specifies column auto incrementable or not                                     |
| INDEX           | Buat indeks dengan atau tanpa nama, nama yang sama menciptakan indeks komposit |
| UNIQUE_INDEX    | Like `INDEX`, create unique index                                              |
| EMBEDDED        | Tetapkan struct sebagai tertanam                                               |
| EMBEDDED_PREFIX | Tetapkan nama awalan struct terstruktur                                        |
| -               | Abaikan bidang ini                                                             |

### Tag struktur untuk Asosiasi

Periksa bagian Asosiasi untuk rinciannya

| Label                              | Keterangan                                           |
| ---------------------------------- | ---------------------------------------------------- |
| MANY2MANY                          | Menentukan ikut nama tabel                           |
| FOREIGNKEY                         | Specifies foreign key                                |
| ASSOCIATION_FOREIGNKEY             | Menentukan asosiasi kunci asing                      |
| POLYMORPHIC                        | Specifies polymorphic type                           |
| POLYMORPHIC_VALUE                  | Menentukan nilai polimorfik                          |
| JOINTABLE_FOREIGNKEY               | Menentukan kunci asing yang bisa digabungkan         |
| ASSOCIATION_JOINTABLE_FOREIGNKEY | Tentukan asosiasi kunci asing yang dapat digabungkan |
| SAVE_ASSOCIATIONS                  | Penyimpanan otomatis asosiasi atau tidak             |
| ASSOCIATION_AUTOUPDATE             | PembaruanOtomatis asosiasi atau tidak                |
| ASSOCIATION_AUTOCREATE             | Buat asosiasi otomatis atau tidak                    |
| ASSOCIATION_SAVE_REFERENCE       | Penyimpanan otomatis asosiasi referensi atau tidak   |
| PRELOAD                            | Auto Preload associations or not                     |