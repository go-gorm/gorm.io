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

## 선택한 필드로 레코드 만들기

레코드를 만들고 지정된 필드에 값을 할당합니다.

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

많은 수의 레코드를 효율적으로 삽입 하려면 `Create ` 메서드에 ` Slice `를 전달합니다. GORM은 모든 데이터를 넣고 primary key 값을 다시 채우는 단일 SQL 문을 만들며, hook 메서드도 호출됩니다.

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

`CreateInBatches`를 사용하여 batch size 를 특정 값으로 조절 할 수 있습니다. 예시:

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// batch size 100
db.CreateInBatches(users, 100)
```

일괄 삽입은 [Upsert](#upsert) 및 [Create With Associations](#create_with_associations)에도 지원됩니다.

{% note warn %}
**NOTE** CreateBatchSize 옵션을 사용하여 GORM을 초기화 할 수 있으며, 모든 `INSERT`는 create record & associations 할 때 이 옵션을 따르게 됩니다.
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

GORM은 `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate` hook을 사용자가 정의 하여 구현 할 수 있습니다.  이러한 hook 메서드는 레코드를 만들때 호출 되며, lifecycle 의 자세한 내용은 [Hooks](hooks.html) 을 참고 하십시오.

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

`Hooks` 메서드를 건너뛰길 원한다면, session mode 에서 `SkipHooks` 를 사용할 수 있습니다. 예시는 다음과 같습니다.

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)
```

## Map으로 생성하기

GORM은 `map[string]interface{}` 와 `[]map[string]interface{}{}` 로 부터 create 하는것이 가능합니다.

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
**NOTE** map으로 create 할 때, hooks 는 실행 되지 않고, associations은 저장 되지 않으며 primary key 값 도 다시 채워지지 않습니다.
{% endnote %}

## <span id="create_from_sql_expr">SQL Expression/Context Valuer로 생성</span>

GORM을 사용하면 SQL 표현식을 사용하여 데이터를 삽입 할 수 있습니다.이 목표를 달성하는 데는 두 가지 방법이 있습니다. `map [string] interface {`} 또는 [사용자 정의 데이터 유형](data_types.html#gorm_valuer_interface)에서 생성합니다.

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

`Select`, `Omit` 를 사용하여 associations를 스킵 할 수 있습니다. 예시:

```go
db.Omit("CreditCard").Create(&user)

// skip all associations
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">기본 값</span>

태그 `default`를 사용하여 필드의 기본값을 정의 할 수 있습니다. 예를 들면 다음과 같습니다.

```go
type User struct {
  ID   int64
  Name string `gorm:"default:galeone"`
  Age  int64  `gorm:"default:18"`
}
```

기본 값은 [zero-value](https://tour.golang.org/basics/12) 필드에 사용됩니다

{% note warn %}
**NOTE** `0`, `''`, `false`와 같은 null 값은 기본 값으로 정의 된 해당 필드에 대해 데이터베이스에 저장되지 않습니다. 이를 방지하기 위해 포인터 또는 Scanner/Valuer를 사용할 수 있습니다. 예를 들면 다음과 같습니다.
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
**NOTE** 데이터베이스에 기본 값 또는 가상/생성 값이 있는 필드에 대해` default ` 태그를 설정해야 합니다. 마이그레이션 할 때 기본 값 정의를 건너뛰려면 다음과 같이 ` default:(-) ` 를 사용할 수 있습니다. 예시는 다음과 같습니다:
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

가상/생성 값을 사용하는 경우 생성/재구성 권한을 비활성화 해야 할 수 있습니다. [Field-Level Permission](models.html#field_permission)을 확인하세요.

### <span id="upsert">Upsert / On Conflict</span>

GORM은 서로 다른 데이터베이스에 대해 호환 가능한 Upsert 지원을 제공합니다.

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

또한 [고급 쿼리 문서](advanced_query.html)에서 ` FirstOrInit `, ` FirstOrCreate `에 대하여 확인하십시오.

자세한 내용은 [Raw SQL 및 SQL Builder](sql_builder.html) 를 확인하십시오.
