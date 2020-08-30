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

## Selected Fields를 이용하여 생성

Selected Fields를 이용하여 생성

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

Selected Fields없이 생성

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## Hooks 생성하기

GORM은 `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate` Hooks를 허용합니다. 해당 메서드는 레코드를 만들 때 호출됩니다. 자세한 내용은 [Hooks](hooks.html)를 참조하십시오.

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

## <span id="batch_insert">일괄 삽입</span>

Create 메서드에 슬라이스 데이터를 전달하면 GORM은 모든 데이터를 삽입하고 기본 키를 채우기위한 단일 SQL 문을 생성하며, Hooks 메서드또한 호출됩니다.

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
DB.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

일괄 삽입은 [Upsert](#upsert) 및 [Create With Associations](#create_with_associations)에도 지원됩니다.

## Map으로 생성하기

GORM은 `map[string]interface{}` 및 `[]map[string]interface{}{}` 을 이용하여 레코드를 생성하는것을 지원합니다. 예시:

```go
DB.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// `[]map[string]interface{}{}` 를 이용한 일괄 삽입
DB.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**NOTE** map으로 생성하면, hooks가 호출되지 않으며, 연결이 저장되지 않고, 기본키가 채워지지 않습니다.
{% endnote %}

## <span id="create_from_sql_expr">SQL Expr/Context Valuer로 생성</span>

GORM을 사용하면 SQL 표현식을 사용하여 데이터를 삽입 할 수 있습니다.이 목표를 달성하는 데는 두 가지 방법이 있습니다. `map [string] interface {`} 또는 [사용자 정의 데이터 유형](data_types.html#gorm_valuer_interface)에서 생성합니다.

```go
// Create from map
DB.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`point`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

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

DB.Create(&User{
  Name:     "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// INSERT INTO `users` (`name`,`point`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"))
```

## 고급

### <span id="create_with_associations">Create With Associations</span>

연관이있는 일부 데이터를 작성할 때 연관 값이 0 값이 아닌 경우 해당 연관이 상향 조정되고 해당 `Hooks` 메소드가 호출됩니다.

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

`Select`, `Omit`를 사용하여 associations를 스킵할 수 있습니다. 예시:

```go
db.Omit("CreditCard").Create(&user)

// skip all associations
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">기본 값</span>

태그 `default`를 사용하여 필드의 기본값을 정의 할 수 있습니다. 예를 들면 다음과 같습니다.

```go
type User struct {
  ID         int64
  Name       string `gorm:"default:galeone"`
  Age        int64  `gorm:"default:18"`
    uuid.UUID  UUID   `gorm:"type:uuid;default:gen_random_uuid()"` // db func
}
```

기본값은 [zero-value](https://tour.golang.org/basics/12) 필드에 사용됩니다

**NOTE** `0`, `''`, `false`와 같은 null값은 기본 값으로 정의 된 해당 필드에 대해 데이터베이스에 저장되지 않습니다. 이를 방지하기 위해 포인터 또는 Scanner/Valuer를 사용할 수 있습니다. 예를 들면 다음과 같습니다.

```go
type User struct {
  gorm.Model
  Name string
  Age  *int           `gorm:"default:18"`
  Active sql.NullBool `gorm:"default:true"`
}
```

**NOTE** database 또는 GORM에 기본값이있는 필드에 대해서 기본 기본값을 설정해야합니다. 그렇지 않으면 GORM에서 다음과 같이 생성 할 때 필드의 0 값을 사용합니다.

```go
type User struct {
    ID   string `gorm:"default:uuid_generate_v3()"`
    Name string
    Age  uint8
}
```

### <span id="upsert">Upsert / On Conflict</span>

GORM은 서로 다른 데이터베이스에 대해 호환 가능한 Upsert 지원을 제공합니다.

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

또한 [고급 쿼리 문서](advanced_query.html)에서 `FirstOrInit`, `FirstOrCreate`에 대하여 확인하십시오.

자세한 내용은 [Raw SQL 및 SQL Builder](sql_builder.html)를 확인하십시오.
