---
title: Преобразования
layout: страница
---

## `ID` как первичный ключ

GORM использует поле с именем `ID` в качестве первичного ключа таблицы по умолчанию.

```go
type User struct {
  ID   string // поле с названием `ID` будет использовано для первичного ключа по умолчанию
  Name string
}
```

Вы можете установить другие поля в качестве первичного ключа при помощи тега `primaryKey`

```go
// Set field `UUID` as primary field
type Animal struct {
  ID     int64
  UUID   string `gorm:"primaryKey"`
  Name   string
  Age    int64
}
```

Также смотрите [Композитный первичный Ключ](composite_primary_key.html)

## Плюрализация имен таблиц

GORM плюрализует имя struct в `snake_cases (правило именования)` в качестве имени таблицы, для stuct `User`, название таблицы будет `users` по умолчанию

### TableName

Вы можете изменить название таблицы по умолчанию, реализуя интерфейс `Tabler`, например:

```go
type Tabler interface {
    TableName() string
}

// TableName переопределяет название таблицы для User на `profiles`
func (User) TableName() string {
  return "profiles"
}
```

{% note warn %}
**NOTE** `TableName` doesn't allow dynamic name, its result will be cached for future, to use dynamic name, you can use `Scopes`, for example:
{% endnote %}

```go
func UserTable(user User) func (db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    if user.Admin {
      return db.Table("admin_users")
    }

    return db.Table("users")
  }
}

DB.Scopes(UserTable(user)).Create(&user)
```

### Временно указать имя

Temporarily specify table name with `Table` method, for example:

```go
// Создать таблицу `deleted_users` с полями struct User
db.Table("deleted_users").AutoMigrate(&User{})

// Запросить данные из другой таблицы
var deletedUsers []User
db.Table("deleted_users").Find(&deletedUsers)
// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete(&User{})
// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

Check out [From SubQuery](advanced_query.html#from_subquery) for how to use SubQuery in FROM clause

### <span id="naming_strategy">Стратегия именования</span>

GORM allows users change the default naming conventions by overriding the default `NamingStrategy`, which is used to build `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`, Check out [GORM Config](gorm_config.html#naming_strategy) for details

## Название столбца

Column db name uses the field's name's `snake_case` by convention.

```go
type User struct {
  ID        uint      // имя столбца `id`
  Name      string    // имя столбца `name`
  Birthday  time.Time // имя столбца `birthday`
  CreatedAt time.Time // имя столбца `created_at`
}
```

You can override the column name with tag `column` or use [`NamingStrategy`](#naming_strategy)

```go
type Animal struct {
  AnimalID int64     `gorm:"column:beast_id"`         // установить имя столбца `beast_id`
  Birthday time.Time `gorm:"column:day_of_the_beast"` // установить имя столбца `day_of_the_beast`
  Age      int64     `gorm:"column:age_of_the_beast"` // установить имя столбца `age_of_the_beast`
}
```

## Отслеживание времени

### CreatedAt

For models having `CreatedAt` field, the field will be set to the current time when the record is first created if its value is zero

```go
db.Create(&user) // установить`CreatedAt` в текущее время

user2 := User{Name: "jinzhu", CreatedAt: time.Now()}
db.Create(&user2) // поле `CreatedAt` не будет изменено

// Для изменения занчения поля `CreatedAt` используйте `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

For models having `UpdatedAt` field, the field will be set to the current time when the record is updated or created if its value is zero

```go
db.Save(&user) // установить `UpdatedAt` в текущее время

db.Model(&user).Update("name", "jinzhu") // установить `UpdatedAt` в текущее время

db.Model(&user).UpdateColumn("name", "jinzhu") // `UpdatedAt` не изменится

user2 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Create(&user2) // `UpdatedAt` не будет изменено при создании

user3 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Save(&user3) // `UpdatedAt` будет обновлено в текуще время при обновлении
```

{% note %}
**NOTE** GORM supports having multiple time tracking fields and track with UNIX (nano/milli) seconds, checkout [Models](models.html#time_tracking) for more details
{% endnote %}
