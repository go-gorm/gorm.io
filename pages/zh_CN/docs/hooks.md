---
title: 钩子
layout: page
---

## 对象生命周期

Hooks(一般称之为钩子函数)的功能是在运行创建/查询/更新/删除语句之前或者之后执行。

如果你为一个 model 定义了一个具体的方法，它将会在运行 创建，更新，查询，删除时自动被调用，并且如果任何回调函数函数返回一个错误，GORM 将会停止接下来的操作并且回滚当前的事务。

## 钩子函数

### 创建对象时

Creating an object，创建对象时可用的 hooks

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
    if !u.IsValid() {
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

**注意** 在 GORM 中 Save/Delete 操作默认是基于事务完成， 所以相关更改在提交事务之前是不可见的。 如果你想在你的 hooks 中看到这些变化，你可以在你的 hooks 中接收当前事务的参数，比如：

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
    tx.Model(u).Update("role", "admin")
    return
}
```

### 更新对象时

Updating an object，更新对象时可用的 hooks

```go
// begin transaction 开始事物
BeforeSave
BeforeUpdate
// save before associations 保存前关联
// update timestamp `UpdatedAt` 更新 `UpdatedAt` 时间戳
// save self 保存自己
// save after associations 保存后关联
AfterUpdate
AfterSave
// commit or rollback transaction 提交或回滚事务
```

代码实例:

```go
func (u *User) BeforeUpdate() (err error) {
    if u.readonly() {
        err = errors.New("read only user")
    }
    return
}

// 在同一个事务中更新数据
func (u *User) AfterUpdate(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("verfied", true)
  }
    return
}
```

### 删除对象时

Deleting an object，删除对象时可用的 hooks

```go
// begin transaction 开始事务
BeforeDelete
// delete self 删除自己
AfterDelete
// commit or rollback transaction 提交或回滚事务
```

代码实例:

```go
//  在一个事务中更新数据
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
    return
}
```

### 查询对象时

Querying an object，查询对象时可用的 hooks

```go
// load data from database 从数据库加载数据
// Preloading (eager loading) 预加载（加载）
AfterFind
```

代码实例:

```go
func (u *User) AfterFind() (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
    return
}
```