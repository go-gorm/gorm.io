---
title: Hooks
layout: page
---

## 对象生命周期

Hooks(一般称之为钩子函数)的功能是在运行创建/查询/更新/删除语句之前或者之后执行。

如果你为一个 model 定义了一个具体的方法，它将会在运行 创建，更新，查询，删除时自动被调用，并且如果任何回调函数函数返回一个错误，GORM 将会停止接下来的操作并且回滚当前的事务。

## 钩子函数

### 创建一个对象

以下为可用的钩子函数

```go
// 开始事务
BeforeSave
BeforeCreate
// 在关联前保存
// 更新时间戳 `CreatedAt`, `UpdatedAt`
// save self
// 重新加载具有默认值的字段，其值为空
// 在关联后保存
AfterCreate
AfterSave
// 提交或回滚事务
```

示例代码

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

**NOTE** Save/Delete operations in GORM are running in transactions by default, so changes made in that transaction are not visible until it is commited. If you would like access those changes in your hooks, you could accept current transaction as argument in your hooks, for example:

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
    tx.Model(u).Update("role", "admin")
    return
}
```

### Updating an object

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