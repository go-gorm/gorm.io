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

GORM allows users to change the default naming conventions by overriding the default `NamingStrategy`, which is used to build `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`, Check out [GORM Config](gorm_config.html#naming_strategy) for details

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

Вы можете отключить отслеживание временных меток, установив для тега `autoCreateTime` значение `false`, например так:

```go
type User struct {
  CreatedAt time.Time `gorm:"autoCreateTime:false"`
}
```

### UpdatedAt

Для моделей, имеющих поле `UpdatedAt`, для поля будет установлено текущее время обновления или создания записи, если его значение равно нулю

```go
db.Save(&user) // установит `updatedAt` на текущее время

db.Model(&user).Update("name", "jinzhu") // установит `updatedAt` на текущее время

db.Model(&user).UpdateColumn("name", "jinzhu") // `UpdatedAt` не изменится

user2 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Create(&user2) // параметр `UpdatedAt` у пользователя user2 при создании записи не изменится

user3 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Save(&user3) // параметр `UpdatedAt` у пользователя user3 при обновлении записи изменится на текущее время
```

Вы можете отключить отслеживание временных меток, установив для тега `autoUpdateTime` значение `false`, например:

```go
type User struct {
  UpdatedAt time.Time `gorm:"autoUpdateTime:false"`
}
```

{% note %}
**ПРИМЕЧАНИЕ** GORM поддерживает наличие нескольких полей отслеживания времени и отслеживание с помощью UNIX (nano/milli) секунд, проверьте [Модели](models.html#time_tracking) для получения более подробной информации
{% endnote %}
