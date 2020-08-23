---
title: Update
layout: page
---

## Save All Fields

`Save` will save all fields when performing the Updating SQL

```go
UpdateColumns(User{Name: "hello"})
// UPDATE users SET name='hello', age=0 WHERE id = 111;
```

## Update/Updates

Use `Update`, `Updates` to update selected fields

```go
// Update single attribute, similar with `Update`
db. UpdateColumn("name", "hello")
// UPDATE users SET name='hello' WHERE id = 111;

// Update attributes, similar with `Updates`
db. UpdateColumns(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE id = 111;

// Update attributes with Select, similar with `Updates`
db. Select("name", "age"). UpdateColumns(User{Name: "hello"})
// UPDATE users SET name='hello', age=0 WHERE id = 111;
```

**NOTE** When update with struct, GORM will only update non-zero fields, you might want to use `map` to update attributes or use `Select` to specify fields to update

## Update Selected Fields

If you want to update selected or ignore some fields when updating, you can use `Select`, `Omit`

```go
Updates(map[string]interface{"name": "jinzhu"})
// Changed("Name") => false, `Name` not changed
db. Updates(map[string]interface{
  "name": "jinzhu2", "admin": false,
})
// Changed("Name") => false, `Name` not selected to update

db. Updates(User{Name: "jinzhu2"})
// Changed("Name") => true
db. Updates(User{Name: "jinzhu"})
// Changed("Name") => false, `Name` not changed
db. Updates(User{Name: "jinzhu2"})
// Changed("Name") => false, `Name` not selected to update
```

## Update Hooks

GORM allows hooks `BeforeSave`, `BeforeUpdate`, `AfterSave`, `AfterUpdate`, those methods will be called when updating a record, refer [Hooks](hooks.html) for details

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
  // role field changed
    if tx. Changed("Role") {
    return errors. New("role not allowed to change")
    }

  if tx.
```

## Batch Updates

If we haven't specified a record having primary key value with `Model`, GORM will perform a batch updates

```go
UpdateColumns(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE id = 111;

// Update attributes with Select, similar with `Updates`
db. Select("name", "age"). UpdateColumns(User{Name: "hello"})
// UPDATE users SET name='hello', age=0 WHERE id = 111;
```

### Block Global Updates

If you perform a batch update without any conditions, GORM WON'T run it and will return `ErrMissingWhereClause` error by default

You have to use some conditions or use raw SQL or enable `AllowGlobalUpdate` mode, for example:

```go
db.Model(&User{}).Update("name", "jinzhu").Error // gorm.ErrMissingWhereClause

db.Model(&User{}).Where("1 = 1").Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu" WHERE 1=1

DB.Session(&gorm.Session{AllowGlobalUpdate: true}).Model(&User{}).Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu"
```

### Updated Records Count

```go
UpdateColumns(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE id = 111;

// Update attributes with Select, similar with `Updates`
db. Select("name", "age"). UpdateColumns(User{Name: "hello"})
// UPDATE users SET name='hello', age=0 WHERE id = 111;
```

## Advanced

### Update with SQL Expression

GORM allows updates column with SQL expression

```go
DB. Update("price", gorm. Updates(map[string]interface{"name": "jinzhu2"})
// Changed("Name") => true
db. + ?", 2, 100)})
// UPDATE "products" SET "price" = price * '2' + '100', "updated_at" = '2013-11-17 21:34:10' WHERE "id" = '2';

DB. Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = '2';

DB. Where("quantity > 1"). Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = '2' AND quantity > 1;
```

### Update from SubQuery

Update a table by using SubQuery

```go
DB.Model(&user).Update("price", DB.Model(&Company{}).Select("name").Where("companies.id = users.company_id"))
DB.Table("users as u").Where("name = ?", "jinzhu").Update("name", DB.Table("companies as c").Select("name").Where("c.id = u.company_id"))
DB.Table("users as u").Where("name = ?", "jinzhu").Updates(map[string]interface{}{}{"name": DB.Table("companies as c").Select("name").Where("c.id = u.company_id")})
```

### Without Hooks/Time Tracking

If you want to skip `Hooks` methods and the auto-update time tracking when updating, you can use `UpdateColumn`, `UpdateColumns`

```go
// Update single attribute, similar with `Update`
db.Model(&user).UpdateColumn("name", "hello")
// UPDATE users SET name='hello' WHERE id = 111;

// Update attributes, similar with `Updates`
db.Model(&user).UpdateColumns(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE id = 111;

// Update attributes with Select, similar with `Updates`
db.Model(&user).Select("name", "age").UpdateColumns(User{Name: "hello"})
// UPDATE users SET name='hello', age=0 WHERE id = 111;
```

### Check Field has changed?

GORM provides `Changed` method could be used in **Before Hooks** when updating to check fields going to be updated or not

The `Changed` method only works with methods `Update`, `Updates`, and it only checks if the value of `Update` / `Updates` equals model value's field value and will the field be saved or not, will returns true if not equal and it will be saved

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
  // role field changed
    if tx.Statement.Changed("Role") {
    return errors.New("role not allowed to change")
    }

  if tx.Statement.Changed("Name", "Admin") { // if Name or Role changed
    tx.Statement.SetColumn("Age", 18)
  }

  // any fields changed
    if tx.Statement.Changed() {
        tx.Statement.SetColumn("RefreshedAt", time.Now())
    }
    return nil
}

db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu2"})
// Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu"})
// Changed("Name") => false, `Name` not changed
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(map[string]interface{
  "name": "jinzhu2", "admin": false,
})
// Changed("Name") => false, `Name` not selected to update

db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu2"})
// Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu"})
// Changed("Name") => false, `Name` not changed
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(User{Name: "jinzhu2"})
// Changed("Name") => false, `Name` not selected to update
```

### Change Updating Values

To change updating values in Before Hooks, you should use `scope.SetColumn` unless it is a full updates with `Save`, for example:

```go
func (user *User) BeforeSave(scope *gorm.Scope) (err error) {
  if pw, err := bcrypt.GenerateFromPassword(user.Password, 0); err == nil {
    scope.SetColumn("EncryptedPassword", pw)
  }
}

db.Model(&user).Update("Name", "jinzhu")
```
