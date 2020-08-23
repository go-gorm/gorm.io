---
title: 删除
layout: page
---

## 删除记录

删除一条记录

```go
// 删除一条已有的记录（email 的主键值为 10）
db.Delete(&email)
// DELETE from emails where id=10;

// 通过内联条件删除记录
db.Delete(&Email{}, 20)
// DELETE from emails where id=20;

// 带上其它条件
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE FROM emails WHERE id=10 AND name = 'jinzhu'
```

## 删除钩子

对于删除操作，GORM 支持 `BeforeDelete`、`AfterDelete` 钩子，在删除记录时会调用这些方法，详情请参考 [钩子](hooks.html)

```go
func (u *User) BeforeDelete(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to delete")
    }
    return
}
```

## 批量删除

如果没有指定带有主键值的记录，GORM 将执行批量删除，删除所有匹配的记录

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

### 阻止全局删除

如果在没有任何条件的情况下执行批量删除，GORM 不会执行该操作，并返回` ErrMissingWhereClause `错误

对此，你必须加一些条件，或者使用原生 SQL，或者启用 `AllowGlobalUpdate` 模式，例如：

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE `users` WHERE 1=1

DB.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// UPDATE users SET `name` = "jinzhu"
```

## 软删除

如果您的模型包含了一个 `gorm.deletedat` 字段（`gorm.Model` 已经包含了该字段)，它将自动获得软删除的能力！

拥有软删除能力的模型调用 `Delete` 时，记录不会被数据库。但 GORM 会将 `DeletedAt` 置为当前时间， 并且你不能再通过普通的查询方法找到该记录。

```go
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// 批量删除
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// 在查询时会忽略被软删除的记录
db.Where("age = 20").Find(&user)
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

如果您不想引入 `gorm.Model`，您也可以这样启用软删除特性：

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### 查找被软删除的记录

您可以使用 `Unscoped` 找到被软删除的记录

```go
db.Unscoped().Where("age = 20").Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### 永久删除

您也可以使用 `Unscoped` 永久删除匹配的记录

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```
