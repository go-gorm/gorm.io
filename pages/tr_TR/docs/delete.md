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

Modeliniz bir `gorm.DeletedAt` alanı içeriyorsa (`gorm.Model` içinde yer alır), otomatik olarak geçici silme özelliğine sahip olur!

`Delete` çağrıldığında, kayıt veritabanından kaldırılmaz, ancak GORM `DeletedAt`'ın değerine silinme tarihi atanır. Veriler sorgularınızda gözükmezler.

```go
// user's ID is `111`
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Toplu Silme
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Sorgulama sırasında geçici silinen kayıtlar yok sayılır
db.Where("age = 20").Find(&user)
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

`gorm.Model`'i dahil etmek istemiyorsanız, geçici silmeyi modelinize ekleyebilirsiniz. Örneğin:

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### Geçici silinmiş kayıtların bulunması

Geçici silinen kayıtları `Unscoped` ile bulabilirsiniz

```go
db.Unscoped().Where("age = 20").Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### Kalıcı Olarak Sil

`Unscoped` ile eşleşen kayıtları kalıcı olarak silebilirsiniz

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```

### Delete Flag

Varsayılan olarak, `gorm.Model` `DeletedAt` alanı için değer olarak `*time.Time` kullanır.`gorm.io/plugin/soft_delete` eklentisi ise diğer veri türleri içinde destek sağlar

{% note warn %}
**INFO** DeletedAt alanı için benzersiz bileşik dizin oluştururken, `gorm.io/plugin/soft_delete` eklentisinin yardımıyla unix second/flag gibi diğer veri türleri kullanmalısınız, örn:

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string                `gorm:"uniqueIndex:udx_name"`
  DeletedAt soft_delete.DeletedAt `gorm:"uniqueIndex:udx_name"`
}
```
{% endnote %}

#### Unix Zamanı (Epoch veya Posix)

Delete Flag'de unix zamanı kullanma

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

Değer olarak örneğin `milli` veya `nano` saniye kullanılmasını da belirtebilirsiniz:

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
UPDATE users SET deleted_at = /* geçerli zamana ait unix mili saniyesi veya nano saniyesi */ WHERE ID = 1;
```

#### Delete Flag olarak `1` / `0` kullanılması

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

#### Karışık Mod

Karma mod, verileri silinmiş veya silinmemiş olarak işaretlemek ve aynı zamanda silinen zamanı kaydetmek için `0`, `1` veya unix saniye kullanabilir.

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
