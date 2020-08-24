---
title: Обновление
layout: страница
---

## Сохранить все поля

`Save` сохранит все поля при выполнении SQL

```go
db.First(&user)

user.Name = "jinzhu 2"
user.Age = 100
db.Save(&user)
// UPDATE users SET name='jinzhu 2', age=100, birthday='2016-01-01', updated_at = '2013-11-17 21:34:10' WHERE id=111;
```

## Update/Updates

Используйте `Update`, `Updates` для обновления выбранных полей

```go
// Обновить один атрибут
// модель `Model(&user)` должна иметь первичный ключ, например со значением `111`
db.Model(&user).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111;

// Обновить один атрибут с условиями
db.Model(&user).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111 AND active=true;

// Обновление атрибутов при помощи `struct`, обновит только не нулевые атрибуты
db.Model(&user).Updates(User{Name: "hello", Age: 18, Active: false})
// UPDATE users SET name='hello', age=18, updated_at = '2013-11-17 21:34:10' WHERE id = 111;

// Обновление атрибута при помощи `map`
db.Model(&user).Updates(map[string]interface{}{"name": "hello", "age": 18, "actived": false})
// UPDATE users SET name='hello', age=18, actived=false, updated_at='2013-11-17 21:34:10' WHERE id=111;
```

**ПРИМЕЧАНИЕ** При обновлении с помощью struct, GORM будет обновлять только не нулевые поля, вы можете использовать `map` для обновления атрибутов или `Select` для указания полей для обновления

## Обновить выбранные поля

Если вы хотите обновить выбранные или игнорировать некоторые поля при обновлении, вы можете использовать `Select`, `Omit`

```go
// Выборка при помощи Map
// the user of `Model(&user)` needs to have primary key value, it is `111` in this example
db.Model(&user).Select("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "actived": false})
// UPDATE users SET name='hello' WHERE id=111;

db.Model(&user).Omit("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "actived": false})
// UPDATE users SET age=18, actived=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// Выборка при помощи Struct
DB.Model(&result).Select("Name", "Age").Updates(User{Name: "new_name"})
// UPDATE users SET name='new_name', age=0 WHERE id=111;
```

## Обновить Хуки

GORM поддерживает хуки `BeforeSave`, `BeforeUpdate`, `AfterSave`, `AfterUpdate`, эти методы будут вызваны при обновлении записи, смотрите [хуки](hooks.html) для подробностей

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to update")
    }
    return
}
```

## Пакетные обновления

Если мы не указали запись первичный ключ с помощью `Model`, GORM будет выполнять пакетное обновление

```go
// Обновление при помощи struct будет работать только с не нулевыми значениями, или используйте map[string]interface{}
db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin;

db.Table("users").Where("id IN (?)", []int{10, 11}).Updates(map[string]interface{}{"name": "hello", "age": 18})
// UPDATE users SET name='hello', age=18 WHERE id IN (10, 11);
```

### Блокировать глобальные обновления

If you perform a batch update without any conditions, GORM WON'T run it and will return `ErrMissingWhereClause` error by default

You have to use some conditions or use raw SQL or enable `AllowGlobalUpdate` mode, for example:

```go
db.Model(&User{}).Update("name", "jinzhu").Error // gorm.ErrMissingWhereClause

db.Model(&User{}).Where("1 = 1").Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu" WHERE 1=1

DB.Session(&gorm.Session{AllowGlobalUpdate: true}).Model(&User{}).Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu"
```

### Количество обновленных записей

```go
// Получить количество обновленных записей при помощи `RowsAffected`
result := db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin;

result.RowsAffected // возвращает количество обновленных записей
result.Error        // возвращает ошибки обновления
```

## Дополнительно

### Обновить с помощью SQL выражения

GORM позволяет обновлять столбец с помощью выражений SQL

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
