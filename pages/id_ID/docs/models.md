---
title: Mendeklarasikan Model
layout: page
---

## Declaring Models

Models are usually just normal Golang structs, basic Go types, or pointers of them. [`sql.Scanner`](https://golang.org/pkg/database/sql/#Scanner) and [`driver.Valuer`](https://golang.org/pkg/database/sql/driver/#Valuer) interfaces are also supported.

Contoh Model:

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

## Label Strukur

Tags are optional to use when declaring models. GORM supports the following tags:

### Label Struktur yang didukung

| Label           | Keterangan                                                                     |
| --------------- | ------------------------------------------------------------------------------ |
| Column          | Menentukan nama kolom                                                          |
| Type            | Menentukan tipe data kolom                                                     |
| Size            | Menentukan ukuran kolom, bawaan 255                                            |
| PRIMARY_KEY     | Menentukan kolom sebagai kunci utama                                           |
| UNIQUE          | Menentukan kolom sebagai unik                                                  |
| BAWAAN          | Menentukan nilai kolom bawaan                                                  |
| PRECISION       | Menentukan keseksamaan kolom                                                   |
| NOT NULL        | Menentukan kolom sebagai TIDAK BATAL                                           |
| AUTO_INCREMENT  | Tentukan kolom yang bisa kenaikan otomatis atau tidak                          |
| INDEX           | Buat indeks dengan atau tanpa nama, nama yang sama menciptakan indeks komposit |
| UNIQUE_INDEX    | Seperti `INDEKS`, membuat indeks unik                                          |
| EMBEDDED        | Tetapkan struct sebagai tertanam                                               |
| EMBEDDED_PREFIX | Tetapkan nama awalan struct terstruktur                                        |
| -               | Abaikan bidang ini                                                             |

### Tag struktur untuk Asosiasi

Check out the Associations section for details

| Label                              | Keterangan                                           |
| ---------------------------------- | ---------------------------------------------------- |
| MANY2MANY                          | Menentukan ikut nama tabel                           |
| FOREIGNKEY                         | Menentukan kunci asing                               |
| ASSOCIATION_FOREIGNKEY             | Menentukan asosiasi kunci asing                      |
| POLYMORPHIC                        | Menentukan jenis polimorfik                          |
| POLYMORPHIC_VALUE                  | Menentukan nilai polimorfik                          |
| JOINTABLE_FOREIGNKEY               | Menentukan kunci asing yang bisa digabungkan         |
| ASSOCIATION_JOINTABLE_FOREIGNKEY | Tentukan asosiasi kunci asing yang dapat digabungkan |
| SAVE_ASSOCIATIONS                  | Penyimpanan otomatis asosiasi atau tidak             |
| ASSOCIATION_AUTOUPDATE             | PembaruanOtomatis asosiasi atau tidak                |
| ASSOCIATION_AUTOCREATE             | Buat asosiasi otomatis atau tidak                    |
| ASSOCIATION_AUTOCREATE             | Penyimpanan otomatis asosiasi referensi atau tidak   |
| PRELOAD                            | Auto Preload associations or not                     |