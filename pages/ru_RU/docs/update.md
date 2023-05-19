---
title: Update
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

`Save` - это комбинированная функция. Если сохраняемое значение не содержит первичного ключа, оно выполнит `Create`, в противном случае оно выполнит `Update` (со всеми полями).

```go
db.Save(&User{Name: "jinzhu", Age: 100})
// INSERT INTO `users` (`name`,`age`,`birthday`,`update_at`) VALUES ("jinzhu",100,"0000-00-00 00:00:00","0000-00-00 00:00:00")

db.Save(&User{ID: 1, Name: "jinzhu", Age: 100})
// UPDATE `users` SET `name`="jinzhu",`age`=100,`birthday`="0000-00-00 00:00:00",`update_at`="0000-00-00 00:00:00" WHERE `id` = 1
```

{% note warn %}
**ПРИМЕЧАНИЕ** Не используйте `Save` с `Model`, это **Неопределенное поведение**.
{% endnote %}

## Обновление одного столбца

При обновлении одного столбца с помощью `Update` для него должны быть какие-либо условия, иначе возникнет ошибка `ErrMissingWhereClause`, проверьте [Блокировка глобальных обновлений](#block_global_updates) для получения подробной информации. При использовании `Model` метод и его значение имеет первичное значение, первичный ключ будет использоваться для построения условия, например:

```go
// Обновление с условием
db.Model(&User{}).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE active=true;

// Пользовательский ID равен `111`:
db.Model(&user).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111;

// Обновление с условиями и значением модели
db.Model(&user).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111 AND active=true;
```

## Обновление нескольких столбцов

`Updates` поддерживает обновление с помощью `struct` или `map[string]interface{}`, при обновлении с помощью `struct` по умолчанию обновляются только ненулевые поля

```go
// Обновление атрибутов с помощью `struct`, обновятся только ненулевые поля
db.Model(&user).Updates(User{Name: "hello", Age: 18, Active: false})
// UPDATE users SET name='hello', age=18, updated_at = '2013-11-17 21:34:10' WHERE id = 111;

// Обновление атрибутов с `map`
db.Model(&user).Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello', age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;
```

{% note warn %}
**ПРИМЕЧАНИЕ** При обновлении с помощью struct GORM обновит только ненулевые поля. Возможно, вы захотите использовать `map` для обновления атрибутов или использовать `Select` для указания полей для обновления
{% endnote %}

## Обновить выбранные поля

Если вы хотите обновить выбранные поля или проигнорировать некоторые поля при обновлении, вы можете использовать `Select`, `Omit`

```go
// Выбрать c Map
// Пользовательский ID равен `111`:
db.Model(&user).Select("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello' WHERE id=111;

db.Model(&user).Omit("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// Выбрать со структурой (выберите поля с нулевым значением)
db.Model(&user).Select("Name", "Age").Updates(User{Name: "new_name", Age: 0})
// UPDATE users SET name='new_name', age=0 WHERE id=111;

// Выбрать все поля (выбрать все поля, включающие поля с нулевым значением)
db.Model(&user).Select("*").Updates(User{Name: "jinzhu", Role: "admin", Age: 0})

// Выбрать все поля, но исключить роль (выбрать все поля с нулевым значением)
db.Model(&user).Select("*").Omit("Role").Updates(User{Name: "jinzhu", Role: "admin", Age: 0})
```

## Хуки Update

GORM поддерживает хуки `BeforeSave`, `BeforeUpdate`, `AfterSave`, `AfterUpdate`. Эти методы будут вызываться при обновлении записи, смотрите [Хуки](hooks.html) для получения подробной информации

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to update")
    }
    return
}
```

## Updates пакетами

Если мы не указали запись, имеющую значение первичного ключа с помощью `Model`, GORM выполнит пакетное обновление

```go
// Обновление со структурой
db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin';

// Обновление с map
db.Table("users").Where("id IN ?", []int{10, 11}).Updates(map[string]interface{}{"name": "hello", "age": 18})
// UPDATE users SET name='hello', age=18 WHERE id IN (10, 11);
```

### <span id="block_global_updates">Глобальные блокировки при Updates</span>

Если вы выполните пакетное обновление без каких-либо условий, GORM НЕ запустит его и вернет ошибку `ErrMissingWhereClause` по умолчанию

Вы должны использовать некоторые условия, или использовать необработанный SQL, или включить режим `AllowGlobalUpdate`, например:

```go
db.Model(&User{}).Update("name", "jinzhu").Error // gorm.ErrMissingWhereClause

db.Model(&User{}).Where("1 = 1").Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu" WHERE 1=1

db.Exec("UPDATE users SET name = ?", "jinzhu")
// UPDATE users SET name = "jinzhu"

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Model(&User{}).Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu"
```

### Количество обновленных записей

Получить количество строк, затронутых обновлением

```go
// Получить количество обновленных записей с помощью `RowsAffected`
result := db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin';

