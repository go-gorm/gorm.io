---
title: Hooks
layout: page
---

## 객체 수명 주기

Hook은 생성/조회/수정/삭제 이전 혹은 이후에 호출되는 함수입니다.

만약 어떤 모델에 대해 특정 함수를 정의했다면, 그 함수는 생성, 수정, 조회, 삭제 시에 자동적으로 호출됩니다. 또한 어떤 콜백이 에러를 반환한다면, GORM은 이후에 수행될 작업들을 멈추고 해당 트랜잭션을 롤백합니다.

훅 메서드의 타입은 `func(*gorm.DB) error`입니다.

## Hooks

### 객체 생성

생성 시에 활용할 수 있는 Hook

```go
// begin transaction
BeforeSave
BeforeCreate
// save before associations
// insert into database
// save after associations
AfterCreate
AfterSave
// commit or rollback transaction
```

코드 예제:

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
**NOTE** GORM에서 저장/삭제 작업은 기본적으로 트랜잭션 모드에서 실행되므로, 트랜잭션 안에서 발생한 변경사항 들은 커밋 이전에는 반영되지 않습니다. Hook에서 에러를 리턴한다면 변경사항은 모두 롤백됩니다.
{% endnote %}

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
  if !u.IsValid() {
    return errors.New("rollback invalid user")
  }
  return nil
}
```

### 객체 수정

수정 시에 활용할 수 있는 Hook

```go
// begin transaction
BeforeSave
BeforeUpdate
// save before associations
// update database
// save after associations
AfterUpdate
AfterSave
// commit or rollback transaction
```

코드 예제:

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

### 객체 삭제

삭제 시에 활용할 수 있는 Hook

```go
// begin transaction
BeforeDelete
// delete from database
AfterDelete
// commit or rollback transaction
```

코드 예제:

```go
// Updating data in same transaction
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
  return
}
```

### 객체 조회

조회 시에 활용할 수 있는 Hook

```go
// load data from database
// Preloading (eager loading)
AfterFind
```

코드 예제:

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
  return
}
```

## 현재 작업 수정

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
