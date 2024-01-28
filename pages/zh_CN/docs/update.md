---
title: 更新
layout: page
---

## 保存所有字段

`Save` 会保存所有的字段，即使字段是零值

```go
db.First(&user)

user.Name = "jinzhu 2"
user.Age = 100
db.Save(&user)
// UPDATE users SET name='jinzhu 2', age=100, birthday='2016-01-01', updated_at = '2013-11-17 21:34:10' WHERE id=111;
```

`保存` 是一个组合函数。 如果保存值不包含主键，它将执行 `Create`，否则它将执行 `Update` (包含所有字段)。

```go
db.Save(&User{Name: "jinzhu", Age: 100})
// INSERT INTO `users` (`name`,`age`,`birthday`,`update_at`) VALUES ("jinzhu",100,"0000-00-00 00:00:00","0000-00-00 00:00:00")

db.Save(&User{ID: 1, Name: "jinzhu", Age: 100})
// UPDATE `users` SET `name`="jinzhu",`age`=100,`birthday`="0000-00-00 00:00:00",`update_at`="0000-00-00 00:00:00" WHERE `id` = 1
```

{% note warn %}
**NOTE**不要将 `Save` 和 `Model`一同使用, 这是 **未定义的行为**。
{% endnote %}

## 更新单个列

当使用 `Update` 更新单列时，需要有一些条件，否则将会引起`ErrMissingWhereClause` 错误，查看 [阻止全局更新](#block_global_updates) 了解详情。 当使用 `Model` 方法，并且它有主键值时，主键将会被用于构建条件，例如：

```go
// 根据条件更新
db.Model(&User{}).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE active=true;

// User 的 ID 是 `111`
db.Model(&user).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111;

// 根据条件和 model 的值进行更新
db.Model(&user).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111 AND active=true;
```

## 更新多列

`Updates` 方法支持 `struct` 和 `map[string]interface{}` 参数。当使用 `struct` 更新时，默认情况下GORM 只会更新非零值的字段

```go
// 根据 `struct` 更新属性，只会更新非零值的字段
db.Model(&user).Updates(User{Name: "hello", Age: 18, Active: false})
// UPDATE users SET name='hello', age=18, updated_at = '2013-11-17 21:34:10' WHERE id = 111;

// 根据 `map` 更新属性
db.Model(&user).Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello', age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;
```

{% note warn %}
**注意** 使用 struct 更新时, GORM 将只更新非零值字段。 你可能想用 `map` 来更新属性，或者使用 `Select` 声明字段来更新
{% endnote %}

## 更新选定字段

如果您想要在更新时选择、忽略某些字段，您可以使用 `Select`、`Omit`

```go
// 选择 Map 的字段
// User 的 ID 是 `111`:
db.Model(&user).Select("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello' WHERE id=111;

db.Model(&user).Omit("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// 选择 Struct 的字段（会选中零值的字段）
db.Model(&user).Select("Name", "Age").Updates(User{Name: "new_name", Age: 0})
// UPDATE users SET name='new_name', age=0 WHERE id=111;

// 选择所有字段（选择包括零值字段的所有字段）
db.Model(&user).Select("*").Updates(User{Name: "jinzhu", Role: "admin", Age: 0})

// 选择除 Role 外的所有字段（包括零值字段的所有字段）
db.Model(&user).Select("*").Omit("Role").Updates(User{Name: "jinzhu", Role: "admin", Age: 0})
```

## 更新 Hook

GORM 支持的 hook 包括：`BeforeSave`, `BeforeUpdate`, `AfterSave`, `AfterUpdate`. 更新记录时将调用这些方法，查看 [Hooks](hooks.html) 获取详细信息

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to update")
    }
    return
}
```

## 批量更新

If we haven't specified a record having a primary key value with `Model`, GORM will perform a batch update

```go
// Update with struct
db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin';

// Update with map
db.Table("users").Where("id IN ?", []int{10, 11}).Updates(map[string]interface{}{"name": "hello", "age": 18})
// UPDATE users SET name='hello', age=18 WHERE id IN (10, 11);
```

### <span id="block_global_updates">阻止全局更新</span>

If you perform a batch update without any conditions, GORM WON'T run it and will return `ErrMissingWhereClause` error by default

You have to use some conditions or use raw SQL or enable the `AllowGlobalUpdate` mode, for example:

```go
db.Model(&User{}).Update("name", "jinzhu").Error // gorm.ErrMissingWhereClause

db.Model(&User{}).Where("1 = 1").Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu" WHERE 1=1

db.Exec("UPDATE users SET name = ?", "jinzhu")
// UPDATE users SET name = "jinzhu"

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Model(&User{}).Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu"
```

### 更新的记录数

Get the number of rows affected by a update

```go
// Get updated records count with `RowsAffected`
result := db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin';