result.RowsAffected // возвращает количество обновленных записей
result.Error        // возвращает ошибку обновления
```

## Расширенный Update

### <span id="update_from_sql_expr">Обновление с помощью SQL выражения</span>

GORM позволяет обновлять столбец с помощью SQL-выражения, например:

```go
// ID продукта равен `3`
db.Model(&product).Update("price", gorm.Expr("price * ? + ?", 2, 100))
// UPDATE "products" SET "price" = price * 2 + 100, "updated_at" = '2013-11-17 21:34:10' WHERE "id" = 3;

db.Model(&product).Updates(map[string]interface{}{"price": gorm.Expr("price * ? + ?", 2, 100)})
// UPDATE "products" SET "price" = price * 2 + 100, "updated_at" = '2013-11-17 21:34:10' WHERE "id" = 3;

db.Model(&product).UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = 3;

db.Model(&product).Where("quantity > 1").UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = 3 AND quantity > 1;
```

И GORM также позволяет обновлять записи с помощью SQL-выражений/контектстного значения используя [Настраиваемые типы данных](data_types.html#gorm_valuer_interface), например:

```go
// Создать на основе собственного типа данных
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

### Update с помощью подзапроса

Обновление таблицы при помощи подзапроса

```go
db.Model(&user).Update("company_name", db.Model(&Company{}).Select("name").Where("companies.id = users.company_id"))
// UPDATE "users" SET "company_name" = (SELECT name FROM companies WHERE companies.id = users.company_id);

db.Table("users as u").Where("name = ?", "jinzhu").Update("company_name", db.Table("companies as c").Select("name").Where("c.id = u.company_id"))

db.Table("users as u").Where("name = ?", "jinzhu").Updates(map[string]interface{}{"company_name": db.Table("companies as c").Select("name").Where("c.id = u.company_id")})
```

### Без использования хуков/отслеживания времени

Если вы хотите пропустить `хуки` и не отслеживать время обновления при обновлении, вы можете использовать `UpdateColumn`, `UpdateColumns`, это работает как `Update`, `Updates`

```go
// Обновить одну колонку
db.Model(&user).UpdateColumn("name", "hello")
// UPDATE users SET name='hello' WHERE id = 111;

// Обновить несколько колонок
db.Model(&user).UpdateColumns(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE id = 111;

// Обновить выбранные колонки
db.Model(&user).Select("name", "age").UpdateColumns(User{Name: "hello", Age: 0})
// UPDATE users SET name='hello', age=0 WHERE id = 111;
```

### Возврат данных из измененных строк

Возврат измененных данных работает только для баз данных, которые поддерживают возврат, например:

```go
// Возвратить все колонки
var users []User
db.Model(&users).Clauses(clause.Returning{}).Where("role = ?", "admin").Update("salary", gorm.Expr("salary * ?", 2))
// UPDATE `users` SET `salary`=salary * 2,`updated_at`="2021-10-28 17:37:23.19" WHERE role = "admin" RETURNING *
// users => []User{{ID: 1, Name: "jinzhu", Role: "admin", Salary: 100}, {ID: 2, Name: "jinzhu.2", Role: "admin", Salary: 1000}}

// Вернуть определенные колонки
db.Model(&users).Clauses(clause.Returning{Columns: []clause.Column{{Name: "name"}, {Name: "salary"}}}).Where("role = ?", "admin").Update("salary", gorm.Expr("salary * ?", 2))
// UPDATE `users` SET `salary`=salary * 2,`updated_at`="2021-10-28 17:37:23.19" WHERE role = "admin" RETURNING `name`, `salary`
// users => []User{{ID: 0, Name: "jinzhu", Role: "", Salary: 100}, {ID: 0, Name: "jinzhu.2", Role: "", Salary: 1000}}
```

### Проверка, изменилось ли поле?

GORM предоставляет метод `Changed`, который можно было бы использовать в **Before Updates Hooks**, он сообщит, изменилось поле или нет.

Метод `Changed` работает только с методами `Update`, `Updates`, и он проверяет только, соответствует ли значение обновления из `Update` / `Updates` значению значение модели. Он вернет значение true, если оно изменено, а не опущено

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
  // если роль изменилась
    if tx.Statement.Changed("Role") {
    return errors.New("role not allowed to change")
    }

  if tx.Statement.Changed("Name", "Admin") { если имя или роль изменились
    tx.Statement.SetColumn("Age", 18)
  }

  // если любое поле изменилось
    if tx.Statement.Changed() {
        tx.Statement.SetColumn("RefreshedAt", time.Now())
    }
    return nil
}

db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu2"})
// Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu"})
// Changed("Name") => false, `Name` без изменений
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(map[string]interface{
  "name": "jinzhu2", "admin": false,
})
// Changed("Name") => false, `Name` не выбрано для обновления

db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu2"})
// Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu"})
// Changed("Name") => false, `Name` не изменилось
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(User{Name: "jinzhu2"})
// Changed("Name") => false, `Name` не выбрано для обновления
```

### Изменение обновляемых данных

Чтобы изменить обновляемые значения в Before Hooks, вы должны использовать `SetColumn`, если только это не полное обновление с `Save`, например:

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
