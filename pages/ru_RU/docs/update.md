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

Если вы выполните пакетное обновление без каких-либо условий, GORM НЕ запустит его и вернет ошибку `ErrMissingWhereClause`

Вы можете использовать условия, такие как `1 = 1` для принудительного глобального обновления

```go
db.Model(&User{}).Update("name", "jinzhu").Error // gorm.ErrMissingWhereClause

db.Model(&User{}).Where("1 = 1").Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu" WHERE 1=1
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

### Без хуков/отслеживание времени

Если вы хотите пропустить методы `Хуков` и автоматическое обновление времени при обновлении, вы можете использовать `UpdateColumn`, `UpdateColumns`

```go
// Обновить один атрибут. аналогично `Update`
db.Model(&user).UpdateColumn("name", "hello")
// UPDATE users SET name='hello' WHERE id = 111;

// Обновить атрибуты, аналогично `Updates`
db.Model(&user).UpdateColumns(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE id = 111;

// Обновить атрибуты с помощью Select, аналогично `Updates`
db.Model(&user).Select("name", "age").UpdateColumns(User{Name: "hello"})
// UPDATE users SET name='hello', age=0 WHERE id = 111;
```

### Проверка, изменилось ли поле?

GORM предоставляет метод `Changed`, который может быть использован в **Before Hooks (Предварительные Хуки)** при обновлении для проверки полей, которые будут обновлены или не обновлены

Метод `Changed` работает только с методами `Update`, `Updates`, и проверяет только равно ли значение `Update` / `Updates` значению поля модели и будет ли поле сохранено или нет, вернет истину, если не равно и она будет сохранена

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
  // поле Role изменено
    if tx.Statement.Changed("Role") {
    return errors.New("role not allowed to change")
    }

  if tx.Statement.Changed("Name", "Admin") { // если Name или Role изменены
    tx.Statement.SetColumn("Age", 18)
  }

  // любое поле изменено
    if tx.Statement.Changed() {
        tx.Statement.SetColumn("RefreshedAt", time.Now())
    }
    return nil
}

db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu2"})
// Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu"})
// Changed("Name") => false, `Name` не изменено
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(map[string]interface{
  "name": "jinzhu2", "admin": false,
})
// Changed("Name") => false, `Name` не выбрано для обновления

db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu2"})
// Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu"})
// Changed("Name") => false, `Name` не изменено
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(User{Name: "jinzhu2"})
// Changed("Name") => false, `Name` не выбрано для обновления
```

### Изменить обновляемые данные

Чтобы изменить значения в Предварительных Хуках, следует использовать `scope.SetColumn` если это не полное обновление с использованием `Save`, например:

```go
func (user *User) BeforeSave(scope *gorm.Scope) (err error) {
  if pw, err := bcrypt.GenerateFromPassword(user.Password, 0); err == nil {
    scope.SetColumn("EncryptedPassword", pw)
  }
}

db.Model(&user).Update("Name", "jinzhu")
```
