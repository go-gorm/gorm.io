---
title: GORM 2.0 Release Note
layout: page
---

GORM 2.0 is a rewrite from scratch, it introduces some incompatible-API change and many improvements

**Highlights**

* Performance Improvements
* Modularity
* Context, Batch Insert, Prepared Statement Mode, DryRun Mode, Join Preload, Find To Map, Create From Map, FindInBatches supports
* Nested Transaction/SavePoint/RollbackTo SavePoint supports
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

## How To Upgrade

* GORM's developments moved to [github.com/go-gorm](https://github.com/go-gorm), and its import path changed to `gorm.io/gorm`, for previous projects, you can keep using `github.com/jinzhu/gorm` [GORM V1 Document](http://v1.gorm.io/)
* Database drivers have been split into separate projects, e.g: [github.com/go-gorm/sqlite](https://github.com/go-gorm/sqlite), and its import path also changed to `gorm.io/driver/sqlite`

### Install

```go
go get gorm.io/gorm
// **NOTE** GORM `v2.0.0` released with git tag `v1.20.0`
```

### Quick Start

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

## Major Features

The release note only cover major changes introduced in GORM V2 as a quick reference list

#### Context Support

* Database operations support `context.Context` with the `WithContext` method
* Logger also accepts context for tracing

```go
db.WithContext(ctx).Find(&users)
```

#### Batch Insert

To efficiently insert large number of records, pass a slice to the `Create` method. GORM will generate a single SQL statement to insert all the data and backfill primary key values, hook methods will be invoked too.

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

You can specify batch size when creating with `CreateInBatches`, e.g:

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// batch size 100
db.CreateInBatches(users, 100)
```

#### Prepared Statement Mode

Prepared Statement Mode creates prepared stmt and caches them to speed up future calls

```go
// globally mode, all operations will create prepared stmt and cache to speed up
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{PrepareStmt: true})

// session mode, create prepares stmt and speed up current session operations
tx := db.Session(&Session{PrepareStmt: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)
```

#### DryRun Mode

Generates SQL without executing, can be used to check or test generated SQL

```go
stmt := db.Session(&Session{DryRun: true}).Find(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 // PostgreSQL
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = ?  // MySQL
stmt.Vars         //=> []interface{}{1}
```

#### Join Preload

Preload associations using INNER JOIN, and will handle null data to avoid failing to scan

```go
db.Joins("Company").Joins("Manager").Joins("Account").Find(&users, "users.id IN ?", []int{1,2})
```

#### Find To Map

Scan result to `map[string]interface{}` or `[]map[string]interface{}`

```go
var result map[string]interface{}
db.Model(&User{}).First(&result, "id = ?", 1)
```

#### Create From Map

Create from map `map[string]interface{}` or `[]map[string]interface{}`

```go
db.Model(&User{}).Create(map[string]interface{}{"Name": "jinzhu", "Age": 18})

datas := []map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 19},
  {"name": "jinzhu_2", "Age": 20},
}

db.Model(&User{}).Create(datas)
```

#### FindInBatches

Query and process records in batch

```go
result := db.Where("age>?", 13).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  // batch processing
  return nil
})
```

#### Nested Transaction

```go
db.Transaction(func(tx *gorm.DB) error {
  tx.Create(&user1)

  tx.Transaction(func(tx2 *gorm.DB) error {
    tx.Create(&user2)
    return errors.New("rollback user2") // rollback user2
  })

  tx.Transaction(func(tx2 *gorm.DB) error {
    tx.Create(&user3)
    return nil
  })

  return nil // commit user1 and user3
})
```

#### SavePoint, RollbackTo

```go
tx := db.Begin()
tx.Create(&user1)

tx.SavePoint("sp1")
tx.Create(&user2)
tx.RollbackTo("sp1") // rollback user2

tx.Commit() // commit user1
```

#### Named Argument

GORM supports use `sql.NamedArg`, `map[string]interface{}` as named arguments

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu2"}).First(&result3)
// SELECT * FROM `users` WHERE name1 = "jinzhu2" OR name2 = "jinzhu2" ORDER BY `users`.`id` LIMIT 1

db.Raw(
  "SELECT * FROM users WHERE name1 = @name OR name2 = @name2 OR name3 = @name",
  sql.Named("name", "jinzhu1"), sql.Named("name2", "jinzhu2"),
).Find(&user)
// SELECT * FROM users WHERE name1 = "jinzhu1" OR name2 = "jinzhu2" OR name3 = "jinzhu1"

db.Exec(
  "UPDATE users SET name1 = @name, name2 = @name2, name3 = @name",
  map[string]interface{}{"name": "jinzhu", "name2": "jinzhu2"},
)
// UPDATE users SET name1 = "jinzhu", name2 = "jinzhu2", name3 = "jinzhu"
```

