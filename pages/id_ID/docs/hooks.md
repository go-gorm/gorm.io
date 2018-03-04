---
title: Hooks
layout: page
---
## Siklus Hidup Objek

Hooks are functions that are called before or after creation/querying/updating/deletion.

Jika anda memiliki metode definisi yang ditentukan untuk model, maka akan dipanggil secara otomatis saat membuat, memperbarui, pertanyaan, menghapus, dan jika ada callback yang mengembalikan kesalahan, GORM akan menghentikan operasi masa depan dan meneruskan transaksi saat ini.

## Kaitan

### Buat sebuah objek

Tersedia kaitan untuk membuat

```go
// begin transaction
BeforeSave
BeforeCreate
// save before associations
// update timestamp `CreatedAt`, `UpdatedAt`
// save self
// reload fields that have default value and its value is blank
// save after associations
AfterCreate
AfterSave
// commit or rollback transaction
```

Contoh Kode:

```go
func (u *User) BeforeSave() (err error) {
    if u.IsValid() {
        err = errors.New("can't save invalid data")
    }
    return
}

func (u *User) AfterCreate(scope *gorm.Scope) (err error) {
    if u.ID == 1 {
    scope.DB().Model(u).Update("role", "admin")
  }
    return
}
```

**CATATAN** Simpan/Hapus operasi dalam GORM yang berjalan pada transaksi secara default, sehingga perubahan yang dibuat dalam transaksi itu tidak terlihat sampai ia dilakukan. Jika anda ingin mengakses perubahan-perubahan ini di dalam kait anda, anda dapat menerima transaksi saat ini sebagai argumen di kait anda, sebagai contoh:

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
    tx.Model(u).Update("role", "admin")
    return
}
```

### Memperbarui objek

Available hooks for updating

```go
// begin transaction
BeforeSave
BeforeUpdate
// save before associations
// update timestamp `UpdatedAt`
// save self
// save after associations
AfterUpdate
AfterSave
// commit or rollback transaction
```

Code Example:

```go
func (u *User) BeforeUpdate() (err error) {
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

### Menghapus sebuah obyek

Available hooks for deleting

```go
// begin transaction
BeforeDelete
// delete self
AfterDelete
// commit or rollback transaction
```

Contoh Kode:

```go
// Updating data in same transaction
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
    return
}
```

### Permintaan sebuah objek

Available hooks for querying

```go
// load data from database
// Preloading (edger loading)
AfterFind
```

Code Example:

```go
func (u *User) AfterFind() (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
    return
}
```