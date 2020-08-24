---
title: Создать
layout: страница
---

## Создать запись

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

result := db.Create(&user) // передаем данные для создания в Create

user.ID             // возвращает первичный ключ добавленной записи
result.Error        // возвращает ошибку
result.RowsAffected // возвращает количество вставленных записей
```

## Создать с указанными полями

Создать с указанными полями

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

Создать без указанных полей

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## Создать хуки

GORM позволяет хуки `BeforeSave (перед сохранением)`, `BeforeCreate (перед созданием)`, `AfterSave (после сохранения)`, `AfterCreate (после создания)`, эти методы будут вызваны при создании записи, смотрите [Хуки](hooks.html) для подробностей

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

## <span id="batch_insert">Пакетная вставка</span>

Передайте массив с данными в метод `Create`, GORM создаст запрос SQL для вставки и заполнит первичными ключами массив, будут также вызваны методы хуков.

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
DB.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

Batch Insert is also supported when using [Upsert](#upsert) and [Create With Associations](#create_with_associations)

## Create From Map

GORM supports create from `map[string]interface{}` and `[]map[string]interface{}{}`, e.g:

```go
DB.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// batch insert from `[]map[string]interface{}{}`
DB.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

**NOTE** When creating from map, hooks won't be invoked, associations won't be saved and primary key values won't be back filled

## Advanced

### <span id="create_with_associations">Создать со связями</span>

When creating some data with associations, if its associations value is not zero-value, those associations will be upserted, and its `Hooks` methods will be invoked.

```go
type CreditCard struct {
  gorm.Model
  Number   string
  UserID   uint
}

type User struct {
  gorm.Model
  Name       string
  CreditCard CreditCard
}

db.Create(&User{
  Name: "jinzhu",
  CreditCard: CreditCard{Number: "411111111111"}
})
// INSERT INTO `users` ...
// INSERT INTO `credit_cards` ...
```

You can skip saving associations with `Select`, `Omit`, for example:

```go
db.Omit("CreditCard").Create(&user)

// skip all associations
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">Default Values</span>

You can define default values for fields with tag `default`, for example:

```go
type User struct {
  ID         int64
  Name       string `gorm:"default:galeone"`
  Age        int64  `gorm:"default:18"`
    uuid.UUID  UUID   `gorm:"type:uuid;default:gen_random_uuid()"` // db func
}
```

Then the default value *will be used* when inserting into the database for [zero-value](https://tour.golang.org/basics/12) fields

**NOTE** Any zero value like `0`, `''`, `false` won't be saved into the database for those fields defined default value, you might want to use pointer type or Scanner/Valuer to avoid this, for example:

```go
type User struct {
  gorm.Model
  Name string
  Age  *int           `gorm:"default:18"`
  Active sql.NullBool `gorm:"default:true"`
}
```

**NOTE** You have to setup the `default` tag for fields having default value in databae or GORM will use the zero value of the field when creating, for example:

```go
type User struct {
    ID   string `gorm:"default:uuid_generate_v3()"`
    Name string
    Age  uint8
}
```

### <span id="upsert">Upsert (Создать или обновить) / Конфликт</span>

GORM provides compatible Upsert support for different databases

```go
import "gorm.io/gorm/clause"

// Do nothing on conflict
DB.Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// Update columns to default value on `id` conflict
DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

// Update columns to new value on `id` conflict
DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age=VALUES(age); MySQL
```

Also checkout `FirstOrInit`, `FirstOrCreate` on [Advanced Query](advanced_query.html)

Checkout [Raw SQL and SQL Builder](sql_builder.html) for more details
