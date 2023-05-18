---
title: Create
layout: страница
---

## Создание записи

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

result := db.Create(&user) // передаем указатель на данные в Create

user.ID             // возвращает первичный ключ добавленной записи
result.Error        // возвращает ошибку
result.RowsAffected // возвращает количество вставленных записей
```

Мы также можем создать несколько записей с помощью `Create()`:
```go
users := []*User{
    User{Name: "Jinzhu", Age: 18, Birthday: time.Now()},
    User{Name: "Jackson", Age: 19, Birthday: time.Now()},
}

result := db.Create(users) // передайте фрагмент, чтобы вставить несколько строк

result.Error        // возвращает ошибку
result.RowsAffected // возвращает количество добавленных записей
```

## Создание записи с указанными полями

Создаем запись и присваиваем значение указанным полям.

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

Создайте запись и игнорируйте значения для полей, переданных в пропущенные (omit).

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## <span id="batch_insert">Пакетная вставка</span>

Чтобы эффективно вставить большое количество записей, передайте срез в метод `Create`. Передайте массив с данными в метод Create, GORM создаст запрос SQL для вставки и заполнит первичными ключами массив, будут также вызваны хук методы. При это начнется **транзакция**, когда записи могут быть переданы в несколько партий.

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

Вы можете указать размер пакета при создании с помощью `CreateInBatches`, например:

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// размер пакета 100
db.CreateInBatches(users, 100)
```

Пакетная вставка также поддерживается при использовании [Upsert](#upsert) и [Создания с помощью ассоциаций](#create_with_associations)

{% note warn %}
**ПРИМЕЧАНИЕ** инициализируйте GORM с помощью параметра `CreateBatchSize`, все `INSERT` будут учитывать этот параметр при создании записей и ассоциаций
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  CreateBatchSize: 1000,
})

db := db.Session(&gorm.Session{CreateBatchSize: 1000})

users = [5000]User{{Name: "jinzhu", Pets: []Pet{pet1, pet2, pet3}}...}

db.Create(&users)
// INSERT INTO users xxx (5 пакетов)
// INSERT INTO pets xxx (15 пакетов)
```

## Создание хуков

GORM позволяет реализовать пользовательские хуки для `BeforeSave`, `BeforeCreate`, `AfterSave` и `AfterCreate`.  Этот метод перехвата будет вызван при создании записи, обратитесь к [Хуки](hooks.html) для получения подробной информации о жизненном цикле

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("неправильная роль")
    }
    return
}
```

Если вы хотите пропустить `Хуки`, вы можете использовать режим сеанса `SkipHooks`, например:

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)
```

## Create с помощью Map(карты)

GORM поддерживает создание из `map[string]interface{}` и `[]map[string]interface{}{}`, например:

```go
db.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// пакетная вставка из `[]map[string]interface{}{}`
db.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**ПРИМЕЧАНИЕ** При создании на основе карты не будут вызываться хуки, ассоциации не будут сохранены, а значения первичного ключа не будут заполнены обратно
{% endnote %}

## <span id="create_from_sql_expr">Метод Create с помощью SQL выражения/значения контекста</span>

GORM позволяет вставлять данные с помощью SQL-выражения, есть два способа достичь этой цели, создать из `map[string]interface{}` или [Настраиваемые типы данных](data_types.html#gorm_valuer_interface), например:

```go
// Создать из map
db.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

// Создать из настраиваемого типа
type Location struct {
    X, Y int
}

// Scan реализует интерфейс sql.Scanner
func (loc *Location) Scan(v interface{}) error {
  // Scan a value into struct from database driver
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

db.Create(&User{
  Name:     "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"))
```

## Дополнительно

### <span id="create_with_associations">Create со связями</span>

При создании некоторых данных с ассоциациями, если их значение не равно нулю, эти ассоциации будут обновлены, и будут вызваны его `Хуки`.

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

Вы можете пропустить сохранение ассоциаций с помощью `Select`, `Omit`, например:

```go
db.Omit("CreditCard").Create(&user)

// пропустить все ассоциации
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">Значения по умолчанию</span>

Вы можете определить значения по умолчанию для полей с тегом `default`, например:

```go
type User struct {
  ID   int64
  Name string `gorm:"default:galeone"`
  Age  int64  `gorm:"default:18"`
}
```

Тогда значение по умолчанию * будет использоваться* при вставке в базу данных для [полей с нулевым значением](https://tour.golang.org/basics/12)

{% note warn %}
**ПРИМЕЧАНИЕ** Любое нулевое значение, например `0`, `"`, `false`, не будет сохранено в базе данных для этих полей, определенных значением по умолчанию, вы можете захотеть использовать тип указателя или Scanner / Valuer, чтобы избежать этого, например:
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
  FullName  string `gorm:"->;type:GENERATED ALWAYS AS (concat(firstname,' ',lastname));default:(-);"`
}
```

When using virtual/generated value, you might need to disable its creating/updating permission, check out [Field-Level Permission](models.html#field_permission)

### <span id="upsert">Upsert (Создать или обновить) / При конфликте</span>

GORM provides compatible Upsert support for different databases

```go
import "gorm.io/gorm/clause"

// Do nothing on conflict
db.Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// Update columns to default value on `id` conflict
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

// Use SQL expression
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"count": gorm.Expr("GREATEST(count, VALUES(count))")}),
}).Create(&users)
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `count`=GREATEST(count, VALUES(count));

// Update columns to new value on `id` conflict
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age); MySQL

// Update all columns to new value on conflict except primary keys and those columns having default values from sql func
db.Clauses(clause.OnConflict{
  UpdateAll: true,
}).Create(&users)
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age", ...;
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age), ...; MySQL
```

Also checkout `FirstOrInit`, `FirstOrCreate` on [Advanced Query](advanced_query.html)

Checkout [Raw SQL and SQL Builder](sql_builder.html) for more details
