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

GORM позволяет пользователям изменять стратегию именования по умолчанию, переопределяя стандартную `NamingStrategy`, которая используется для сборки `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`, Смотрите [Настройки GORM](gorm_config.html) для подробностей

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
db.Create(&user) // уствноит текущее время в `CreatedAt`

// Для смены значения, вы можете использовать `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

Для моделей, имеющих поле `CreatedAt`, оно будет установлено в текущее время при обновлении или создании записи, если её значение равно нулю

```go
db.Save(&user) // установит текущее время в `UpdatedAt`

db.Model(&user).Update("name", "jinzhu") // установит текущее время в `UpdatedAt`
```

**ПРИМЕЧАНИЕ** GORM поддерживает множество полей отслеживания времени, отслеживание с другими полями или отслеживание в UNIX секундах/UNIX наносекундах, смотрите [Модели](models.html#time_tracking) для подробностей
