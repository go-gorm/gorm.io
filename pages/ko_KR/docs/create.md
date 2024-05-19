---
title: 생성
layout: page
---

## 레코드 생성

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

result := db.Create(&user) // 생성할 데이터의 포인터 넘기기

user.ID             // 입력된 데이터의 primary key를 반환합니다
result.Error        // 에러를 반환합니다
result.RowsAffected // 입력된 레코드의 개수를 반환합니다.
```

`Create()` 함수를 통해 여러 레코드를 동시에 생성할수도 있습니다.
```go
users := []*User{
    {Name: "Jinzhu", Age: 18, Birthday: time.Now()},
    {Name: "Jackson", Age: 19, Birthday: time.Now()},
}

result := db.Create(users) // 레코드들이 들어갈 슬라이스를 넣어줍니다.

result.Error        // 에러를 반환합니다. 
result.RowsAffected // 슬라이스에 삽입된 레코드의 숫자를 반환합니다.
```

{% note warn %}
**주의할점** 구조체를 직접 'create' 함수에 넣지 마세요, 대신 포인터를 넣어주세요.
{% endnote %}

## 선택한 필드로 레코드 만들기

Create a record and assign a value to the fields specified.

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

Create a record and ignore the values for fields passed to omit.

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## <span id="batch_insert">Batch Insert</span>

많은 레코드를 만들기 위해서, slice를 `Create` 메소드에 넣어주세요. GORM will generate a single SQL statement to insert all the data and backfill primary key values, hook methods will be invoked too. It will begin a **transaction** when records can be split into multiple batches.

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

Batch Insert is also supported when using [Upsert](#upsert) and [Create With Associations](#create_with_associations)

{% note warn %}
**NOTE** initialize GORM with `CreateBatchSize` option, all `INSERT` will respect this option when creating record & associations
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

## Hooks 생성하기

GORM allows user defined hooks to be implemented for `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate`.  These hook method will be called when creating a record, refer [Hooks](hooks.html) for details on the lifecycle

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

If you want to skip `Hooks` methods, you can use the `SkipHooks` session mode, for example:

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)
```

## Map으로 생성하기

GORM supports create from `map[string]interface{}` and `[]map[string]interface{}{}`, e.g:

```go
db.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// batch insert from `[]map[string]interface{}{}`
db.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**NOTE** When creating from map, hooks won't be invoked, associations won't be saved and primary key values won't be back filled
{% endnote %}

## <span id="create_from_sql_expr">SQL Expression/Context Valuer로 생성</span>

GORM allows insert data with SQL expression, there are two ways to achieve this goal, create from `map[string]interface{}` or [Customized Data Types](data_types.html#gorm_valuer_interface), for example:

```go
// Create from map
db.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

// Create from customized data type
type Location struct {
    X, Y int
}

// Scan implements the sql.Scanner interface
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

## 고급

### <span id="create_with_associations">Create With Associations</span>

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

### <span id="default_values">기본 값</span>

You can define default values for fields with tag `default`, for example:

```go
type User struct {
  ID   int64
  Name string `gorm:"default:galeone"`
  Age  int64  `gorm:"default:18"`
}
```

Then the default value *will be used* when inserting into the database for [zero-value](https://tour.golang.org/basics/12) fields

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
  FullName  string `gorm:"->;type:GENERATED ALWAYS AS (concat(firstname,' ',lastname));default:(-);"`
}
```

{% note warn %}
**NOTE** **SQLite** doesn't support some records are default values when batch insert. See [SQLite Insert stmt](https://www.sqlite.org/lang_insert.html). For example:

```go
type Pet struct {
    Name string `gorm:"default:cat"`
}

// In SQLite, this is not supported, so GORM will build a wrong SQL to raise error:
// INSERT INTO `pets` (`name`) VALUES ("dog"),(DEFAULT) RETURNING `name`
db.Create(&[]Pet{{Name: "dog"}, {}})
```
A viable alternative is to assign default value to fields in the hook, e.g.

```go
func (p *Pet) BeforeCreate(tx *gorm.DB) (err error) {
    if p.Name == "" {
        p.Name = "cat"
    }
}
```

You can see more info in [issues#6335](https://github.com/go-gorm/gorm/issues/6335)
{% endnote %}

When using virtual/generated value, you might need to disable its creating/updating permission, check out [Field-Level Permission](models.html#field_permission)

### <span id="upsert">Upsert / On Conflict</span>

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