#### Group Conditions

```go
db.Where(
  db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
  db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&pizzas)

// SELECT * FROM pizzas WHERE (pizza = 'pepperoni' AND (size = 'small' OR size = 'medium')) OR (pizza = 'hawaiian' AND size = 'xlarge')
```

#### SubQuery

```go
// Where SubQuery
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)

// From SubQuery
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE age = 18

// Update SubQuery
db.Model(&user).Update(
  "price", db.Model(&Company{}).Select("name").Where("companies.id = users.company_id"),
)
```

#### Upsert

`clause.OnConflict` provides compatible Upsert support for different databases (SQLite, MySQL, PostgreSQL, SQL Server)

```go
import "gorm.io/gorm/clause"

db.Clauses(clause.OnConflict{DoNothing: true}).Create(&users)

db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"name": "jinzhu", "age": 18}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE name="jinzhu", age=18; MySQL

db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age=VALUES(age); MySQL
```

#### Locking

```go
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`
```

#### Optimizer/Index/Comment Hints

```go
import "gorm.io/hints"

// Optimizer Hints
db.Clauses(hints.New("hint")).Find(&User{})
// SELECT * /*+ hint */ FROM `users`

// Index Hints
db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

// Comment Hints
db.Clauses(hints.Comment("select", "master")).Find(&User{})
// SELECT /*master*/ * FROM `users`;
```

Check out [Hints](hints.html) for details

#### CRUD From SQL Expr/Context Valuer

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

db.Create(&User{
  Name:     "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// INSERT INTO `users` (`name`,`point`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"))

db.Model(&User{ID: 1}).Updates(User{
  Name:  "jinzhu",
  Point: Point{X: 100, Y: 100},
})
// UPDATE `user_with_points` SET `name`="jinzhu",`point`=ST_PointFromText("POINT(100 100)") WHERE `id` = 1
```

Check out [Customize Data Types](data_types.html#gorm_valuer_interface) for details

#### Field permissions

Field permissions support, permission levels: read-only, write-only, create-only, update-only, ignored

```go
type User struct {
  Name string `gorm:"<-:create"` // allow read and create
  Name string `gorm:"<-:update"` // allow read and update
  Name string `gorm:"<-"`        // allow read and write (create and update)
  Name string `gorm:"->:false;<-:create"` // createonly
  Name string `gorm:"->"` // readonly
  Name string `gorm:"-"`  // ignored
}
```

#### Track creating/updating time/unix (milli/nano) seconds for multiple fields

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updaing or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix Nano seconds as updating time
  Updated2  int64 `gorm:"autoUpdateTime:milli"` // Use unix Milli seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

#### Multiple Databases, Read/Write Splitting

GORM provides multiple databases, read/write splitting support with plugin `DB Resolver`, which also supports auto-switching database/table based on current struct/table, and multiple sources、replicas supports with customized load-balancing logic

Check out [Database Resolver](dbresolver.html) for details

#### Prometheus

GORM provides plugin `Prometheus` to collect `DBStats` and user-defined metrics

Check out [Prometheus](prometheus.html) for details

#### Naming Strategy

GORM allows users change the default naming conventions by overriding the default `NamingStrategy`, which is used to build `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`, Check out [GORM Config](gorm_config.html) for details

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NamingStrategy: schema.NamingStrategy{TablePrefix: "t_", SingularTable: true},
})
```

#### Logger

* Context support
* Customize/turn off the colors in the log
* Slow SQL log, default slow SQL time is 200ms
* Optimized the SQL log format so that it can be copied and executed in a database console

#### Transaction Mode

By default, all GORM write operations run inside a transaction to ensure data consistency, you can disable it during initialization to speed up write operations if it is not required

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

#### DataTypes (JSON as example)

GORM optimizes support for custom types, so you can define a struct to support all databases

The following takes JSON as an example (which supports SQLite, MySQL, Postgres, refer: https://github.com/go-gorm/datatypes/blob/master/json.go)

```go
import "gorm.io/datatypes"

type User struct {
  gorm.Model
  Name       string
  Attributes datatypes.JSON
}

