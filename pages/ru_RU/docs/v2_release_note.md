---
title: GORM 2.0 Release Note
layout: page
---

GORM 2.0 это перезапись с нуля, представляет некоторые изменения несовместимых API и много улучшений

**Ключевые моменты**

* Улучшение производительности
* Модульность
* Context, Batch Insert, Prepared Statment Mode, DryRun Mode, Join Preload, Find To Map, Create From Map, FindInBatches
* Вложенная транзакция/SavePoint/RollbackTo
* SQL Builder, Named Argument, Group Conditions, Upsert, Locking, Optimizer/Index/Comment Hints supports, SubQuery improvements, CRUD with SQL Expr and Context Valuer
* Full self-reference relationships support, Join Table improvements, Association Mode for batch data
* Multiple fields allowed to track create/update time, UNIX (milli/nano) seconds supports
* Field permissions support: read-only, write-only, create-only, update-only, ignored
* New plugin system, provides official plugins for multiple databases, read/write splitting, prometheus integrations...
* New Hooks API: unified interface with plugins
* New Migrator: allows to create database foreign keys for relationships, smarter AutoMigrate, constraints/checker support, enhanced index support
* New Logger: context support, improved extensibility
* Unified Naming strategy: table name, field name, join table name, foreign key, checker, index name rules
* Better customized data type support (e.g: JSON)

## Как обновить

