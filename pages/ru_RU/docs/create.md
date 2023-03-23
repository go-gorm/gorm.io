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

## Создание записи с указанными полями

Создаем запись и присваиваем значение указанным полям.

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

Создание записи и игнорирование значений CreatedAt для полей, переданных для omit.

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## <span id="batch_insert">Пакетная вставка</span>

Чтобы эффективно вставить большое количество записей, передайте слайс в метод `Create`. GORM создаст один SQL запрос для вставки всех данных и заполнения значений первичных ключей, а также будут вызваны хук методы.

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

Вы можете указать размер создаваемой вставки с помощью `CreateInBatches`, например:

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// batch size 100
db.CreateInBatches(users, 100)
```

Пакетная вставка также поддерживается при использовании [Upsert](#upsert) и [Создать с ассоциациями](#create_with_associations)

{% note warn %}
**Внимание** при инициализации GORM с опцией `CreateBatchSize`, все `INSERT` будут учитывать эту опцию при создании записи& объединения
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  CreateBatchSize: 1000,
})

db := db.Session(&gorm.Session{CreateBatchSize: 1000})

users = [5000]User{{Name: "jinzhu", Pets: []Pet{pet1, pet2, pet3}}...}

db.Create(&users)
// INSERT INTO users xxx (5 batches)
// INSERT INTO pets xxx (15 batches)
```

## Создание хуков

GORM позволяет реализовывать заданные пользователем хуки для `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate`.  Эти хуки будут вызываться при создании записи, подробности смотрите в [Хуки](hooks.html)

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

Если необходимо пропустить методы `Hooks`, вы можете использовать значение в Session `SkipHooks`:

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)
```

## Create с помощью Map(карты)

GORM поддерживает создание с помощью `map[string]interface{}` и `[]map[string]interface{}{}`, например:

```go
db.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// batch insert from `&[]map[string]interface{}{}`
db.Model(&User{}).Create(&[]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**ПРИМЕЧАНИЕ** При создании из карты, хуки не будут вызваны, связи не будут сохранены и значения первичных ключей не будут заполнены
{% endnote %}

## <span id="create_from_sql_expr">Метод Create с помощью SQL выражения/значения контекста</span>

GORM позволяет вставить данные при помощи выражения SQL. Существует два способа достижения этой цели: создать из `map[string]interface{}` или с помощью [Пользовательских типов данных](data_types.html#gorm_valuer_interface), например:

```go
// Create с помощью карты
db.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

// Create с помощью собственных типов
type Location struct {
    X, Y int
}

// Метод Scan использующий интерфейс sql.Scanner
func (loc *Location) Scan(v interface{}) error {
  // Scan значение в структуру из драйвера базы данных
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

// skip all associations
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
**ПРИМЕЧАНИЕ** Любые нулевые значение, например `0`, `''`, `false` не будут сохранены в базу данных. Для полей с определенным значением по умолчанию, вы можете использовать Scanner/Valuer для избежания этого, например:
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
**ПРИМЕЧАНИЕ** Вы должны установить тег `default` для полей по умолчанию или значения virtual/generated в базе данных. Если вы хотите пропустить определенные значения по умолчанию при миграции, вы должны использовать `default:(-)`, например:
{% endnote %}

```go
type User struct {
  ID        string `gorm:"default:uuid_generate_v3()"` // функция в базе данных
  FirstName string
  LastName  string
  Age       uint8
  FullName  string `gorm:"->;type:GENERATED ALWAYS AS (concat(firstname,' ',lastname));default:(-);"`
}
```

When using virtual/generated value, you might need to disable its creating/updating permission, check out [Field-Level Permission](models.html#field_permission)

### <span id="upsert">Upsert (Создать или обновить) / При конфликте</span>

GORM обеспечивает поддержку Upsert для различных баз данных

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

Смотрите также `FirstOrInit`, `FirstOrCreate` в [Расширенные запросы](advanced_query.html)

Смотрите [Сырой SQL и Конструктор SQL](sql_builder.html) для подробностей