db.Create(&User{
  Name:       "jinzhu",
  Attributes: datatypes.JSON([]byte(`{"name": "jinzhu", "age": 18, "tags": ["tag1", "tag2"], "orgs": {"orga": "orga"}}`)),
}

// Query user having a role field in attributes
db.First(&user, datatypes.JSONQuery("attributes").HasKey("role"))
// Query user having orgs->orga field in attributes
db.First(&user, datatypes.JSONQuery("attributes").HasKey("orgs", "orga"))
```

#### Smart Select

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

#### Associations Batch Mode

Association Mode supports batch data, e.g:

```go
// Find all roles for all users
db.Model(&users).Association("Role").Find(&roles)

// Delete User A from all user's team
db.Model(&users).Association("Team").Delete(&userA)

// Get unduplicated count of members in all user's team
db.Model(&users).Association("Team").Count()

// For `Append`, `Replace` with batch data, argument's length need to equal to data's length or will returns error
var users = []User{user1, user2, user3}
// e.g: we have 3 users, Append userA to user1's team, append userB to user2's team, append userA, userB and userC to user3's team
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Reset user1's team to userA，reset user2's team to userB, reset user3's team to userA, userB and userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

#### Delete Associations when deleting

You are allowed to delete selected has one/has many/many2many relations with `Select` when deleting records, for example:

```go
// delete user's account when deleting user
db.Select("Account").Delete(&user)

// delete user's Orders, CreditCards relations when deleting user
db.Select("Orders", "CreditCards").Delete(&user)

// delete user's has one/many/many2many relations when deleting user
db.Select(clause.Associations).Delete(&user)

// delete user's account when deleting users
db.Select("Account").Delete(&users)
```

## Breaking Changes

We are trying to list big breaking changes or those changes can't be caught by the compilers, please create an issue or pull request [here](https://github.com/go-gorm/gorm.io) if you found any unlisted breaking changes

#### Tags

* GORM V2 prefer write tag name in `camelCase`, tags in `snake_case` won't works anymore, for example: `auto_increment`, `unique_index`, `polymorphic_value`, `embedded_prefix`, check out [Model Tags](models.html#tags)
* Tags used to specify foreign keys changed to `foreignKey`, `references`, check out [Associations Tags](associations.html#tags)
* Not support `sql` tag

#### Table Name

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

db.Scopes(UserTable(&user)).Create(&user)
```

#### Creating and Deleting Tables requires the use of the Migrator

Previously tables could be created and dropped as follows:

```go
db.CreateTable(&MyTable{})
db.DropTable(&MyTable{})
```

Now you do the following:

```go
db.Migrator().CreateTable(&MyTable{})
db.Migrator().DropTable(&MyTable{})
```

#### Foreign Keys

A way of adding foreign key constraints was;

```go
db.Model(&MyTable{}).AddForeignKey("profile_id", "profiles(id)", "NO ACTION", "NO ACTION")
```

Now you add constraints as follows:

```go
db.Migrator().CreateConstraint(&Users{}), "Profiles")
db.Migrator().CreateConstraint(&Users{}), "fk_users_profiles")
```

which translates to the following sql code for postgres:

```sql
ALTER TABLE `Profiles` ADD CONSTRAINT `fk_users_profiles` FORIEGN KEY (`useres_id`) REFRENCES `users`(`id`))
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
  go ctxDB.Where(...).First(&user) // `name = 'jinzhu'` will apply to the query
}

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{})
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user) // `name = 'jinzhu'` will apply to the query
}
```

Check out [Method Chain](method_chaining.html) for details

#### Default Value

GORM V2 won't auto-reload default values created with database function after creating, checkout [Default Values](create.html#default_values) for details

#### Soft Delete

GORM V1 will enable soft delete if the model has a field named `DeletedAt`, in V2, you need to use `gorm.DeletedAt` for the model wants to enable the feature, e.g:

```go
type User struct {
  ID        uint
  DeletedAt gorm.DeletedAt
}

type User struct {
  ID      uint
  // field with different name
  Deleted gorm.DeletedAt
}
```

{% note warn %}
**NOTE:** `gorm.Model` is using `gorm.DeletedAt`, if you are embedding it, nothing needs to change
{% endnote %}

#### BlockGlobalUpdate

GORM V2 enabled `BlockGlobalUpdate` mode by default, to trigger a global update/delete, you have to use some conditions or use raw SQL or enable `AllowGlobalUpdate` mode, for example:

```go
db.Where("1 = 1").Delete(&User{})

