---
title: Advanced Query
layout: page
---

## <span id="smart_select">Smart Select Fields</span>

GORM은 [`Select`](query.html) 를 사용하여 특정 필드를 선택할 수 있습니다. 응용 프로그램에서 이 필드를 자주 사용하는 경우 다음과 같이 특정 필드를 자동으로 선택할 수 있는 API 사용을 위한 작은 구조를 정의할 수 있습니다.

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

// Select `id`, `name` automatically when querying
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

{% note warn %}
**NOTE** `QueryFields` 모드는 현재 모델에 대한 모든 필드 이름으로 선택됩니다.
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  QueryFields: true,
})

db.Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users` // with this option

// Session Mode
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users`
```

## Locking (FOR UPDATE)

GORM 은 다른 종류의 lock을 지원합니다.

```go
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`
```

자세한 내용은 [Raw SQL and SQL Builder](sql_builder.html) 을 참고하세요.

## SubQuery

서브쿼리는 쿼리 내에 중첩될 수 있으며, GORM은 `*gorm.DB` 개체를 매개 변수로 사용할 때 하위 쿼리를 생성할 수 있습니다.

```go
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">From SubQuery</span>

GORM은 FROM 절의 서브쿼리를 `Table` 메서드와 함께 사용할 수 있습니다. 예시:

```go
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18}).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Group Conditions (그룹화 조건)</span>

그룹 조건을 사용하여 복잡한 SQL 쿼리를 더 쉽게 작성할 수 있습니다.

```go
db.Where(
    db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## 명명된 인수 (Named Argument)

GORM은 [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) or `map[string]interface{}{}` 를 사용하여 명명된 인수(named arguments) 를 지원합니다. 예시:

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

자세한 내용은 [Raw SQL and SQL Builder](sql_builder.html#named_argument)를 확인하세요.

## Find To Map

GORM은 `map[string]interface{}` 또는 `[]map[string]interface{}` 을 통해 결과값을 조회 할 수 있으며, 특정 `Model` 또는 `Table` 을 빠트리지 마십시오.

```go
var result map[string]interface{}
db.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
db.Table("users").Find(&results)
```

## FirstOrInit

처음 일치하는 레코드를 가져오거나 지정된 조건으로 새 인스턴스를 초기화합니다. (struct 또는 map 조건에서만 작동).

```go
// User not found, initialize it with give conditions
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"}

// Found user with `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}

// Found user with `name` = `jinzhu`
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

레코드를 찾을 수 없는 경우 더 많은 속성을 가진 구조를 초기화 합니다. 이러한 `Attrs` 는 SQL 쿼리를 작성하는 데 사용되지 않습니다.

```go
// User not found, initialize it with give conditions and Attrs
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// User not found, initialize it with give conditions and Attrs
db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, attributes will be ignored
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

struct에 대한 `Assign` 속성은 찾든 말든 SQL 쿼리를 작성하는 데 사용되지 않으며 최종 데이터는 데이터베이스에 저장되지 않습니다.

```go
// User not found, initialize it with give conditions and Assign attributes
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, update it with Assign attributes
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## FirstOrCreate

처음 일치하는 레코드를 가져오거나 지정된 조건으로 새 인스턴스를 초기화합니다. (struct 또는 map 조건에서만 작동).

```go
// User not found, create a new record with give conditions
// 유저를 못찾아서 주어진 조건으로 새로운 레코드 생성
db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}

// Found user with `name` = `jinzhu`
// `name` = `jinzhu` 인 유저를 찾음
db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age": 18}
```

레코드를 찾을 수 없는 경우 더 많은 속성을 가진 struct를 생성합니다. 이러한 `Attrs` 는 SQL 쿼리를 작성하는 데 사용되지 않습니다.

```go
// User not found, create it with give conditions and Attrs
// 유저를 찾지 못함, 주어진 조건과 추가 속성을 통해 생성
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, attributes will be ignored
// `name` = `jinzhu 인 유저를 찾음, 속성은 무시 됨
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

`Assign` 속성은 레코드가 있는지 여부에 관계없이 레코드에 속하며 데이터베이스에 다시 저장합니다.

```go
// User not found, initialize it with give conditions and Assign attributes
// 유저 못찾음, 주어진 조건과 Assign 속성을 통해 초기화
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, update it with Assign attributes
// `name` = `jinzhu` 유저를 찾음, Assign 속성으로 업데이트
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "jinzhu", Age: 20}
```

## Optimizer/Index Hints

Optimizer hints를 통해 쿼리 최적화 도구를 제어하여 특정 쿼리 실행 계획을 선택할 수 있습니다. GORM은 다음과 같이 `gorm.io/hints` 를 지원합니다.

```go
import "gorm.io/hints"

db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Index hints 에서는 query planner가 혼동될 경우 Index hints를 데이터베이스에 전달할 수 있습니다.

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```

더 자세한 내용은 [Optimizer Hints/Index/Comment](hints.html)를 참고하세요.

## Iteration

GORM은 행 간 반복을 지원합니다.

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Rows()
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows is a method of `gorm.DB`, it can be used to scan a row into a struct
  db.ScanRows(rows, &user)

  // do something
}
```

## FindInBatches

일괄적으로 레코드를 쿼리하고 처리합니다.

```go
// batch size 100
result := db.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // batch processing found records
  }

  tx.Save(&results)

  tx.RowsAffected // number of records in this batch

  batch // Batch 1, 2, 3

  // returns error will stop future batches
  return nil
})

result.Error // returned error
result.RowsAffected // processed records count in all batches
```

## Query Hooks

GORM은 쿼리에 대해 `AfterFind` hooks 를 허용하며, 레코드를 쿼리할 때 호출됩니다. 자세한 내용은 [Hooks](hooks.html) 를 참조하십시오.

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.Role == "" {
    u.Role = "user"
  }
  return
}
```

## <span id="pluck">Pluck</span>

데이터베이스에서 단일 열을 쿼리하고 slice로 스캔합니다. 여러 column을 쿼리하려면, `Select` 를 [`Scan`](query.html#scan)과 함께 사용하십시오.

```go
var ages []int64
db.Model(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Distinct Pluck
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Requesting more than one column, use `Scan` or `Find` like this:
// 여러 컬럼의 결과를 원할때, `Scan` 또는 `Find` 를 아래와같이 사용하세요.
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```

## Scopes

`Scopes` 는 자주 일반적으로 사용 되는 쿼리를 메서드 호출로 참조하여 지정할 수 있습니다.

```go
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
  return db.Where("amount > ?", 1000)
}

func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func PaidWithCod(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func OrderStatus(status []string) func (db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    return db.Where("status IN (?)", status)
  }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Find all credit card orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Find all COD orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Find all paid, shipped orders that amount greater than 1000
```

자세한 내용은 [Scopes](scopes.html)를 확인하세요.

## <span id="count">Count</span>

일치하는 레코드 수를 가져옵니다.

```go
var count int64
db.Model(&User{}).Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu'; (count)

db.Table("deleted_users").Count(&count)
// SELECT count(1) FROM deleted_users;

// Count with Distinct
db.Model(&User{}).Distinct("name").Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db.Table("deleted_users").Select("count(distinct(name))").Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Count with Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

db.Model(&User{}).Group("name").Count(&count)
count // => 3
```
