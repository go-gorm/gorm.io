---
title: Hooks
layout: page
---

## オブジェクトのライフサイクル

Hooks は 作成／取得／更新／削除 処理の前後に呼び出される関数です。

指定のメソッドをモデルに対して定義すると、作成・更新・取得・削除時にそのメソッドが自動的に呼び出されます。 定義したメソッドが返した場合、GORMは以降の操作を中止し、トランザクションをロールバックします。

`func(*gorm.DB) error` が Hooks メソッドの型となります。

## Hooks

### オブジェクトの作成

作成処理時に利用可能なHooks

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

コード例：

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
**注意** デフォルトでは、GORMでの保存/削除操作はトランザクション内で実行されます。 つまり、トランザクション内で行われた変更はコミットされるまで参照できません。Hookメソッドがエラーを返却した場合、変更はロールバックされます。
{% endnote %}

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
  if !u.IsValid() {
    return errors.New("rollback invalid user")
  }
  return nil
}
```

### オブジェクトの更新

更新処理時に利用可能なHooks

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

コード例：

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

### オブジェクトの削除

削除処理時に利用可能なHooks

```go
// begin transaction
BeforeDelete
// delete from database
AfterDelete
// commit or rollback transaction
```

コード例：

```go
// 同一トランザクション内でのデータの更新
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
  return
}
```

### オブジェクトを取得する

取得処理時に利用可能なHooks

```go
// load data from database
// Preloading (eager loading)
AfterFind
```

コード例：

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
  return
}
```

## 現在の操作を変更する

```go
func (u *User) BeforeCreate(tx *gorm.DB) error {
  // Modify current operation through tx.Statement, e.g:
  // tx.Statement を使用して現在の操作を変更する。例：
  tx.Statement.Select("Name", "Age")
  tx.Statement.AddClause(clause.OnConflict{DoNothing: true})

  // tx は `NewDB` オプションで生成された new session mode のインスタンス
  // tx を利用した操作は 同一トランザクション内で実行されますが、元の処理の状態は反映されません
  var role Role
  err := tx.First(&role, "name = ?", user.Role).Error
  // SELECT * FROM roles WHERE name = "admin"
  // ...
  return err
}
```
