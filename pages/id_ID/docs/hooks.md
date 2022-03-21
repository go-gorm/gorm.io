---
title: Hooks
layout: page
---

## Siklus perkebnagan objek

Hooks are functions that are called before or after creation/querying/updating/deletion.

Jika Anda telah mendefinisikan metode tertentu untuk sebuah model, itu akan dipanggil secara otomatis saat create, updating, querying deletion, dan jika ada callback yang mengembalikan error, GORM akan menghentikan operasi dan mengembalikan jalur transaction.

Type dari hook disini seharusnya `func(*gorm.DB) error`

## Hooks

### Membuat sebuah objek

Hook yang tersedia untuk membuat

```go
// begin transaction
BeforeSave
BeforeCreate
// save before associations
// insert into database
// save after associations
AfterSave
AfterCreate
// commit or rollback transaction
```

Contoh code:

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

  if !u.IsValid() {
    err = errors.New("can't save invalid data")
  }
  return
}

func (u *User) AfterCreate(tx *gorm.DB) (err error) {
  if u.ID == 1 {
    tx.Model(u).Update("role", "admin")
  }
  return
}
```

{% note warn %}
NOTE "" Operasi Save/Delete di dalam GORM menjalankan pertukaran secara default, jadi peruba di dalam pertukaran itu tidak terlihat, jika kita mengembalikan nilai error apapun dalam hooks kita, maka perubahan itu akan di kembalikan
{% endnote %}

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
  if !u.IsValid() {
    return errors.New("rollback invalid user")
  }
  return nil
}
```

### Melakukan Update pada sebuah Objek

Hook yang tersedia untuk membuat

```go
// begin transaction
BeforeSave
BeforeUpdate
// save before associations
// update database
// save after associations
AfterSave
AfterUpdate
// commit or rollback transaction
```

Code Example:

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
  if u.readonly() {
    err = errors.New("read only user")
  }
  return
}

// Updating data in same transaction
func (u *User) AfterUpdate(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("verfied", true)
  }
  return
}
```

### Menghapus Sebuah Objek

Hook yang tersedia untuk melakukan Delete

```go
// begin transaction
BeforeDelete
// delete from database
AfterDelete
// commit or rollback transaction
```

Contoh kode:

```go
// Updating data in same transaction
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
  return
}
```

### Querying on object (get data)

Hook yang tersedia untuk querying (mengambil data)

```go
// load data from database
// Preloading (eager loading)
AfterFind
```

Code Example:

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
  return
}
```

## Memodifikasi alur operasi

```go
func (u *User) BeforeCreate(tx *gorm.DB) error {
  // Modify current operation through tx.Statement, e.g:
  tx.Statement.Select("Name", "Age")
  tx.Statement.AddClause(clause.OnConflict{DoNothing: true})

  // tx is new session mode with the `NewDB` option
  // operations based on it will run inside same transaction but without any current conditions
  var role Role
  err := tx.First(&role, "name = ?", user.Role).Error
  // SELECT * FROM roles WHERE name = "admin"
  // ...
  return err
}
```
