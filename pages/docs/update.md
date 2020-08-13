---
title: Update
layout: page
---

## Save All Fields

`Save` will save all fields when performing the Updating SQL

```go
db.First(&user)

user.Name = "jinzhu 2"
user.Age = 100
db.Save(&user)
// UPDATE users SET name='jinzhu 2', age=100, birthday='2016-01-01', updated_at = '2013-11-17 21:34:10' WHERE id=111;
```

## Update/Updates

Use `Update`, `Updates` to update selected fields

```go
// Update single attribute
// the user of `Model(&user)` needs to have primary key value, it is `111` in this example
db.Model(&user).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111;

// Update single attribute with conditions
db.Model(&user).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111 AND active=true;

// Update attributes with `struct`, will only update non-zero fields
db.Model(&user).Updates(User{Name: "hello", Age: 18, Active: false})
// UPDATE users SET name='hello', age=18, updated_at = '2013-11-17 21:34:10' WHERE id = 111;

// Update attributes with `map`
db.Model(&user).Updates(map[string]interface{}{"name": "hello", "age": 18, "actived": false})
// UPDATE users SET name='hello', age=18, actived=false, updated_at='2013-11-17 21:34:10' WHERE id=111;
```

**NOTE** When update with struct, GORM will only update non-zero fields, you might want to use `map` to update attributes or use `Select` to specify fields to update

## Update Selected Fields

If you want to update selected or ignore some fields when updating, you can use `Select`, `Omit`

```go
// Select with Map
// the user of `Model(&user)` needs to have primary key value, it is `111` in this example
db.Model(&user).Select("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "actived": false})
// UPDATE users SET name='hello' WHERE id=111;

db.Model(&user).Omit("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "actived": false})
// UPDATE users SET age=18, actived=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// Select with Struct
DB.Model(&result).Select("Name", "Age").Updates(User{Name: "new_name"})
// UPDATE users SET name='new_name', age=0 WHERE id=111;
```

## Update Hooks

GORM allows hooks `BeforeSave`, `BeforeUpdate`, `AfterSave`, `AfterUpdate`, those methods will be called when updating a record, refer [Hooks](hooks.html) for details

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
	if u.Role == "admin" {
		return errors.New("admin user not allowed to update")
	}
	return
}
```

## Batch Updates

If we haven't specified a record having primary key value with `Model`, GORM will perform a batch updates

```go
// Update with struct only works with none zero values, or use map[string]interface{}
db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin;

db.Table("users").Where("id IN (?)", []int{10, 11}).Updates(map[string]interface{}{"name": "hello", "age": 18})
// UPDATE users SET name='hello', age=18 WHERE id IN (10, 11);
```

### Block Global Updates

If you perform a batch update without any conditions, GORM WON'T run it and will return `ErrMissingWhereClause` error

You can use conditions like `1 = 1` to force the global update

```go
db.Model(&User{}).Update("name", "jinzhu").Error // gorm.ErrMissingWhereClause

db.Model(&User{}).Where("1 = 1").Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu" WHERE 1=1
```

### Updated Records Count

```go
// Get updated records count with `RowsAffected`
result := db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin;

result.RowsAffected // returns updated records count
result.Error        // returns updating error
```

## Advanced

### Update with SQL Expression

GORM allows updates column with SQL expression

```go
DB.Model(&product).Update("price", gorm.Expr("price * ? + ?", 2, 100))
// UPDATE "products" SET "price" = price * '2' + '100', "updated_at" = '2013-11-17 21:34:10' WHERE "id" = '2';

DB.Model(&product).Updates(map[string]interface{}{"price": gorm.Expr("price * ? + ?", 2, 100)})
// UPDATE "products" SET "price" = price * '2' + '100', "updated_at" = '2013-11-17 21:34:10' WHERE "id" = '2';

DB.Model(&product).UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = '2';

DB.Model(&product).Where("quantity > 1").UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
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
