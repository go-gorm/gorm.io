---
title: Update
layout: page
---

## Update single column

When updating a single column with `Update`, it needs to have any conditions or it will raise error `ErrMissingWhereClause`, for example:

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

## Updates multiple columns

`Updates` supports update with `struct` or `map[string]interface{}`, when updating with `struct` it will only update non-zero fields by default

```go
u := query.User

// Update attributes with `map`
u.WithContext(ctx).Where(u.ID.Eq(111)).Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello', age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// Update attributes with `struct`
u.WithContext(ctx).Where(u.ID.Eq(111)).Updates(model.User{Name: "hello", Age: 18, Active: false})
// UPDATE users SET name='hello', age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// Update with expression
u.WithContext(ctx).Where(u.ID.Eq(111)).UpdateSimple(u.Age.Add(1), u.Number.Add(1))
// UPDATE users SET age=age+1,number=number+1, updated_at='2013-11-17 21:34:10' WHERE id=111;

u.WithContext(ctx).Where(u.Activate.Is(true)).UpdateSimple(u.Age.Value(17), u.Number.Zero(), u.Birthday.Null())
// UPDATE users SET age=17, number=0, birthday=NULL, updated_at='2013-11-17 21:34:10' WHERE active=true;
```

> **NOTE** When update with struct, GEN will only update non-zero fields, you might want to use `map` to update attributes or use `Select` to specify fields to update

## Update selected fields

If you want to update selected fields or ignore some fields when updating, you can use `Select`, `Omit`

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
