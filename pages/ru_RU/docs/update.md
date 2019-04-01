---
title: Update
layout: страница
---
## Обновить все поля

`Save` будет включать все поля при вызове Update, даже если ничего не изменено

```go
db.First(&user)

user.Name = "jinzhu 2"
user.Age = 100
db.Save(&user)

//// UPDATE users SET name='jinzhu 2', age=100, birthday='2016-01-01', updated_at = '2013-11-17 21:34:10' WHERE id=111;
```

## Обновить измененные поля

Если вы хотите обновить только измененные поля, вы можете использовать `Update`, `Updates`

```go
// Обновить один атрибут если он изменен
db.Model(&user).Update("name", "hello")
//// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111;

// Обновить один атрибут с использованием условий
db.Model(&user).Where("active = ?", true).Update("name", "hello")
//// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111 AND active=true;

// Обновить несколько атрибутов при помощи `карты`, будет менять только эти поля
db.Model(&user).Updates(map[string]interface{}{"name": "hello", "age": 18, "actived": false})
//// UPDATE users SET name='hello', age=18, actived=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// Обновить несколько атрибутов при помощи `структуры`, будет менять только измененные & не пустые поля
db.Model(&user).Updates(User{Name: "hello", Age: 18})
//// UPDATE users SET name='hello', age=18, updated_at = '2013-11-17 21:34:10' WHERE id = 111;

// ВНИМАНИЕ при обновлении с помощью структуры, GORM будет обновлять только не пустые значения
// Для текущего Update, ничего не будет обновлено, потому как "", 0, false пустые значения для их типов
db.Model(&user).Updates(User{Name: "", Age: 0, Actived: false})
```

## Обновить выбранные поля

Если вы хотите обновить или игнорировать некоторые поля при обновлении, вы можете использовать `Select`, `Omit`

```go
db.Model(&user).Select("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "actived": false})
//// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111;

db.Model(&user).Omit("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "actived": false})
//// UPDATE users SET age=18, actived=false, updated_at='2013-11-17 21:34:10' WHERE id=111;
```

## Обновление столбцов w/o хуки

Above updating operations will perform the model's `BeforeUpdate`, `AfterUpdate` method, update its `UpdatedAt` timestamp, save its `Associations` when updating, if you don't want to call them, you could use `UpdateColumn`, `UpdateColumns`

```go
// Обновить один атрибут, аналогично `Update`
db.Model(&user).UpdateColumn("name", "hello")
//// UPDATE users SET name='hello' WHERE id = 111;

// Обновить несколько атрибутов, аналогично `Updates`
db.Model(&user).UpdateColumns(User{Name: "hello", Age: 18})
//// UPDATE users SET name='hello', age=18 WHERE id = 111;
```

## Пакетные обновления

Хуки не будут запущены при пакетных обновлениях

```go
db.Table("users").Where("id IN (?)", []int{10, 11}).Updates(map[string]interface{}{"name": "hello", "age": 18})
//// UPDATE users SET name='hello', age=18 WHERE id IN (10, 11);

// Обновление с помощью структуры работает только с не нулевыми значениями, используйте map[string]interface{}
db.Model(User{}).Updates(User{Name: "hello", Age: 18})
//// UPDATE users SET name='hello', age=18;

// Получить количество обновленных записей с помощью `RowsAffected`
db.Model(User{}).Updates(User{Name: "hello", Age: 18}).RowsAffected
```

## Обновить при помощи SQL выражения

```go
DB.Model(&product).Update("price", gorm.Expr("price * ? + ?", 2, 100))
//// UPDATE "products" SET "price" = price * '2' + '100', "updated_at" = '2013-11-17 21:34:10' WHERE "id" = '2';

DB.Model(&product).Updates(map[string]interface{}{"price": gorm.Expr("price * ? + ?", 2, 100)})
//// UPDATE "products" SET "price" = price * '2' + '100', "updated_at" = '2013-11-17 21:34:10' WHERE "id" = '2';

DB.Model(&product).UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
//// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = '2';

DB.Model(&product).Where("quantity > 1").UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
//// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = '2' AND quantity > 1;
```

## Изменить значения в хуках

Если вы хотите изменить значения обновления в хуках с помощью `BeforeUpdate`, `BeforeSave`, вы можете использовать `scope.SetColumn`, например:

```go
func (user *User) BeforeSave(scope *gorm.Scope) (err error) {
  if pw, err := bcrypt.GenerateFromPassword(user.Password, 0); err == nil {
    scope.SetColumn("EncryptedPassword", pw)
  }
}
```

## Дополнительные опции обновления

```go
// Добавить строковый SQL для обновления
db.Model(&user).Set("gorm:update_option", "OPTION (OPTIMIZE FOR UNKNOWN)").Update("name", "hello")
//// UPDATE users SET name='hello', updated_at = '2013-11-17 21:34:10' WHERE id=111 OPTION (OPTIMIZE FOR UNKNOWN);
```