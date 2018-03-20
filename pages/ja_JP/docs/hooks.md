---
title: フック
layout: page
---
## オブジェクトのライフサイクル

フックとは生成/参照/更新/削除の前後に呼ばれる関数のことです。

モデルに特定のメソッドを定義すると、生成、更新、参照、削除の時に自動的に呼ばれます。コールバックからエラーを返した場合、GORMはそれ以降の操作を停止して現在のトランザクションをロールバックします。

## フック

### オブジェクトの生成

生成に使えるフック

```go
// トランザクションの開始
BeforeSave
BeforeCreate
// 関連の保存前
// `CreatedAt`と`UpdatedAt`のタイムスタンプ更新
// 自身の保存
// デフォルト値か空値のフィールドの再ロード
// 関連の保存後
AfterCreate
AfterSave
// トランザクションのコミットもしくはロールバック
```

コード例:

```go
func (u *User) BeforeSave() (err error) {
    if u.IsValid() {
        err = errors.New("不正な値を保存できません")
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

**メモ** GORMにおける保存と削除の操作はデフォルトでトランザクション内で実行されます。そのため、トランザクション内での変更はコミットするまで可視化されません。 フック内からこれらの変更にアクセスしたい場合は、現在のトランザクションをフックの引数として受け入れます。例:

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
    tx.Model(u).Update("role", "admin")
    return
}
```

### オブジェクトの更新

更新に使えるフック

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

コード例:

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

### Deleting an object

Available hooks for deleting

```go
// begin transaction
BeforeDelete
// delete self
AfterDelete
// commit or rollback transaction
```

Code Example:

```go
// Updating data in same transaction
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
    return
}
```

### Querying an object

Available hooks for querying

```go
// load data from database
// Preloading (eager loading)
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