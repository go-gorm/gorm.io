---
title: Sil
layout: sayfa
---

## Bir Kaydı Sil

Bir kaydı silerken, silinen değerin birincil anahtara sahip olması gerekir, aksi takdirde [toplu silme](#batch_delete) işlemini tetiklenir. Örneğin:

```go
// Email Id değerimizin '10' olduğunu varsayalım
db.Delete(&email)
// DELETE from emails where id = 10;

// Koşul belirterek silme işlemi
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE from emails where id = 10 AND name = "jinzhu";
```

## Birincil anahtar ile sil

GORM, satır içi koşul ile birincil anahtar(lar) kullanarak nesneleri silmeye izin verir, sayılarla çalışır, ayrıntılar için [Satır içi koşullar](query.html#inline_conditions) bölümüne göz atın

```go
db.Delete(&User{}, 10)
// DELETE FROM users WHERE id = 10;

db.Delete(&User{}, "10")
// DELETE FROM users WHERE id = 10;

db.Delete(&users, []int{1,2,3})
// DELETE FROM users WHERE id IN (1,2,3);
```

## Hook ile Silme

GORM,`BeforeDelete`, `AfterDelete` hooklarına izin verir, bu yöntemler bir kayıt silinirken çağrılacaktır, ayrıntılar için [Hooks](hooks.html) sayfasına bakınız

```go
func (u *User) BeforeDelete(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin kullanıcısının silme yetkisi yok")
    }
    return
}
```

## <span id="batch_delete">Toplu Silme</span>

Belirtilen değerin birincil değeri yoksa, GORM bir toplu silme işlemi gerçekleştirir, koşulla eşleşen tüm kayıtları siler

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(&Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(&Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

Çok sayıda kaydı verimli bir şekilde silmek için, `Delete` yöntemine birincil anahtarları içeren bir slice ekleyin.

```go
var users = []User{{ID: 1}, {ID: 2}, {ID: 3}}
db.Delete(&users)
// DELETE FROM users WHERE id IN (1,2,3);

db.Delete(&users, "name LIKE ?", "%jinzhu%")
// DELETE FROM users WHERE name LIKE "%jinzhu%" AND id IN (1,2,3); 
```

### Global Silme İşlemini Engelleme

Herhangi bir koşul olmadan bir toplu silme işlemi gerçekleştirirseniz, GORM bunu çalıştırmaz ve `ErrMissingWhereClause` hatası döndürür

Eğer kullanmak istiyorsanız, bazı koşulları eklemelisiniz, Saf (Raw) SQL sorgusu kullanmalısınız veya `AllowGlobalUpdate` modunu aktif etmeniz gerekiyor. Örneğin:

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause hatası döndürür.

db.Delete(&[]User{{Name: "jinzhu1"}, {Name: "jinzhu2"}}).Error // gorm.ErrMissingWhereClause hatası döndürür.

db.Where("1 = 1").Delete(&User{})
// DELETE FROM `users` WHERE 1=1

db.Exec("DELETE FROM users")
// DELETE FROM users

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// DELETE FROM users
```

### Silinen Satırlardan Veri Döndürme

Silinen verileri döndür, yalnızca destekleyen veritabanları için döndürür, Örneğin:

```go
// Bütün sütunları döndürür
var users []User
DB.Clauses(clause.Returning{}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING *
// users => []User{{ID: 1, Name: "jinzhu", Role: "admin", Salary: 100}, {ID: 2, Name: "jinzhu.2", Role: "admin", Salary: 1000}}

// Belirtilen sütunları döndürür
DB.Clauses(clause.Returning{Columns: []clause.Column{{Name: "name"}, {Name: "salary"}}}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING `name`, `salary`
// users => []User{{ID: 0, Name: "jinzhu", Role: "", Salary: 100}, {ID: 0, Name: "jinzhu.2", Role: "", Salary: 1000}}
```

## Geçici Silme

If your model includes a `gorm.DeletedAt` field (which is included in `gorm.Model`), it will get soft delete ability automatically!

When calling `Delete`, the record WON'T be removed from the database, but GORM will set the `DeletedAt`'s value to the current time, and the data is not findable with normal Query methods anymore.

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

If you don't want to include `gorm.Model`, you can enable the soft delete feature like:

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### Find soft deleted records

You can find soft deleted records with `Unscoped`

```go
db.Unscoped().Where("age = 20").Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### Delete permanently

You can delete matched records permanently with `Unscoped`

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```

### Delete Flag

By default, `gorm.Model` uses `*time.Time` as the value for the `DeletedAt` field, and it provides other data formats support with plugin `gorm.io/plugin/soft_delete`

{% note warn %}
**INFO** when creating unique composite index for the DeletedAt field, you must use other data format like unix second/flag with plugin `gorm.io/plugin/soft_delete`'s help, e.g:

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string                `gorm:"uniqueIndex:udx_name"`
  DeletedAt soft_delete.DeletedAt `gorm:"uniqueIndex:udx_name"`
}
```
{% endnote %}

#### Unix Second

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

You can also specify to use `milli` or `nano` seconds as the value, for example:

```go
type User struct {
  ID    uint
  Name  string
  DeletedAt soft_delete.DeletedAt `gorm:"softDelete:milli"`
  // DeletedAt soft_delete.DeletedAt `gorm:"softDelete:nano"`
}

// Query
SELECT * FROM users WHERE deleted_at = 0;

// Delete
UPDATE users SET deleted_at = /* current unix milli second or nano second */ WHERE ID = 1;
```

#### Use `1` / `0` AS Delete Flag

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

#### Mixed Mode

Mixed mode can use `0`, `1` or unix seconds to mark data as deleted or not, and save the deleted time at the same time.

```go
type User struct {
  ID        uint
  Name      string
  DeletedAt time.Time
  IsDel     soft_delete.DeletedAt `gorm:"softDelete:flag,DeletedAtField:DeletedAt"` // use `1` `0`
  // IsDel     soft_delete.DeletedAt `gorm:"softDelete:,DeletedAtField:DeletedAt"` // use `unix second`
  // IsDel     soft_delete.DeletedAt `gorm:"softDelete:nano,DeletedAtField:DeletedAt"` // use `unix nano second`
}

// Query
SELECT * FROM users WHERE is_del = 0;

// Delete
UPDATE users SET is_del = 1, deleted_at = /* current unix second */ WHERE ID = 1;
```
