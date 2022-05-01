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
// Установить поле `UUID` как первичный ключ
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
**ПРИМЕЧАНИЕ** `TableName` не допускает динамическое имя, его результат будет кэшироваться на будущее, для использования динамического имени, вы можете использовать `Scopes`, например:
{% endnote %}

```go
func UserTable(user User) func (tx *gorm.DB) *gorm.DB {
  return func (tx *gorm.DB) *gorm.DB {
    if user.Admin {
      return tx.Table("admin_users")
    }

    return tx.Table("users")
  }
}

db.Scopes(UserTable(user)).Create(&user)
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

Смотрите [SubQuery](advanced_query.html#from_subquery) для того, чтобы использовать SubQuery в выражении FROM

### <span id="naming_strategy">Стратегия именования</span>

GORM позволяет пользователям изменять стратегию именования по умолчанию, переопределяя стандартную `NamingStrategy`, которая используется для сборки `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`, Смотрите [Настройки GORM](gorm_config.html#naming_strategy) для подробностей

## Название столбца

Имя столбца db использует имя поля в формате `snake_case` с преобразованием.

```go
type User struct {
  ID        uint      // имя столбца `id`
  Name      string    // имя столбца `name`
  Birthday  time.Time // имя столбца `birthday`
  CreatedAt time.Time // имя столбца `created_at`
}
```

Вы можете переопределить имя столбца с помощью тега `column`, или использовать [`NamingStrategy`](#naming_strategy)

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
db.Create(&user) // установить`CreatedAt` в текущее время

user2 := User{Name: "jinzhu", CreatedAt: time.Now()}
db.Create(&user2) // поле `CreatedAt` не будет изменено

// Для изменения занчения поля `CreatedAt` используйте `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

You can disable the timestamp tracking by setting `autoCreateTime` tag to `false`, for example:

```go
type User struct {
  CreatedAt time.Time `gorm:"autoCreateTime:false"`
}
```

### UpdatedAt

For models having `UpdatedAt` field, the field will be set to the current time when the record is updated or created if its value is zero

```go
db.Save(&user) // set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time

db.Model(&user).UpdateColumn("name", "jinzhu") // `UpdatedAt` won't be changed

user2 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Create(&user2) // user2's `UpdatedAt` won't be changed when creating

user3 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Save(&user3) // user3's `UpdatedAt` will change to current time when updating
```

You can disable the timestamp tracking by setting `autoUpdateTime` tag to `false`, for example:

```go
type User struct {
  UpdatedAt time.Time `gorm:"autoUpdateTime:false"`
}
```

{% note %}
**NOTE** GORM supports having multiple time tracking fields and track with UNIX (nano/milli) seconds, checkout [Models](models.html#time_tracking) for more details
{% endnote %}
