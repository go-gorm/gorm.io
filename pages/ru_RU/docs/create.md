---
title: Create
layout: страница
---

## Создать запись

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

db.NewRecord(user) // => вернет `true` пока первичный ключ пуст

db.Create(&user)

db.NewRecord(user) // => вернет `false` после создания `user`
```

## Значения по умолчанию

Вы можете определить значения поля по умолчанию при помощи тегов. Например:

```go
type Animal struct {
    ID   int64
    Name string `gorm:"default:'galeone'"`
    Age  int64
}
```

В таком случае SQL исключает эти поля, как не имеющие значения или [нулевые значения](https://tour.golang.org/basics/12). После вставки записи в базу данных, GORM загрузит в эти поля значения из базы данных.

```go
var animal = Animal{Age: 99, Name: ""}
db.Create(&animal)
// INSERT INTO animals("age") values('99');
// SELECT name from animals WHERE ID=111; // возвращаемый первичный ключ 111
// animal.Name => 'galeone'
```

**Примечание** все поля, имеющие нулевые значения, такие как `0`, `''`, `false` или другие [нулевые значения](https://tour.golang.org/basics/12), не сохраняются в базу данных, но будет использовать его значение по умолчанию. Если вы хотите избежать этого, рассмотрите использование типа указателя или сканера/оценщика, например:

```go
// Использование типа указателя
type User struct {
  gorm.Model
  Name string
  Age  *int `gorm:"default:18"`
}

// Использовать сканер/оценщик
type User struct {
  gorm.Model
  Name string
  Age  sql.NullInt64 `gorm:"default:18"`
}
```

## Установка значений полей в хуках

Если вы хотите обновить значение поля в `BeforeCreate` хуке, вы можете использовать `scope.SetColumn`, например:

```go
func (user *User) BeforeCreate(scope *gorm.Scope) error {
  scope.SetColumn("ID", uuid.New())
  return nil
}
```

## Дополнительные опции создания

```go
// Добавление дополнительных SQL опций при создании записи
db.Set("gorm:insert_option", "ON CONFLICT").Create(&product)
// INSERT INTO products (name, code) VALUES ("name", "code") ON CONFLICT;
```
