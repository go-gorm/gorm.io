---
title: Delete
layout: page
---

## Delete a Record

Saat menghapus  data, nilai yang di hapus perlu memiliki kunci utama atau itu akan memicu  [Batch Delete](#batch_delete), sebagai contoh

```go
// Email's ID is `10`
db.Delete(&email)
// DELETE from emails where id = 10;

// Delete with additional conditions
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE from emails where id = 10 AND name = "jinzhu";
```

## Delete with primary key

GORM mengijinkan untuk menghapus objek menggunakan primary key dengan kondisi di inline, ini akan bekerja dengan angka, check keluaran  [  Ketentuan query inline](query.html#inline_conditions) untuk detail .

```go
db.Delete(&User{}, 10)
// DELETE FROM users WHERE id = 10;

db.Delete(&User{}, "10")
// DELETE FROM users WHERE id = 10;

db.Delete(&users, []int{1,2,3})
// DELETE FROM users WHERE id IN (1,2,3);
```

## Delete Hooks

GORM mengijinkan pengambilan ` beforedelete`, `Afterdelete`,  metode itu akan di panggil saat menghapus record, lihat [Hooks](hooks.html) untuk detail.

```go
func (u *User) BeforeDelete(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to delete")
    }
    return
}
```

## <span id="batch_delete">Batch Delete</span>

NIlai yang di tentukan tidak memiliki nilai primary, GORM akan penghapusan batch,  itu akan menghapus semua catatan yang sesuai.

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### Block Global Delete

Jika kamu melakukan penghapusan batch tanpa tanpa kondisi(syarat apapun ), GORM tidak akan menjalankannya, dan akan mengembalikan  kesalahan ` ErrMissingWhereClause<0>error</p>

<p spaces-before="0">You have to use some conditions or use raw SQL or enable <code>AllowGlobalUpdate` mode, for example:

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE FROM `users` WHERE 1=1

db.Exec("DELETE FROM users")
// DELETE FROM users

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// DELETE FROM users
```

## Soft Delete

Jika di dalam model anda menyertakan file`gorm.DeleteAt`  bidang termasuk dalam `gorm.Model`, itu dapat menghapus ability secara otomatis

Saat memanggil`Code` ,  data tidak akan di hapus dari database , tapi, GORM akan mengatur `DeletedAt`  nilai dari saat ini  dan data tidak akan di temukan lagi jika ita menggunakan metode query biasa.

```go
// user's ID is `111`
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Batch Delete
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Soft deleted records will be ignored when querying
db.Where("age = 20").Find(&user)
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

Jika kamu tidak akan memasukkan `gorm.Model`, kamu bisa  mengaktifkan fitur hapus soft

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### Find soft deleted records

Anda dapat menemukandata record yang di hapusdengan`Unscoped`

```go
db.Unscoped().Where("age = 20").Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### Delete permanently

Anda dapat menghapus record yang cocok secara permanen dengan menggunakan Unscoped

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```

### Delete Flag

Use unix second as delete flag

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string
  DeletedAt soft_delete.DeletedAt
}

// Query
SELECT * FROM users WHERE deleted_at = 0;

// Delete
UPDATE users SET deleted_at = /* current unix second */ WHERE ID = 1;
```

{% note warn %}
**INFO** when using unique field with soft delete, you should create a composite index with the unix second based `DeletedAt` field, e.g:

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string                `gorm:"uniqueIndex:udx_name"`
  DeletedAt soft_delete.DeletedAt `gorm:"uniqueIndex:udx_name"`
}
```
{% endnote %}

Use `1` / `0` as delete flag

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID    uint
  Name  string
  IsDel soft_delete.DeletedAt `gorm:"softDelete:flag"`
}

// Query
SELECT * FROM users WHERE is_del = 0;

// Delete
UPDATE users SET is_del = 1 WHERE ID = 1;
```
