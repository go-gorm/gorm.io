---
title: Gen Delete
layout: page
---

## 删除记录

当删除一条记录时，需要满足一些条件否则程序会抛出`ErrMissingWhereClause`异常，例如：

```go
e := query.Email

// Email 的 ID 是 10
e.WithContext(ctx).Where(e.ID.Eq(10)).Delete()
// DELETE from emails where id = 10;

// 有附加条件的删除
e.WithContext(ctx).Where(e.ID.Eq(10), e.Name.Eq("modi")).Delete()
// DELETE from emails where id = 10 AND name = "modi";

result, err := e.WithContext(ctx).Where(e.ID.Eq(10), e.Name.Eq("modi")).Delete()

result.RowsAffected // 受影响的行
err                 // 错误
```

## 通过主键删除

GEN 允许使用带有内联条件的主键删除对象，它适用于数字

```go
u.WithContext(ctx).Where(u.ID.In(1,2,3)).Delete()
// DELETE FROM users WHERE id IN (1,2,3);
```

## 批量删除

如果指定值不包括主键，GEN 将执行批量删除，删除所有匹配记录

```go
e := query.Email

e.WithContext(ctx).Where(e.Name.Like("%modi%")).Delete()
// DELETE from emails where email LIKE "%modi%";
```

## 软删除

如果你的模型包含了 `gorm.DeletedAt`字段（在`gorm.Model`中），那么该模型将会自动获得软删除的能力！

当调用`Delete`时，GORM并不会从数据库中删除该记录，而是将该记录的`DeleteAt`设置为当前时间，之后普通查询方法将无法查找到此条记录。

```go
// 批量删除
u.WithContext(ctx).Where(u.Age.Eq(20)).Delete()
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// 查询时将忽略被软删除的记录
users, err := u.WithContext(ctx).Where(u.Age.Eq(20)).Find()
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

如果你不想嵌入 `gorm.Model`，你也可以这样启用软删除特性：

```go
type User struct {
    ID      int
    Deleted gorm.DeletedAt
    Name    string
}
```

## 查找被软删除的记录

你可以使用 `Unscoped` 找到被软删除的记录

```go
users, err := db.WithContext(ctx).Unscoped().Where(u.Age.Eq(20)).Find()
// SELECT * FROM users WHERE age = 20;
```

## 永久删除

你可以使用 `Unscoped`来永久删除匹配的记录

```go
o.WithContext(ctx).Unscoped().Where(o.ID.Eq(10)).Delete()
// DELETE FROM orders WHERE id=10;
```

### 删除关联

Remove the relationship between source & arguments if exists, only delete the reference, won’t delete those objects from DB.

```go
u := query.User

u.Languages.Model(&user).Delete(&languageZH, &languageEN)

u.Languages.Model(&user).Delete([]*Language{&languageZH, &languageEN}...)
```

### 带 Select 的删除

你可以在删除记录时通过 `Select` 来删除具有 has one、has many、many2many 关系的记录，例如：

```go
u := query.User

// 删除 user 时，也删除 user 关联的 account 数据
u.Select(u.Account).Delete(&user)

// 删除 user 时，也删除 user 关联的 Orders, CreditCards 数据
db.Select(u.Orders.Field(), u.CreditCards.Field()).Delete(&user)

// 删除 user 时，也删除 user 关联的 has one/many/many2many 关系数据
db.Select(field.AssociationsFields).Delete(&user)
```
