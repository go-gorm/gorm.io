---
title: Gen Update
layout: page
---

## 更新单列

当使用`Update`命令更新单独某一列的时候，必须存在`Where`条件，否则程序会抛出` ErrMissingWhereClause `异常，比如：

```go
u := query.User

// Update with conditions
u.WithContext(ctx).Where(u.Activate.Is(true)).Update(u.Name, "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE active=true;

// Update with conditions
u.WithContext(ctx).Where(u.Activate.Is(true)).Update(u.Age, u.Age.Add(1))
// or
u.WithContext(ctx).Where(u.Activate.Is(true)).UpdateSimple(u.Age.Add(1))
// UPDATE users SET age=age+1, updated_at='2013-11-17 21:34:10' WHERE active=true;

u.WithContext(ctx).Where(u.Activate.Is(true)).UpdateSimple(u.Age.Zero())
// UPDATE users SET age=0, updated_at='2013-11-17 21:34:10' WHERE active=true;
```

## 更新多列

`Updates` 方法支持使用 `struct` 和 `map[string]interface{}` 作为参数。默认情况下，当使用 `struct` 作为参数进行更新时，GORM 只会更新非零值的字段。

```go
u := query.User

// 使用 `map` 更新字段
u.WithContext(ctx).Where(u.ID.Eq(111)).Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello', age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// 使用 `struct` 更新字段
u.WithContext(ctx).Where(u.ID.Eq(111)).Updates(model.User{Name: "hello", Age: 18, Active: false})
// UPDATE users SET name='hello', age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// 使用表达式更新
u.WithContext(ctx).Where(u.ID.Eq(111)).UpdateSimple(u.Age.Add(1), u.Number.Add(1))
// UPDATE users SET age=age+1,number=number+1, updated_at='2013-11-17 21:34:10' WHERE id=111;

u.WithContext(ctx).Where(u.Activate.Is(true)).UpdateSimple(u.Age.Value(17), u.Number.Zero(), u.Birthday.Null())
// UPDATE users SET age=17, number=0, birthday=NULL, updated_at='2013-11-17 21:34:10' WHERE active=true;
```

> **注意** 当通过 struct 更新时，GORM 只会更新非零字段。 如果想确保指定字段被更新，你应该使用 `Select` 更新选定字段，或使用 `map` 来完成更新操作。

## 更新选定字段

如果您想要在更新时选定、忽略某些字段，您可以使用 `Select`、`Omit`

```go
u := query.User

// Select with Map
// User's ID is `111`:
u.WithContext(ctx).Select(u.Name).Where(u.ID.Eq(111)).Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello' WHERE id=111;

u.WithContext(ctx).Omit(u.Name).Where(u.ID.Eq(111)).Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

result, err := u.WithContext(ctx).Where(u.ID.Eq(111)).Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})

result.RowsAffected // affect rows number
err                 // error
```

## Update from SubQuery

Update a table by using SubQuery

```go
u := query.User
c := query.Company

u.WithContext(ctx).Update(u.CompanyName, c.Select(c.Name).Where(c.ID.EqCol(u.CompanyID)))
// UPDATE "users" SET "company_name" = (SELECT name FROM companies WHERE companies.id = users.company_id);

u.WithContext(ctx).Where(u.Name.Eq("modi")).Update(u.CompanyName, c.Select(c.Name).Where(c.ID.EqCol(u.CompanyID)))
```

## Update multiple columns from SubQuery

Update multiple columns by using SubQuery (for MySQL):

```go
u := query.User
c := query.Company

ua := u.As("u")
ca := u.As("c")

ua.WithContext(ctx).UpdateFrom(ca.WithContext(ctx).Select(c.ID, c.Address, c.Phone).Where(c.ID.Gt(100))).
Where(ua.CompanyID.EqCol(ca.ID)).
UpdateSimple(
  ua.Address.SetCol(ca.Address),
  ua.Phone.SetCol(ca.Phone),
)
// UPDATE `users` AS `u`,(
//   SELECT `company`.`id`,`company`.`address`,`company`.`phone`
//   FROM `company` WHERE `company`.`id` > 100 AND `company`.`deleted_at` IS NULL
// ) AS `c`
// SET `u`.`address`=`c`.`address`,`c`.`phone`=`c`.`phone`,`updated_at`='2021-11-11 11:11:11.111'
// WHERE `u`.`company_id` = `c`.`id`
```
