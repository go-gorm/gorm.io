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

효율적으로 많은 레코드를 만들기 위해서, slice를 `Create` 메소드에 넣어주세요. GORM은 단 하나의 SQL 구문을 작성하여 모든 데이터를 삽입합니다 또한 hook methods, primary key 값 자동 삽입등이 이를 기점으로 하여 실행됩니다. 이를 일정한 배치 단위로 나누어서 **트랜잭션**으로 처리할 수 있습니다.

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

`CreateInBatches`를 활용하여 배치 사이즈를 결정할 수 있습니다, e.g:

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// batch size 100
db.CreateInBatches(users, 100)
```

Batch Insert는 [Upset](#upsert)와 [Create With Associtations](#create_with_associations)에도 지원됩니다.

{% note warn %}
**주의할점:** GORM을 `CreateBatchSize`옵션과 함께 생성할 경우, 모든 `INSERT`구문은 레코드 생성시 해당 배치 옵션을 따를것입니다.
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

GORM은 `BeforeSave`,`BeforeCreate`,`AfterSave`,`AfterCreate`등과 같은 사용자가 정의한 hook을 구현하여 사용할 수 있습니다.  이런 hook 메소드들은 레코드를 만들때 호출 됩니다, [Hooks](hooks.html)를 참고하여 좀 더 자세한 생명주기에 관하여 참고해보세요.

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

만일 `Hooks` 메소드들을 생략하고 싶으시다면, `SkipHooks`를 session mode에서 활용할 수 있습닏, 예시:

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)
```

## Map으로 생성하기

GORM은 `map[string] interface{}` 및 `[]map[string] interface{}{}`를 활용한 레코드 생성을 지원합니다, 예시:

```go
db.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// `[]map[string]interface{}{}`를 활용한 batch insert
db.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**주의할점** map 자료구조를 활용한 레코드 생성시, hooks은 실행되지 않으며 기본키가 채워지지 안흥며 연결이 저장되지 않습니다.
{% endnote %}

## <span id="create_from_sql_expr">SQL Expression/Context Valuer로 생성</span>

GORM은 SQL을 활용한 데이터 삽입을 지원합니다. SQL을 활용하기 위하여는 두 가지 방법을 사용할 수 있습니다. `map[string] interface{}` 혹은 [사용자 정의 데이터 타입](data_types.html#gorm_valuer_interface)을 활용할 수 있습니다. 예시:

```go
// map을 활용한 레코드 생성 
db.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

// 사용자 정의 타입을 활용한 데이터 생성 
type Location struct {
    X, Y int
}

// sql.Scanner 인터페이스의 구현을 검사 
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

연관(associations) 이 있는 일부 데이터를 작성할 때 association 값이 0 값이 아닌 경우 해당 association이 upsert 되고 해당 `Hooks` 메소드가 호출됩니다.

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
