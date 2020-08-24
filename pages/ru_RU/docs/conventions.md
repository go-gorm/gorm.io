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
// Установить поле `AnimalID` в качестве первичного ключа
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

**NOTE** `TableName` doesn't allow dynamic name, its result will be cached for future, to use dynamic name, you can use `Scopes`, for example:

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

Временно указать имя таблицы с помощью метода `Table`, например:

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

Смотрите [из подзапроса](advanced_query.html#from_subquery) для того, чтобы использовать SubQuery в оговорке

### <span id="naming_strategy">Стратегия именования</span>

GORM allows users change the default naming conventions by overriding the default `NamingStrategy`, which is used to build `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`, Check out [GORM Config](gorm_config.html#naming_strategy) for details

## Название столбца

Имя столбца db использует имя поля в формате `snake_case`.

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

Для моделей, имеющих поле `CreatedAt`, оно будет установлено в текущее время при создании записи, если её значение равно нулю

```go
db.Create(&user) // set `CreatedAt` to current time

user2 := User{Name: "jinzhu", CreatedAt: time.Now()}
db.Create(&user2) // user2's `CreatedAt` won't be changed

// To change its value, you could use `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

Для моделей, имеющих поле `CreatedAt`, оно будет установлено в текущее время при обновлении или создании записи, если её значение равно нулю

```go
db.Save(&user) // set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time

db.Model(&user).UpdateColumn("name", "jinzhu") // `UpdatedAt` won't be changed

user2 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Create(&user2) // user2's `UpdatedAt` won't be changed when creating

user3 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Save(&user3) // user3's `UpdatedAt` will change to current time when updating
```

**NOTE** GORM supports having multiple time tracking fields and track with UNIX (nano/milli) seconds, checkout [Models](models.html#time_tracking) for more details
