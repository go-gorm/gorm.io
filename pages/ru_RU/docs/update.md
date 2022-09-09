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

## Обновление одного столбца

При обновлении одного столбца с `Обновить`, он должен иметь какие-либо условия или может вызвать ошибку `ErrsingWhereClause`, смотрите [Block Global Updates](#block_global_updates) для деталей. При использовании метода `Model` и его значение имеют первичное значение и первичный ключ будет использоваться для построения условия, например:

```go
// Update с условиями
db.Model(&User{}).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE active=true;

// User's ID is `111`:
db.Model(&user).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111;

// Update с условиями и значением Model
db.Model(&user).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111 AND active=true;
```

## Обновление нескольких столбцов

`Updates` поддерживают обновление с помощью `структур` или `map[string]interface{}`, при обновлении со `структурой` по умолчанию будет обновлять только не-нулевые поля

```go
// Обновление атрибутами `структуры`, будут обновляться только не нулевые поля
db.Model(&user).Updates(User{Name: "hello", Age: 18, Active: false})
// UPDATE users SET name='hello', age=18, updated_at = '2013-11-17 21:34:10' WHERE id = 111;

// Обновление атрибутов с помощью `карты`
db.Model(&user).Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello', age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;
```

{% note warn %}
**ПРИМЕЧАНИЕ** При обновлении со структурой, GORM будет обновлять только ненулевые поля, вы можете использовать `карту` для обновления атрибутов или с помощью `Select` для указания полей для обновления
{% endnote %}

## Обновить выбранные поля

Если вы хотите обновить выбранные или игнорировать некоторые поля при обновлении, вы можете использовать `Select`, `Omit`

```go
// Select с картой
// User's ID = `111`:
db.Model(&user).Select("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello' WHERE id=111;

db.Model(&user).Omit("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// Select со структурой (выберите поля с нулевыми значениями)
db.Model(&user).Select("Name", "Age").Updates(User{Name: "new_name", Age: 0})
// UPDATE users SET name='new_name', age=0 WHERE id=111;

// Select всех полей (выбор всех полей включая нулевые поля)
db.Model(&user).Select("*").Update(User{Name: "jinzhu", Role: "admin", Age: 0})

// Select всех полей, но пропустить(Omit) Role (выбор всех полей включая нулевые поля)
db.Model(&user).Select("*").Omit("Role").Update(User{Name: "jinzhu", Role: "admin", Age: 0})
```

## Хуки Update

GORM позволяет использовать хуки `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate`, эти методы будут вызваны при обновлении записи, смотрите [Хуки](hooks.html) для подробностей

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to update")
    }
    return
}
```

## Updates пакетами

Если мы не указали запись, имеющую значение первичного ключа, с помощью `Model`, GORM будет выполнять пакетное обновление

```go
// Update с помощью структуры
db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin';

// Update с помощью карты
db.Table("users").Where("id IN ?", []int{10, 11}).Updates(map[string]interface{}{"name": "hello", "age": 18})
// UPDATE users SET name='hello', age=18 WHERE id IN (10, 11);
```

### <span id="block_global_updates">Глобальные блокировки при Updates</span>

Если вы выполните пакетное обновление без каких-либо условий, GORM НЕ выполнит его и вернет ошибку `ErrMissingWhereClause`

Вы должны использовать некоторые условия или использовать чистый SQL или включить режим `AllowGlobalUpdate`, например:

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

Получение количества измененных строк

```go
// Получение количество обновленных записей с помощью `RowsAffected`
result := db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin';

result.RowsAffected // возвращает количество обновленных записей
result.Error        // возвращает ошибку при обновлении
```

## Расширенный Update

### <span id="update_from_sql_expr">Обновление с помощью SQL выражения</span>

GORM позволяет обновлять столбец с выражением SQL, например:

```go
// product's ID = `3`
db.Model(&product).Update("price", gorm.Expr("price * ? + ?", 2, 100))
// UPDATE "products" SET "price" = price * 2 + 100, "updated_at" = '2013-11-17 21:34:10' WHERE "id" = 3;

db.Model(&product).Updates(map[string]interface{}{"price": gorm.Expr("price * ? + ?", 2, 100)})
// UPDATE "products" SET "price" = price * 2 + 100, "updated_at" = '2013-11-17 21:34:10' WHERE "id" = 3;

db.Model(&product).UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = 3;

db.Model(&product).Where("quantity > 1").UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = 3 AND quantity > 1;
```

Также GORM позволяет обновлять данные с помощью SQL выражения/Context Valuer с [настраиваемыми типами данных](data_types.html#gorm_valuer_interface), например:

```go
// Создание с помощью собственных типов данных
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

### Update с помощью вложенного запроса

Обновление таблицы с помощью вложенного запроса

```go
db.Model(&user).Update("company_name", db.Model(&Company{}).Select("name").Where("companies.id = users.company_id"))
// UPDATE "users" SET "company_name" = (SELECT name FROM companies WHERE companies.id = users.company_id);

db.Table("users as u").Where("name = ?", "jinzhu").Update("company_name", db.Table("companies as c").Select("name").Where("c.id = u.company_id"))

db.Table("users as u").Where("name = ?", "jinzhu").Updates(map[string]interface{}{"company_name": db.Table("companies as c").Select("name").Where("c.id = u.company_id")})
```

### Без использования хуков/отслеживания времени

Если вы хотите пропустить методы `Хуков`  и не отслеживать время обновления при обновлении, вы можете использовать `UpdateColumn`, `UpdateColumns` - это работает как и `Update`, `Updates`

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

Возврат измененных данных работает только для поддерживаемых баз данных, например:

```go
// возвращает все столбцы
var users []User
DB.Model(&users).Clauses(clause.Returning{}).Where("role = ?", "admin").Update("salary", gorm.Expr("salary * ?", 2))
// UPDATE `users` SET `salary`=salary * 2,`updated_at`="2021-10-28 17:37:23.19" WHERE role = "admin" RETURNING *
// users => []User{{ID: 1, Name: "jinzhu", Role: "admin", Salary: 100}, {ID: 2, Name: "jinzhu.2", Role: "admin", Salary: 1000}}

// возвращает указанные столбцы
DB.Model(&users).Clauses(clause.Returning{Columns: []clause.Column{{Name: "name"}, {Name: "salary"}}}).Where("role = ?", "admin").Update("salary", gorm.Expr("salary * ?", 2))
// UPDATE `users` SET `salary`=salary * 2,`updated_at`="2021-10-28 17:37:23.19" WHERE role = "admin" RETURNING `name`, `salary`
// users => []User{{ID: 0, Name: "jinzhu", Role: "", Salary: 100}, {ID: 0, Name: "jinzhu.2", Role: "", Salary: 1000}}
```

### Проверка, изменилось ли поле?

GORM предоставляет метод `Changed`, который может быть использован в **Before Update Hooks** при обновлении для проверки полей, которые будут обновлены или не обновлены

Метод `Changed` работает только с методами `Update`, `Updates`, и он только проверяет, соответствует ли значение обновления из `Update` / `Updates` значению модели, вернет true, если оно было изменено, а не пропущено

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

### Изменение обновляемых данных

Чтобы изменить обновляемые значения в хуках Before, вы должны использовать `SetColumn`, если это не полные обновления с `Save`, например:

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