result.RowsAffected // returns updated records count
result.Error        // returns updating error
```

## 高级选项

### <span id="update_from_sql_expr">使用 SQL 表达式更新</span>

GORM allows updating a column with a SQL expression, e.g:

```go
// product's ID is `3`
db.Model(&product).Update("price", gorm.Expr("price * ? + ?", 2, 100))
// UPDATE "products" SET "price" = price * 2 + 100, "updated_at" = '2013-11-17 21:34:10' WHERE "id" = 3;

db.Model(&product).Updates(map[string]interface{}{"price": gorm.Expr("price * ? + ?", 2, 100)})
// UPDATE "products" SET "price" = price * 2 + 100, "updated_at" = '2013-11-17 21:34:10' WHERE "id" = 3;

db.Model(&product).UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = 3;

db.Model(&product).Where("quantity > 1").UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = 3 AND quantity > 1;
```

And GORM also allows updating with SQL Expression/Context Valuer with [Customized Data Types](data_types.html#gorm_valuer_interface), e.g:

```go
// Create from customized data type
type Location struct {
    X, Y int
}

func (loc Location) GormValue(ctx context.Context, db *gorm.DB) clause.Expr {
  return clause.Expr{
    SQL:  "ST_PointFromText(?)",
    Vars: []interface{}{fmt.Sprintf("POINT(%d %d)", loc.X, loc.Y)},
  }
}

db.Model(&User{ID: 1}).Updates(User{
  Name:  "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// UPDATE `user_with_points` SET `name`="jinzhu",`location`=ST_PointFromText("POINT(100 100)") WHERE `id` = 1
```

### 根据子查询进行更新

Update a table by using SubQuery

```go
db.Model(&user).Update("company_name", db.Model(&Company{}).Select("name").Where("companies.id = users.company_id"))
// UPDATE "users" SET "company_name" = (SELECT name FROM companies WHERE companies.id = users.company_id);

db.Table("users as u").Where("name = ?", "jinzhu").Update("company_name", db.Table("companies as c").Select("name").Where("c.id = u.company_id"))

db.Table("users as u").Where("name = ?", "jinzhu").Updates(map[string]interface{}{"company_name": db.Table("companies as c").Select("name").Where("c.id = u.company_id")})
```

### 不使用 Hook 和时间追踪

If you want to skip `Hooks` methods and don't track the update time when updating, you can use `UpdateColumn`, `UpdateColumns`, it works like `Update`, `Updates`

```go
// Update single column
db.Model(&user).UpdateColumn("name", "hello")
// UPDATE users SET name='hello' WHERE id = 111;

// Update multiple columns
db.Model(&user).UpdateColumns(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE id = 111;

// Update selected columns
db.Model(&user).Select("name", "age").UpdateColumns(User{Name: "hello", Age: 0})
// UPDATE users SET name='hello', age=0 WHERE id = 111;
```

### 返回修改行的数据

Returning changed data only works for databases which support Returning, for example:

```go
// return all columns
var users []User
db.Model(&users).Clauses(clause.Returning{}).Where("role = ?", "admin").Update("salary", gorm.Expr("salary * ?", 2))
// UPDATE `users` SET `salary`=salary * 2,`updated_at`="2021-10-28 17:37:23.19" WHERE role = "admin" RETURNING *
// users => []User{{ID: 1, Name: "jinzhu", Role: "admin", Salary: 100}, {ID: 2, Name: "jinzhu.2", Role: "admin", Salary: 1000}}

// return specified columns
db.Model(&users).Clauses(clause.Returning{Columns: []clause.Column{{Name: "name"}, {Name: "salary"}}}).Where("role = ?", "admin").Update("salary", gorm.Expr("salary * ?", 2))
// UPDATE `users` SET `salary`=salary * 2,`updated_at`="2021-10-28 17:37:23.19" WHERE role = "admin" RETURNING `name`, `salary`
// users => []User{{ID: 0, Name: "jinzhu", Role: "", Salary: 100}, {ID: 0, Name: "jinzhu.2", Role: "", Salary: 1000}}
```

### 检查字段是否有变更？

GORM provides the `Changed` method which could be used in **Before Update Hooks**, it will return whether the field has changed or not.

The `Changed` method only works with methods `Update`, `Updates`, and it only checks if the updating value from `Update` / `Updates` equals the model value. It will return true if it is changed and not omitted

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
  // if Role changed
    if tx.Statement.Changed("Role") {
    return errors.New("role not allowed to change")
    }

  if tx.Statement.Changed("Name", "Admin") { // if Name or Role changed
    tx.Statement.SetColumn("Age", 18)
  }

  // if any fields changed
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

### 在 Update 时修改值

To change updating values in Before Hooks, you should use `SetColumn` unless it is a full update with `Save`, for example:

```go
func (user *User) BeforeSave(tx *gorm.DB) (err error) {
  if pw, err := bcrypt.GenerateFromPassword(user.Password, 0); err == nil {
    tx.Statement.SetColumn("EncryptedPassword", pw)
  }

  if tx.Statement.Changed("Code") {
    user.Age += 20
    tx.Statement.SetColumn("Age", user.Age)
  }
}

db.Model(&user).Update("Name", "jinzhu")
```
