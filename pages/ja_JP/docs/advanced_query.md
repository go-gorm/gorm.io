---
title: 高度なクエリ
layout: page
---

## <span id="smart_select">便利なフィールドの選択</span>

GORMでは [`Select`](query.html) で選択するフィールド指定することができます。アプリケーションでこれを頻繁に使用する場合は、特定のフィールドを自動的に選択できる、用途に適した構造体を定義するとよいでしょう。例:

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
**注意** `QueryFields` モードを有効にすると、モデルのすべてのフィールド名を選択するようになります。
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

## ロック (FOR UPDATE)

GORMは数種類のロック処理をサポートしています。例:

```go
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`

db.Clauses(clause.Locking{
  Strength: "UPDATE",
  Options: "NOWAIT",
}).Find(&users)
// SELECT * FROM `users` FOR UPDATE NOWAIT
```

詳細については、[Raw SQL and SQL Builder](sql_builder.html)を参照してください。

## サブクエリ

クエリ内にサブクエリをネストすることができます。GORMは、パラメータとして `*gorm.DB` オブジェクトを使用するとサブクエリを生成できます。

```go
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">From句でのサブクエリ</span>

GORMでは、`Table`を用いることで、FROM句でサブクエリを使用することができます。例:

```go
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">条件をグループ化する</span>

グループ条件で複雑な SQL クエリを簡単に記述できます。

```go
db.Where(
    db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## 複数カラムでのIN

IN句で複数カラムを指定してレコードを取得することができます。

```go
db.Where("(name, age, role) IN ?", [][]interface{}{{"jinzhu", 18, "admin"}, {"jinzhu2", 19, "user"}}).Find(&users)
// SELECT * FROM users WHERE (name, age, role) IN (("jinzhu", 18, "admin"), ("jinzhu 2", 19, "user"));
```

## 名前付き引数

GORMは[`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg)や`map[string]interface{}{}`を使用した名前付き引数をサポートしています 。例：

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

より詳細については、 [Raw SQL and SQL Builder](sql_builder.html#named_argument) も参照してみてください。

## 取得結果をマップに代入

GORMでは取得結果を `map[string]interface{}`や `[]map[string]interface{}` に代入することができます。その際 `Model` や `Table` の指定を忘れないでください。例：

```go
result := map[string]interface{}{}
db.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
db.Table("users").Find(&results)
```

## FirstOrInit

条件に最初に一致するレコードを取得するか、指定された条件を使用して構造体のインスタンスを初期化します (構造体、map条件でのみ動作します)。

```go
// ユーザを取得できないため、与えられた条件でユーザを初期化
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"}

// `name` = `jinzhu` の条件でユーザを取得できた
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}

// `name` = `jinzhu` の条件でユーザを取得できた
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

レコードが見つからない場合のみ、struct をより多くの属性で初期化できます。これらの `Attrs（属性）` はSQLクエリの生成には使用されません。

```go
// Userが見つからないため、取得条件とAttrsで指定された属性で構造体を初期化
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Userが見つからないため、取得条件とAttrsで指定された属性で構造体を初期化
db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// `name` = `jinzhu` のUserが見つかったため、Attrsで指定された属性は無視される
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

`Assign` メソッドを使用すると、レコードが見つかったかどうかにかかわらず、指定した値を構造体に割り当てます。このメソッドで指定した属性はレコード取得時のSQLクエリには使用されません。また、生成されたデータのデータベースへの登録も行われません。

```go
// Userが見つからないため、取得条件とAssignで指定された属性で構造体を初期化
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20}

// `name` = `jinzhu` のUserが見つかったため、取得レコードの値とAssignで指定された値で構造体を生成
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## FirstOrCreate

条件に最初に一致するレコードを取得するか、指定された条件で新しいレコードを作成します (構造体、map条件でのみ動作します)。

```go
// Userが見つからないため、指定された条件でレコードを作成する
db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}

// `name` = `jinzhu` のUserが見つかった
db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age": 18}
```

`Attrs` メソッドを使用すると、レコードが見つからない場合に作成されるデータの属性をより多く指定することができます。このメソッドで指定した属性はレコード取得時のSQLクエリには使用されません。

```go
// Userが見つからないため、取得条件とAttrsで指定された属性でレコードを作成
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// `name` = `jinzhu`のユーザが見つかったため、Attrsで指定された属性は無視される
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

`Assign` メソッドを使用すると、レコードが見つかったどうかにかかわらず、指定した値をデータベースに登録します。

```go
// Userが見つからないため、取得条件とAssignで指定された属性でレコードを作成
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// `name` = `jinzhu`のUserが見つかったため、Assignの値で取得したレコードを更新する
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "jinzhu", Age: 20}
```

## Optimizer/Index Hints

オプティマイザヒントを利用することで、特定のクエリ実行計画を選択するようオプティマイザを制御することができます。GORMでは、 `gorm.io/hints` でそれをサポートしています。例：

```go
import "gorm.io/hints"

db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

クエリプランナーが最適なクエリを計画できていない場合、データベースにインデックスヒントを渡すことができます。

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```

詳細については、 [Optimizer Hints/Index/Comment](hints.html) を参照してください。

## Iteration

GORMは行ごとのイテレーション処理をサポートしています。

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

バッチ処理におけるクエリやレコード処理を行うことができます。

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

GORMではレコード取得のフック処理に `AfterFind` を利用することができます。このメソッドはレコードを取得時に呼び出されます。 詳細は [Hooks](hooks.html) を参照してください。

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.Role == "" {
    u.Role = "user"
  }
  return
}
```

## <span id="pluck">Pluck</span>

1つのカラムからのみ値を取得してsliceに代入することができます。複数のカラムから値を取得する場合は、 `Select` と [`Scan`](query.html#scan) を代わりに利用する必要があります。

```go
var ages []int64
db.Model(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Distinct Pluck
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// 2つ以上のカラムを指定する場合は、以下のように `Scan` もしくは `Find` を利用します
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```

## Scopes

共通で使用されるクエリ処理は関数化することができます。`Scopes` を使用すると、関数化されたクエリ処理を指定することができます。

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

詳細については [Scopes](scopes.html) を確認してください。

## <span id="count">Count</span>

条件に一致したレコード数を取得することができます。

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