* GORM's developments moved to [github.com/go-gorm](https://github.com/go-gorm), and its import path changed to `gorm.io/gorm`, for previous projects, you can keep using `github.com/jinzhu/gorm` [GORM V1 Document](http://v1.gorm.io/)
* Database drivers have been split into separate projects, e.g: [github.com/go-gorm/sqlite](https://github.com/go-gorm/sqlite), and its import path also changed to `gorm.io/driver/sqlite`

### Установка

```go
go get gorm.io/gorm
// **ПРИМЕЧАНИЕ** GORM `v2.0.0` релиз выложен с тегом `v1.20.0`
```

### Быстрый старт

```go
import (
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
)

func init() {
  db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})

  // Most CRUD API kept compatibility
  db.AutoMigrate(&Product{})
  db.Create(&user)
  db.First(&user, 1)
  db.Model(&user).Update("Age", 18)
  db.Model(&user).Omit("Role").Updates(map[string]interface{}{"Name": "jinzhu", "Role": "admin"})
  db.Delete(&user)
}
```

## Основные возможности

Примечание к выпуску содержит только основные изменения, внесенные в GORM V2 в качестве краткого справочного списка

#### Поддержка контекста

* Операции с БД поддерживают `context.Context` при помощи метода `WithContext`
* Logger также принимает контекст для отслеживания

```go
DB.WithContext(ctx).Find(&users)
```

#### Пакетная вставка

* Use slice data with `Create` will generate a single SQL statement to insert all the data and backfill primary key values
* If those data contain associations, all associations will be upserted with another SQL
* Batch inserted data will call its `Hooks` methods (Before/After Create/Save)

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
DB.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

#### Подготовленный подготовленного Statment

Prepared Statement Mode creates prepared stmt and caches them to speed up future calls

```go
// глобальный режим, все операции будут создавать подготовленный stmt и кешировать для ускорения
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{PrepareStmt: true})

// сессионный режим, создает подготовленный stmt и ускоряет работу текущей сессии
tx := DB.Session(&Session{PrepareStmt: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)
```

#### Режим DryRun

Generates SQL without executing, can be used to check or test generated SQL

```go
stmt := DB.Session(&Session{DryRun: true}).Find(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 // PostgreSQL
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = ?  // MySQL
stmt.Vars         //=> []interface{}{1}
```

#### Join с предварительной загрузкой

Preload associations using INNER JOIN, and will handle null data to avoid failing to scan

```go
DB.Joins("Company").Joins("Manager").Joins("Account").Find(&users, "users.id IN ?", []int{1,2})
```

#### Поиск в Map

Сканировать результат в `map[string]interface{}` или `[]map[string]interface{}`

```go
var result map[string]interface{}
DB.Model(&User{}).First(&result, "id = ?", 1)
```

#### Создать из Map

Create from map `map[string]interface{}` or `[]map[string]interface{}`

```go
DB.Model(&User{}).Create(map[string]interface{}{"Name": "jinzhu", "Age": 18})

datas := []map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 19},
  {"name": "jinzhu_2", "Age": 20},
}

DB.Model(&User{}).Create(datas)
```

#### Найти в пакете(FindInBatches)

Query and process records in batch

```go
result := DB.Where("age>?", 13).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  // пакетная обработка
  return nil
})
```

#### Вложенные транзакции

```go
DB.Transaction(func(tx *gorm.DB) error {
  tx.Create(&user1)

  tx.Transaction(func(tx2 *gorm.DB) error {
    tx.Create(&user2)
    return errors.New("rollback user2") // rollback user2
  })

  tx.Transaction(func(tx2 *gorm.DB) error {
    tx.Create(&user3)
    return nil
  })

  return nil // commit user1 и user3
})
```

#### SavePoint, RollbackTo

```go
tx := DB.Begin()
tx.Create(&user1)

tx.SavePoint("sp1")
tx.Create(&user2)
tx.RollbackTo("sp1") // rollback user2

tx.Commit() // commit user1
```

#### Именованные аргументы

GORM supports use `sql.NamedArg`, `map[string]interface{}` as named arguments

```go
DB.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

DB.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu2"}).First(&result3)
// SELECT * FROM `users` WHERE name1 = "jinzhu2" OR name2 = "jinzhu2" ORDER BY `users`.`id` LIMIT 1

DB.Raw(
  "SELECT * FROM users WHERE name1 = @name OR name2 = @name2 OR name3 = @name",
  sql.Named("name", "jinzhu1"), sql.Named("name2", "jinzhu2"),
).Find(&user)
// SELECT * FROM users WHERE name1 = "jinzhu1" OR name2 = "jinzhu2" OR name3 = "jinzhu1"

DB.Exec(
  "UPDATE users SET name1 = @name, name2 = @name2, name3 = @name",
  map[string]interface{}{"name": "jinzhu", "name2": "jinzhu2"},
)
// UPDATE users SET name1 = "jinzhu", name2 = "jinzhu2", name3 = "jinzhu"
```

#### Группировка условий

```go
db.Where(
  db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
  db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&pizzas)

// SELECT * FROM pizzas WHERE (pizza = 'pepperoni' AND (size = 'small' OR size = 'medium')) OR (pizza = 'hawaiian' AND size = 'xlarge')
```

#### Под Запрос

```go
// Where SubQuery
db.Where("amount > ?", db.Table("orders").Select("AVG(amount)")).Find(&orders)

// From SubQuery
db.Table("(?) as u", DB.Model(&User{}).Select("name", "age")).Where("age = ?", 18}).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE age = 18

// Update SubQuery
DB.Model(&user).Update(
  "price", DB.Model(&Company{}).Select("name").Where("companies.id = users.company_id"),
)
```

#### Upsert (обновить или создать)

`clause.OnConflict` provides compatible Upsert support for different databases (SQLite, MySQL, PostgreSQL, SQL Server)

```go
import "gorm.io/gorm/clause"

DB.Clauses(clause.OnConflict{DoNothing: true}).Create(&users)

DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"name": "jinzhu", "age": 18}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE name="jinzhu", age=18; MySQL

DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age=VALUES(age); MySQL
```

#### Блокировка

```go
DB.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

DB.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`
```

#### Optimizer/Index/Comment Hints

```go
import "gorm.io/hints"

// Optimizer Hints
DB.Clauses(hints.New("hint")).Find(&User{})
// SELECT * /*+ hint */ FROM `users`

// Index Hints
DB.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

// Comment Hints
DB.Clauses(hints.Comment("select", "master")).Find(&User{})
// SELECT /*master*/ * FROM `users`;
```

Check out [Hints](hints.html) for details

#### CRUD из SQL Expr/Context Valuer

```go
type Location struct {
    X, Y int
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

DB.Create(&User{
  Name:     "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// INSERT INTO `users` (`name`,`point`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"))

DB.Model(&User{ID: 1}).Updates(User{
  Name:  "jinzhu",
  Point: Point{X: 100, Y: 100},
})
// UPDATE `user_with_points` SET `name`="jinzhu",`point`=ST_PointFromText("POINT(100 100)") WHERE `id` = 1
```

Смотрите [Настраиваемые типы данных](data_types.html#gorm_valuer_interface) для подробностей

#### Права доступа к полю

Поддержка прав доступа полей, уровни доступа: только для чтения, только для записи, только для создания, только для обновления, игнорируется

```go
type User struct {
  Name string `gorm:"<-:create"` // разрешить читать и создавать
  Name string `gorm:"<-:update"` // разрешить читать и обновлять
  Name string `gorm:"<-"`        // разрешить читать и записывать (создавать и обновлять)
  Name string `gorm:"->:false;<-:create"` // только создание
  Name string `gorm:"->"` // только чтение
  Name string `gorm:"-"`  // игнорируется
}
```

#### Отслеживать создание/обновление времени/unix (мили/нано) секунд для нескольких полей

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updaing or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix Nano seconds as updating time
  Updated2  int64 `gorm:"autoUpdateTime:milli"` // Use unix Milli seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

#### Множественные базы данных, разделение чтения/записи

GORM provides multiple databases, read/write splitting support with plugin `DB Resolver`, which also supports auto-switching database/table based on current struct/table, and multiple sources、replicas supports with customized load-balancing logic

Check out [Database Resolver](dbresolver.html) for details

#### Prometheus

GORM provides plugin `Prometheus` to collect `DBStats` and user-defined metrics

Check out [Prometheus](prometheus.html) for details

#### Cтратегия именования

GORM allows users change the default naming conventions by overriding the default `NamingStrategy`, which is used to build `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`, Check out [GORM Config](gorm_config.html) for details

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NamingStrategy: schema.NamingStrategy{TablePrefix: "t_", SingularTable: true},
})
```

#### Logger

* Context support
* Customize/turn off the colors in the log
* Slow SQL log, default slow SQL time is 100ms
* Optimized the SQL log format so that it can be copied and executed in a database console

#### Режим транзакции

By default, all GORM write operations run inside a transaction to ensure data consistency, you can disable it during initialization to speed up write operations if it is not required

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

#### Типы данных (JSON в качестве примера)

GORM optimizes support for custom types, so you can define a struct to support all databases

The following takes JSON as an example (which supports SQLite, MySQL, Postgres, refer: https://github.com/go-gorm/datatypes/blob/master/json.go)

```go
import "gorm.io/datatypes"

type User struct {
  gorm.Model
  Name       string
  Attributes datatypes.JSON
}

DB.Create(&User{
  Name:       "jinzhu",
  Attributes: datatypes.JSON([]byte(`{"name": "jinzhu", "age": 18, "tags": ["tag1", "tag2"], "orgs": {"orga": "orga"}}`)),
}

// Query user having a role field in attributes
DB.First(&user, datatypes.JSONQuery("attributes").HasKey("role"))
// Query user having orgs->orga field in attributes
DB.First(&user, datatypes.JSONQuery("attributes").HasKey("orgs", "orga"))
```

#### Умный выбор

GORM allows select specific fields with [`Select`](query.html), and in V2, GORM provides smart select mode if you are querying with a smaller struct

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // hundreds of fields
}

type APIUser struct {
  ID   uint
  Name string
}

// Select `id`, `name` automatically when query
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

#### Пакетный режим связей

Association Mode supports batch data, e.g:

```go
// Find all roles for all users
db.Model(&users).Association("Role").Find(&roles)

// Delete User A from all users's team
db.Model(&users).Association("Team").Delete(&userA)

// Get unduplicated count of members in all user's team
db.Model(&users).Association("Team").Count()

// For `Append`, `Replace` with batch data, arguments's length need to equal to data's length or will returns error
var users = []User{user1, user2, user3}
// e.g: we have 3 users, Append userA to user1's team, append userB to user2's team, append userA, userB and userC to user3's team
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Reset user1's team to userA，reset user2's team to userB, reset user3's team to userA, userB and userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## Критические изменения

We are trying to list big breaking changes or those changes can't be caught by the compilers, please create an issue or pull request [here](https://github.com/go-gorm/gorm.io) if you found any unlisted breaking changes

#### Теги

* GORM V2 prefer write tag name in `camelCase`, tags in `snake_case` won't works anymore, for example: `auto_increment`, `unique_index`, `polymorphic_value`, `embedded_prefix`, check out [Model Tags](models.html#tags)
* Tags used to specify foreign keys changed to `foreignKey`, `references`, check out [Associations Tags](associations.html#tags)

#### Название таблицы

`TableName` will *not* allow dynamic table name anymore, the result of `TableName` will be cached for future

```go
func (User) TableName() string {
  return "t_user"
}
```

Please use `Scopes` for dynamic tables, for example:

```go
func UserTable(u *User) func(*gorm.DB) *gorm.DB {
  return func(db *gorm.DB) *gorm.DB {
    return db.Table("user_" + u.Role)
  }
}

DB.Scopes(UserTable(&user)).Create(&user)
```

#### Method Chain Safety/Goroutine Safety

To reduce GC allocs, GORM V2 will share `Statement` when using method chains, and will only create new `Statement` instances for new initialized `*gorm.DB` or after a `New Session Method`, to reuse a `*gorm.DB`, you need to make sure it just after a `New Session Method`, for example:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

// Safe for new initialized *gorm.DB
for i := 0; i < 100; i++ {
  go db.Where(...).First(&user)
}

tx := db.Where("name = ?", "jinzhu")
// NOT Safe as reusing Statement
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user)
}

ctxDB := db.WithContext(ctx)
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user)
}

ctxDB := db.Where("name = ?", "jinzhu").WithContext(ctx)
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user) // `name = 'jinzhu'` будет добавлено в запрос
}

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{WithConditions: true})
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user) // `name = 'jinzhu'` будет добавлено в запрос
}
```

Check out [Method Chain](method_chaining.html) for details

#### Значение по умолчанию

GORM V2 won't auto-reload default values created with database function after creating, checkout [Default Values](create.html#default_values) for details

#### Мягкое удаление

GORM V1 will enable soft delete if the model has a field named `DeletedAt`, in V2, you need to use `gorm.DeletedAt` for the model wants to enable the feature, e.g:

```go
type User struct {
  ID        uint
  DeletedAt gorm.DeletedAt
}

type User struct {
  ID      uint
  // поле с другим названием
  Deleted gorm.DeletedAt
}
```

{% note warn %}
**NOTE:** `gorm.Model` is using `gorm.DeletedAt`, if you are embedding it, nothing needs to change
{% endnote %}

#### BlockGlobalUpdate

GORM V2 enabled `BlockGlobalUpdate` mode by default, to trigger a global update/delete, you have to use some conditions or use raw SQL or enable `AllowGlobalUpdate` mode, for example:

```go
DB.Where("1 = 1").Delete(&User{})

DB.Raw("delete from users")

DB.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
```

#### ErrRecordNotFound

GORM V2 only returns `ErrRecordNotFound` when you are querying with methods `First`, `Last`, `Take` which is expected to return some result, and we have also removed method `RecordNotFound` in V2, please use `errors.Is` to check the error, e.g:

```go
err := DB.First(&user).Error
errors.Is(err, gorm.ErrRecordNotFound)
```

#### Hooks Method

Before/After Create/Update/Save/Find/Delete must be defined as a method of type `func(tx *gorm.DB) error` in V2, which has unified interfaces like plugin callbacks, if defined as other types, a warning log will be printed and it won't take effect, check out [Hooks](hooks.html) for details

```go
func (u *User) BeforeCreate(tx *gorm.DB) error {
  // Изменить текущую операцию через tx.Statement, например:
  tx.Statement.Select("Name", "Age")
  tx.Statement.AddClause(clause.OnConflict{DoNothing: true})

  // операции на основе tx будут выполняться внутри той же транзакции, но без каких-либо текущих условий
  var role Role
  err := tx.First(&role, "name = ?", user.Role).Error
  // SELECT * FROM roles WHERE name = "admin"
}
```

#### Update Hooks support `Changed` to check fields changed or not

When updating with `Update`, `Updates`, You can use `Changed` method in Hooks `BeforeUpdate`, `BeforeSave` to check a field changed or not

```go
func (user *User) BeforeUpdate(tx *gorm.DB) error {
  if tx.Statement.Changed("Name", "Admin") { // Если изменились Name или Admin
    tx.Statement.SetColumn("Age", 18)
  }

  if tx.Statement.Changed() { // если изменилось любое поле
    tx.Statement.SetColumn("Age", 18)
  }
  return nil
}

DB.Model(&user).Update("Name", "Jinzhu") // обновит поле `Name` в `Jinzhu`
DB.Model(&user).Updates(map[string]interface{}{"name": "Jinzhu", "admin": false}) // обновит поле `Name` в `Jinzhu`, `Admin` в false
DB.Model(&user).Updates(User{Name: "Jinzhu", Admin: false}) // обновит не нелевые поля при использовании struct в качестве аргумента, оновит только `Name` в `Jinzhu`

DB.Model(&user).Select("Name", "Admin").Updates(User{Name: "Jinzhu"}) // обновит выбранные поля `Name`, `Admin`，`Admin` будет обновлен в нулевое значение (false)
DB.Model(&user).Select("Name", "Admin").Updates(map[string]interface{}{"Name": "Jinzhu"}) // обновит выбранные поля и существующие в map, обновит только `Name` в `Jinzhu`

// Внимание: `Changed` будет проверять только равено ли значение в `Update` / `Updates` и поле модели `Model`, вернет true еслин не равнои поле будет сохранено
DB.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu2"}) // Changed("Name") => true
DB.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu"}) // Changed("Name") => false, `Name` не изменено
DB.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(map[string]interface{"name": "jinzhu2", "admin": false}) // Changed("Name") => false, `Name` не выбрано для обновления

DB.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu2"}) // Changed("Name") => true
DB.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu"})  // Changed("Name") => false, `Name` не изменено
DB.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(User{Name: "jinzhu2"}) // Changed("Name") => false, `Name` не выбрано для обновления
```

#### Плагины

Plugin callbacks also need be defined as a method of type `func(tx *gorm.DB) error`, check out [Write Plugins](write_plugins.html) for details

#### Обновление с struct

When updating with struct, GORM V2 allows to use `Select` to select zero-value fields to update them, for example:

```go
DB.Model(&user).Select("Role", "Age").Update(User{Name: "jinzhu", Role: "", Age: 0})
```

#### Связи

GORM V1 allows to use some settings to skip create/update associations, in V2, you can use `Select` to do the job, for example:

```go
DB.Omit(clause.Associations).Create(&user)
DB.Omit(clause.Associations).Save(&user)

DB.Select("Company").Save(&user)
```

and GORM V2 doesn't allow preload with `Set("gorm:auto_preload", true)` anymore, you can use `Preload` with `clause.Associations`, e.g:

```go
// предзагрузка всех связей
db.Preload(clause.Associations).Find(&users)
```

Also, checkout field permissions, which can be used to skip creating/updating associations globally

#### Join таблицы

In GORM V2, a `JoinTable` can be a full-featured model, with features like `Soft Delete`，`Hooks`, and define other fields, e.g:

```go
type Person struct {
  ID        int
  Name      string
  Addresses []Address `gorm:"many2many:person_addresses;"`
}

type Address struct {
  ID   uint
  Name string
}

type PersonAddress struct {
  PersonID  int
  AddressID int
  CreatedAt time.Time
  DeletedAt gorm.DeletedAt
}

func (PersonAddress) BeforeCreate(db *gorm.DB) error {
  // ...
}

// В PersonAddress должны быть определены все внешние ключи, или выбросит ошибку
err := DB.SetupJoinTable(&Person{}, "Addresses", &PersonAddress{})
```

#### Count

Count принимает только `*int64` в качестве аргумента

#### Transactions

some transaction methods like `RollbackUnlessCommitted` removed, prefer to use method `Transaction` to wrap your transactions

```go
db.Transaction(func(tx *gorm.DB) error {
  // do some database operations in the transaction (use 'tx' from this point, not 'db')
  if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
    // return any error will rollback
    return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
    return err
  }

  // return nil will commit the whole transaction
  return nil
})
```

Checkout [Transactions](transactions.html) for details

#### Migrator

* Migrator will create database foreign keys by default
* Migrator is more independent, many API renamed to provide better support for each database with unified API interfaces
* AutoMigrate will alter column's type if its size, precision, nullable changed
* Support Checker through tag `check`
* Enhanced tag setting for `index`

Checkout [Migration](migration.html) for details

```go
type UserIndex struct {
  Name  string `gorm:"check:named_checker,(name <> 'jinzhu')"`
  Name2 string `gorm:"check:(age > 13)"`
  Name4 string `gorm:"index"`
  Name5 string `gorm:"index:idx_name,unique"`
  Name6 string `gorm:"index:,sort:desc,collate:utf8,type:btree,length:10,where:name3 != 'jinzhu'"`
}
```

## Happy Hacking!

<style>
li.toc-item { list-style: none; }
li.toc-item.toc-level-4 { display: none; }
</style>
