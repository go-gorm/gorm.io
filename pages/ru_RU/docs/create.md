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

[Создать или обновить](#upsert), [Создать со связями](#create_with_associations) поддерживается для пакетной вставки

## Дополнительно

### <span id="create_with_associations">Создать со связями</span>

Если в вашей модели определены связи, и она не имеет нулевых связей, эти данные будут сохранены при создании

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

Вы можете пропустить сохранение связей с помощью `Select`, `Omit`

```go
db.Omit("CreditCard").Create(&user)

// пропустить все связи
db.Omit(clause.Associations).Create(&user)
```

### Значения по умолчанию

Вы можете определить значения по умолчанию для полей при помощи тега `default`, например:

```go
type User struct {
  ID         int64
  Name       string `gorm:"default:'galeone'"`
  Age        int64  `gorm:"default:18"`
    uuid.UUID  UUID   `gorm:"type:uuid;default:gen_random_uuid()"` // функция БД
}
```

Значение по умолчанию будет использовано при добавлении записи в БД для полей с [нулевыми-значениями](https://tour.golang.org/basics/12)

**ПРИМЕЧАНИЕ** Любые нулевые значение, например `0`, `''`, `false` не будут сохранены в базу данных, для полей с определенным значением по умолчанию, вы можете использовать Scanner/Valuer для избежания этого, например:

```go
type User struct {
  gorm.Model
  Name string
  Age  *int           `gorm:"default:18"`
  Active sql.NullBool `gorm:"default:true"`
}
```

**ПРИМЕЧАНИЕ** Вы должны установить тег `default` для полей, имеющих значение по умолчанию в БД или GORM будет использовать нулевое значение поля при создании, например:

```go
type User struct {
    ID   string `gorm:"default:uuid_generate_v3()"`
    Name string
    Age  uint8
}
```

### <span id="upsert">Upsert (Создать или обновить) / Конфликт</span>

GORM обеспечивает поддержку Upsert (Создать или обновить) для различных баз данных

```go
import "gorm.io/gorm/clause"

// Ничего не делать при конфликте
DB.Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// Обновить колонок значением default при конфликте по полю `id`
DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

// Обновить на новые данные при конфликте по полю `id`
DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age=VALUES(age); MySQL
```

Смотрите также `FirstOrInit (первая или инициализировать)`, `FirstOrCreate (первая или создать)` в [Расширенный запрос SQL](advanced_query.html)

Смотрите [Чистый SQL и Конструктор SQL](sql_builder.html) для подробностей
