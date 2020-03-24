---
title: Определения
layout: страница
---

## gorm.Model

`gorm.Model` является базовой структурой GoLang, которая включает следующие поля: `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`.

It may be embedded into your model or you may build your own model without it.

```go
// Определение gorm.Model
type Model struct {
  ID        uint `gorm:"primary_key"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt *time.Time
}

// Добавление полей `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt` в модель `User`
type User struct {
  gorm.Model
  Name string
}

// Обявление модели w/o gorm.Model
type User struct {
  ID   int
  Name string
}
```

## `ID` это первичный ключ

GORM использует любое поле с именем `ID` как первичный ключ таблицы по умолчанию.

```go
type User struct {
  ID   string // поле с название `ID` будет использовано как первичный ключ по умолчанию
  Name string
}

// Установить поле `AnimalID` как первичный ключ
type Animal struct {
  AnimalID int64 `gorm:"primary_key"`
  Name     string
  Age      int64
}
```

## Плюрализированное имя таблицы

Название таблицы - плюралистическая версия структурного имени.

```go
type User struct {} // название таблицы по умолчанию `users`

// Установить имя таблицы User's как `profiles`
func (User) TableName() string {
  return "profiles"
}

func (u User) TableName() string {
  if u.Role == "admin" {
    return "admin_users"
  } else {
    return "users"
  }
}

// Отключить множественное имя таблицы, если установлено значение true, имя таблицы `User` будет` user`
db.SingularTable(true)
```

### Указание названия таблицы

```go
// Создать таблицу `deleted_users` со структурой User's
db.Table("deleted_users").CreateTable(&User{})

var deleted_users []User
db.Table("deleted_users").Find(&deleted_users)
//// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete()
//// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

### Изменение названий полей по умолчанию

Вы можете применить любые правила по умолчанию, определив `DefaultTableNameHandler`.

```go
gorm.DefaultTableNameHandler = func (db *gorm.DB, defaultTableName string) string  {
  return "prefix_" + defaultTableName;
}
```

## Snake Case Column Name

Названия столбцов будут именовать поле нижней части змеи.

```go
type User struct {
  ID        uint      // column name is `id`
  Name      string    // column name is `name`
  Birthday  time.Time // column name is `birthday`
  CreatedAt time.Time // column name is `created_at`
}

// Переопределение имени столбца
type Animal struct {
  AnimalId    int64     `gorm:"column:beast_id"`         // set column name to `beast_id`
  Birthday    time.Time `gorm:"column:day_of_the_beast"` // set column name to `day_of_the_beast`
  Age         int64     `gorm:"column:age_of_the_beast"` // set column name to `age_of_the_beast`
}
```

## Отслеживание метки времени

### CreatedAt

Для моделей, имеющих поле `CreatedAt`, оно будет установлено в момент, когда запись будет создана.

```go
db.Create(&user) // установит `CreatedAt` на текущее unix время

// Для изменения его значения, вы должны использовать `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

Для моделей, имеющих поле `UpdatedAt`, оно будет изменяться в момент, когда запись будет изменена.

```go
db.Save(&user) // установит `UpdatedAt` на текущее unix время

db.Model(&user).Update("name", "jinzhu") // установит `UpdatedAt` на текущее unix время
```

### DeletedAt

Для моделей с полем `DeletedAt`, когда вызывается метод экземпляра `Delete`, он не будет по-настоящему удален из базы данных, а установит поле `DeletedAt` на текущее unix время. Ссылка на [Мягкое удаление](delete.html#Soft-Delete)