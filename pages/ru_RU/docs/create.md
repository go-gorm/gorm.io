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

Пакетная вставка также поддерживается при использовании [Upsert](#upsert) и [Создать с ассоциациями](#create_with_associations)

## Создать из Map

GORM поддерживает создание из `map[string]interface{}` и `[]map[string]interface{}{}`, например:

```go
DB.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// пакетная вставка из `[]map[string]interface{}{}`
DB.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**ПРИМЕЧАНИЕ** При создании из map, хуки не будут вызываться, связи не будут сохранены и значения первичных ключей не будут возвращены
{% endnote %}

## <span id="create_from_sql_expr">Создать из SQL Expr/Context Valuer</span>

GORM позволяет вставить данные при помощи выражения SQL, существует два способа достижения этой цели, создать из `map[string]interface{}` или [Пользовательские типы данных](data_types.html#gorm_valuer_interface), например:

```go
// Создание из map
DB.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`point`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

// Создание из пользовательского типа данных
type Location struct {
    X, Y int
}

// Scan имплементирует интерфейс sql.Scanner
func (loc *Location) Scan(v interface{}) error {
  // Сканировать значение в struct из драйвера БД
}

func (loc Location) GormDataType() string {
  return "geometry"
}

func (loc Location) GormValue(ctx context.Context, db *gorm.DB) clause.Expr {
  return clause.Expr{
    SQL:  "ST_PointFromText(?)",
    Vars: []interface{}{fmt.Sprintf("POINT(%d %d)", loc.X, loc.Y)},
  }
}

type User struct {
  Name     string
  Location Location
}

DB.Create(&User{
  Name:     "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// INSERT INTO `users` (`name`,`point`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"))
```

## Дополнительно

### <span id="create_with_associations">Создать со связями</span>

При создании со связями, если значение связей не равно нулю, эти связи будут добавлены, и будут применены методы их `хуков`.

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

Вы можете пропустить сохранение связей с помощью `Select`, `Omit`, например:

```go
db.Omit("CreditCard").Create(&user)

// пропустить все связи 
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">Значения по умолчанию</span>

Вы можете определить значения по умолчанию для полей при помощи тега `default`, например:

```go
type User struct {
  ID   int64
  Name string `gorm:"default:galeone"`
  Age  int64  `gorm:"default:18"`
}
```

Значение по умолчанию *будет использовано* при добавлении записи в БД для полей с [нулевыми-значениями](https://tour.golang.org/basics/12)

{% note warn %}
**NOTE** Any zero value like `0`, `''`, `false` won't be saved into the database for those fields defined default value, you might want to use pointer type or Scanner/Valuer to avoid this, for example:
{% endnote %}

```go
type User struct {
  gorm.Model
  Name string
  Age  *int           `gorm:"default:18"`
  Active sql.NullBool `gorm:"default:true"`
}
```

{% note warn %}
**NOTE** You have to setup the `default` tag for fields having default or virtual/generated value in database, if you want to skip a default value definition when migrating, you could use `default:(-)`, for example:
{% endnote %}

```go
type User struct {
  ID        string `gorm:"default:uuid_generate_v3()"` // db func
  FirstName string
  LastName  string
  Age       uint8
  FullName  string `gorm:"->;type:GENERATED ALWAYS AS (concat(firstname,' ',lastname));default:(-);`
}
```

When using virtual/generated value, you might need to disable its creating/updating permission, check out [Field-Level Permission](models.html#field_permission)

### <span id="upsert">Upsert (Создать или обновить) / При конфликте</span>

GORM provides compatible Upsert support for different databases

```go
import "gorm.io/gorm/clause"

// Ничего не делать при конфликте
DB.Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// Обновить колонки в значение по умолчанию при конфликте по полю `id`
DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

// Обновить колонки в новые значения при конфликте по полю `id`
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
