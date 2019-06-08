---
title: Ubah log
layout: halaman
---

## v2.0

WIP

## v1.0 - 2016.04.27

Melanggar perubahan

* `gorm.Open` return type `*gorm.DB` instead of `gorm.DB`

* Membarui hanya akan memperbarui bidang yang berubah

* Hapus lembut hanya akan memeriksa ` deleted_at IS NULL ` adalah batal

* Logika untukDBNama baru
    
    When GORM convert struct, field name to db name, only common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` were handled, so `HTTP`'s db name is `http`, but not `h_t_t_p`.
    
    But for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it.

* Kesalahan `RecordNotFound` telah diubah namanya menjadi `ErrRecordNotFound`

* `mssql` dialect has been renamed to "github.com/jinzhu/gorm/dialects/mssql"

* `Hstore` telah dipindahkan ke paket "github.com/jinzhu/gorm/dialects/postgres"