db.Raw("delete from users")

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
```

#### ErrRecordNotFound

GORM V2 only returns `ErrRecordNotFound` when you are querying with methods `First`, `Last`, `Take` which is expected to return some result, and we have also removed method `RecordNotFound` in V2, please use `errors.Is` to check the error, e.g:

```go
err := db.First(&user).Error
errors.Is(err, gorm.ErrRecordNotFound)
```

#### Hooks Method

Before/After Create/Update/Save/Find/Delete must be defined as a method of type `func(tx *gorm.DB) error` in V2, which has unified interfaces like plugin callbacks, if defined as other types, a warning log will be printed and it won't take effect, check out [Hooks](hooks.html) for details

```go
func (user *User) BeforeCreate(tx *gorm.DB) error {
  // Modify current operation through tx.Statement, e.g:
  tx.Statement.Select("Name", "Age")
  tx.Statement.AddClause(clause.OnConflict{DoNothing: true})

  // Operations based on tx will runs inside same transaction without clauses of current one
  var role Role
  err := tx.First(&role, "name = ?", user.Role).Error
  // SELECT * FROM roles WHERE name = "admin"
  return err
}
```

#### Update Hooks support `Changed` to check fields changed or not

When updating with `Update`, `Updates`, You can use `Changed` method in Hooks `BeforeUpdate`, `BeforeSave` to check a field changed or not

```go
func (user *User) BeforeUpdate(tx *gorm.DB) error {
  if tx.Statement.Changed("Name", "Admin") { // if Name or Admin changed
    tx.Statement.SetColumn("Age", 18)
  }

  if tx.Statement.Changed() { // if any fields changed
    tx.Statement.SetColumn("Age", 18)
  }
  return nil
}

db.Model(&user).Update("Name", "Jinzhu") // update field `Name` to `Jinzhu`
db.Model(&user).Updates(map[string]interface{}{"name": "Jinzhu", "admin": false}) // update field `Name` to `Jinzhu`, `Admin` to false
db.Model(&user).Updates(User{Name: "Jinzhu", Admin: false}) // Update none zero fields when using struct as argument, will only update `Name` to `Jinzhu`

db.Model(&user).Select("Name", "Admin").Updates(User{Name: "Jinzhu"}) // update selected fields `Name`, `Admin`，`Admin` will be updated to zero value (false)
db.Model(&user).Select("Name", "Admin").Updates(map[string]interface{}{"Name": "Jinzhu"}) // update selected fields exists in the map, will only update field `Name` to `Jinzhu`

// Attention: `Changed` will only check the field value of `Update` / `Updates` equals `Model`'s field value, it returns true if not equal and the field will be saved
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu2"}) // Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu"}) // Changed("Name") => false, `Name` not changed
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(map[string]interface{"name": "jinzhu2", "admin": false}) // Changed("Name") => false, `Name` not selected to update

db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu2"}) // Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu"})  // Changed("Name") => false, `Name` not changed
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(User{Name: "jinzhu2"}) // Changed("Name") => false, `Name` not selected to update
```

#### Plugins

Plugin callbacks also need be defined as a method of type `func(tx *gorm.DB) error`, check out [Write Plugins](write_plugins.html) for details

#### Updating with struct

When updating with struct, GORM V2 allows to use `Select` to select zero-value fields to update them, for example:

```go
db.Model(&user).Select("Role", "Age").Update(User{Name: "jinzhu", Role: "", Age: 0})
```

#### Associations

GORM V1 allows to use some settings to skip create/update associations, in V2, you can use `Select` to do the job, for example:

```go
db.Omit(clause.Associations).Create(&user)
db.Omit(clause.Associations).Save(&user)

db.Select("Company").Save(&user)
```

and GORM V2 doesn't allow preload with `Set("gorm:auto_preload", true)` anymore, you can use `Preload` with `clause.Associations`, e.g:

```go
// preload all associations
db.Preload(clause.Associations).Find(&users)
```

Also, checkout field permissions, which can be used to skip creating/updating associations globally

GORM V2 will use upsert to save associations when creating/updating a record, won't save full associations data anymore to protect your data from saving uncompleted data, for example:

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db.Create(&user)
// BEGIN TRANSACTION;
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "languages" ("name") VALUES ('ZH'), ('EN') ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "user_languages" ("user_id","language_id") VALUES (111, 1), (111, 2) ON DUPLICATE KEY DO NOTHING;
// COMMIT;
  ```

#### Join Table

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

// PersonAddress must defined all required foreign keys, or it will raise error
err := db.SetupJoinTable(&Person{}, "Addresses", &PersonAddress{})
```

After that, you could use normal GORM methods to operate the join table data, for example:

```go
var results []PersonAddress
db.Where("person_id = ?", person.ID).Find(&results)

db.Where("address_id = ?", address.ID).Delete(&PersonAddress{})

db.Create(&PersonAddress{PersonID: person.ID, AddressID: address.ID})
```

#### Count

Count only accepts `*int64` as the argument

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
