---
title: レコードの取得
layout: page
---

## 単一のオブジェクトを取得する

GORMは、データベースから１つのオブジェクトを取得するために`First`, `Take`, `Last`メソッドを提供しています。それらのメソッドは、データベースにクエリを実行する際に`LIMIT 1`の条件を追加し、レコードが見つからなかった場合、`ErrRecordNotFound`エラーを返します。

```go
// Get the first record ordered by primary key
db.First(&user)
// SELECT * FROM users ORDER BY id LIMIT 1;

// Get one record, no specified order
db.Take(&user)
// SELECT * FROM users LIMIT 1;

// Get last record, ordered by primary key desc
db.Last(&user)
// SELECT * FROM users ORDER BY id DESC LIMIT 1;

result := db.First(&user)
result.RowsAffected // returns count of records found
result.Error        // returns error or nil

// check error ErrRecordNotFound
errors.Is(result.Error, gorm.ErrRecordNotFound)
```

{% note warn %}
`ErrRecordNotFound` エラーを避けたい場合は、`db.Limit(1).Find(&user)`のように、`Find` を 使用することができます。`Find` メソッドは struct と slice のどちらも受け取ることができます。
{% endnote %}

{% note warn %}
単一のオブジェクトを取得する際、`db.Find(&user)` のように、上限を設定せずに `Find` を使用した場合、テーブル全体を問い合わせたのち先頭のオブジェクトのみを返すため、これは非効率的かつ非確定的な方法です。
{% endnote %}

The `First` and `Last` methods will find the first and last record (respectively) as ordered by primary key. これら2つのメソッドは、対象の構造体のポインタをメソッドの引数に渡す、もしくは `db.Model()` を使用してモデルを指定した場合のみ動作します。 また、モデルに主キーが定義されていない場合、モデル内の最初のフィールドで順序付けされることになります。 例:

```go
var user User
var users []User

// 対象の構造体が渡されているため正しく動作
db.First(&user)
// SELECT * FROM `users` ORDER BY `users`.`id` LIMIT 1

// `db.Model()` を使ってモデルを指定しているため正しく動作
result := map[string]interface{}{}
db.Model(&User{}).First(&result)
// SELECT * FROM `users` ORDER BY `users`.`id` LIMIT 1

// 動作しない
result := map[string]interface{}{}
db.Table("users").First(&result)

// Takeメソッドであれば動作する
result := map[string]interface{}{}
db.Table("users").Take(&result)

// 主キーが未定義のため、最初のフィールド（`Code`）で順序付けされる
type Language struct {
  Code string
  Name string
}
db.First(&Language{})
// SELECT * FROM `languages` ORDER BY `languages`.`code` LIMIT 1
```

### プライマリキーでオブジェクトを取得する

Objects can be retrieved using primary key by using [Inline Conditions](#inline_conditions) if the primary key is a number. 文字列を扱う場合、SQLインジェクションを避けるためにさらなる注意が必要です。詳細については[セキュリティ](security.html)セクションを参照してください。

```go
db.First(&user, 10)
// SELECT * FROM users WHERE id = 10;

db.First(&user, "10")
// SELECT * FROM users WHERE id = 10;

db.Find(&users, []int{1,2,3})
// SELECT * FROM users WHERE id IN (1,2,3);
```

主キーが（たとえばUUIDのような）文字列の場合、クエリは以下のように書くことができます。

```go
db.First(&user, "id = ?", "1b74413f-f3b8-409f-ac47-e8c062e3472a")
// SELECT * FROM users WHERE id = "1b74413f-f3b8-409f-ac47-e8c062e3472a";
```

対象オブジェクトの主キーに値が入っている場合、その主キーは検索条件の構築に使用されます。例:

```go
var user = User{ID: 10}
db.First(&user)
// SELECT * FROM users WHERE id = 10;

var result User
db.Model(User{ID: 10}).First(&result)
// SELECT * FROM users WHERE id = 10;
```

{% note warn %}
**注意:** `gorm.DeletedAt` のようなGORM用のフィールドの型を使用する場合、オブジェクトの取得の際に異なるクエリが実行されます。
{% endnote %}
```go
type User struct {
  ID           string `gorm:"primarykey;size:16"`
  Name         string `gorm:"size:24"`
  DeletedAt    gorm.DeletedAt `gorm:"index"`
}

var user = User{ID: 15}
db.First(&user)
//  SELECT * FROM `users` WHERE `users`.`id` = '15' AND `users`.`deleted_at` IS NULL ORDER BY `users`.`id` LIMIT 1
```
## すべてのオブジェクトを取得する

```go
// 全レコードを取得
result := db.Find(&users)
// SELECT * FROM users;

result.RowsAffected // 見つかったレコードの件数 `len(users)` を返す
result.Error        // エラーを返す
```

## 取得条件

### 文字列条件

```go
// 最初に条件に合ったレコードを取得
db.Where("name = ?", "jinzhu").First(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;

// 条件にあったすべてのレコードを取得
db.Where("name <> ?", "jinzhu").Find(&users)
// SELECT * FROM users WHERE name <> 'jinzhu';

// IN
db.Where("name IN ?", []string{"jinzhu", "jinzhu 2"}).Find(&users)
// SELECT * FROM users WHERE name IN ('jinzhu','jinzhu 2');

// LIKE
db.Where("name LIKE ?", "%jin%").Find(&users)
// SELECT * FROM users WHERE name LIKE '%jin%';

// AND
db.Where("name = ? AND age >= ?", "jinzhu", "22").Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' AND age >= 22;

// 日時
db.Where("updated_at > ?", lastWeek).Find(&users)
// SELECT * FROM users WHERE updated_at > '2000-01-01 00:00:00';

// BETWEEN
db.Where("created_at BETWEEN ? AND ?", lastWeek, today).Find(&users)
// SELECT * FROM users WHERE created_at BETWEEN '2000-01-01 00:00:00' AND '2000-01-08 00:00:00';
```

{% note warn %}
If the object's primary key has been set, then condition query wouldn't cover the value of primary key but use it as a 'and' condition. 例:
```go
var user = User{ID: 10}
db.Where("id = ?", 20).First(&user)
// SELECT * FROM users WHERE id = 10 and id = 20 ORDER BY id ASC LIMIT 1
```
This query would give `record not found` Error. So set the primary key attribute such as `id` to nil before you want to use the variable such as `user` to get new value from database.
{% endnote %}


### 構造体 & マップでの条件指定

```go
// 構造体
db.Where(&User{Name: "jinzhu", Age: 20}).First(&user)
// SELECT * FROM users WHERE name = "jinzhu" AND age = 20 ORDER BY id LIMIT 1;

// マップ
db.Where(map[string]interface{}{"name": "jinzhu", "age": 20}).Find(&users)
// SELECT * FROM users WHERE name = "jinzhu" AND age = 20;

// 主キーのスライス
db.Where([]int64{20, 21, 22}).Find(&users)
// SELECT * FROM users WHERE id IN (20, 21, 22);
```

{% note warn %}
**NOTE** When querying with struct, GORM will only query with non-zero fields, that means if your field's value is `0`, `''`, `false` or other [zero values](https://tour.golang.org/basics/12), it won't be used to build query conditions, for example:
{% endnote %}

```go
db.Where(&User{Name: "jinzhu", Age: 0}).Find(&users)
// SELECT * FROM users WHERE name = "jinzhu";
```

クエリ条件にゼロ値を含めるには、すべてのキーと値のペアを含んだマップをクエリ条件として使用します。例:

```go
db.Where(map[string]interface{}{"Name": "jinzhu", "Age": 0}).Find(&users)
// SELECT * FROM users WHERE name = "jinzhu" AND age = 0;
```

詳細については、 [構造体の検索フィールドを指定する](#specify_search_fields) を参照してください。

### <span id="specify_search_fields">構造体の検索フィールドを指定する</span>

構造体を使用して検索する場合、フィールド名またはテーブルのカラム名を `Where()` の引数として列挙することで、構造体の特定の値のみをクエリ条件として使用することができます。 例:

```go
db.Where(&User{Name: "jinzhu"}, "name", "Age").Find(&users)
// SELECT * FROM users WHERE name = "jinzhu" AND age = 0;

db.Where(&User{Name: "jinzhu"}, "Age").Find(&users)
// SELECT * FROM users WHERE age = 0;
```

### <span id="inline_conditions">インライン条件</span>

クエリ条件は、`First` や `Find` のようなメソッドにおいても `Where` と同様の方法でインラインで記述することができます。

```go
// Get by primary key if it were a non-integer type
db.First(&user, "id = ?", "string_primary_key")
// SELECT * FROM users WHERE id = 'string_primary_key';

// Plain SQL
db.Find(&user, "name = ?", "jinzhu")
// SELECT * FROM users WHERE name = "jinzhu";

db.Find(&users, "name <> ? AND age > ?", "jinzhu", 20)
// SELECT * FROM users WHERE name <> "jinzhu" AND age > 20;

// Struct
db.Find(&users, User{Age: 20})
// SELECT * FROM users WHERE age = 20;

// Map
db.Find(&users, map[string]interface{}{"age": 20})
// SELECT * FROM users WHERE age = 20;
```

### Not条件

Build NOT conditions, works similar to `Where`

```go
db.Not("name = ?", "jinzhu").First(&user)
// SELECT * FROM users WHERE NOT name = "jinzhu" ORDER BY id LIMIT 1;

// Not In
db.Not(map[string]interface{}{"name": []string{"jinzhu", "jinzhu 2"}}).Find(&users)
// SELECT * FROM users WHERE name NOT IN ("jinzhu", "jinzhu 2");

// Struct
db.Not(User{Name: "jinzhu", Age: 18}).First(&user)
// SELECT * FROM users WHERE name <> "jinzhu" AND age <> 18 ORDER BY id LIMIT 1;

// Not In slice of primary keys
db.Not([]int64{1,2,3}).First(&user)
// SELECT * FROM users WHERE id NOT IN (1,2,3) ORDER BY id LIMIT 1;
```

### OR条件

```go
db.Where("role = ?", "admin").Or("role = ?", "super_admin").Find(&users)
// SELECT * FROM users WHERE role = 'admin' OR role = 'super_admin';

// 構造体
db.Where("name = 'jinzhu'").Or(User{Name: "jinzhu 2", Age: 18}).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' OR (name = 'jinzhu 2' AND age = 18);

// マップ
db.Where("name = 'jinzhu'").Or(map[string]interface{}{"name": "jinzhu 2", "age": 18}).Find(&users)
// SELECT * FROM users WHERE name = 'jinzhu' OR (name = 'jinzhu 2' AND age = 18);
```

For more complicated SQL queries. please also refer to [Group Conditions in Advanced Query](advanced_query.html#group_conditions).

## 特定のフィールドのみ選択

データベースから取得するフィールドを指定するには `Select` を使用します。 指定がない場合、GORMではデフォルトで全フィールドが選択されます。

```go
db.Select("name", "age").Find(&users)
// SELECT name, age FROM users;

db.Select([]string{"name", "age"}).Find(&users)
// SELECT name, age FROM users;

db.Table("users").Select("COALESCE(age,?)", 42).Rows()
// SELECT COALESCE(age,'42') FROM users;
```

[Smart Select Fields](advanced_query.html#smart_select) も参照してください。

## Order

データベースからレコードを取得する際の順序を指定します。

```go
db.Order("age desc, name").Find(&users)
// SELECT * FROM users ORDER BY age desc, name;

// 複数の順序
db.Order("age desc").Order("name").Find(&users)
// SELECT * FROM users ORDER BY age desc, name;

db.Clauses(clause.OrderBy{
  Expression: clause.Expr{SQL: "FIELD(id,?)", Vars: []interface{}{[]int{1, 2, 3}}, WithoutParentheses: true},
}).Find(&User{})
// SELECT * FROM users ORDER BY FIELD(id,1,2,3)
```

## Limit & Offset

`Limit`は取得するレコードの上限数を指定します。`Offset`はレコードを返す前にスキップする件数を指定します。

```go
db.Limit(3).Find(&users)
// SELECT * FROM users LIMIT 3;

// -1 を指定して上限数を解除
db.Limit(10).Find(&users1).Limit(-1).Find(&users2)
// SELECT * FROM users LIMIT 10; (users1)
// SELECT * FROM users; (users2)

db.Offset(3).Find(&users)
// SELECT * FROM users OFFSET 3;

db.Limit(10).Offset(5).Find(&users)
// SELECT * FROM users OFFSET 5 LIMIT 10;

// -1 を指定して上限数を解除
db.Offset(10).Find(&users1).Offset(-1).Find(&users2)
// SELECT * FROM users OFFSET 10; (users1)
// SELECT * FROM users; (users2)
```

ページネーターの作成方法については、[ページネーション](scopes.html#pagination) を参照してください。

## Group By & Having

```go
type result struct {
  Date  time.Time
  Total int
}

db.Model(&User{}).Select("name, sum(age) as total").Where("name LIKE ?", "group%").Group("name").First(&result)
// SELECT name, sum(age) as total FROM `users` WHERE name LIKE "group%" GROUP BY `name` LIMIT 1


db.Model(&User{}).Select("name, sum(age) as total").Group("name").Having("name = ?", "group").Find(&result)
// SELECT name, sum(age) as total FROM `users` GROUP BY `name` HAVING name = "group"

rows, err := db.Table("orders").Select("date(created_at) as date, sum(amount) as total").Group("date(created_at)").Rows()
defer rows.Close()
for rows.Next() {
  ...
}

rows, err := db.Table("orders").Select("date(created_at) as date, sum(amount) as total").Group("date(created_at)").Having("sum(amount) > ?", 100).Rows()
defer rows.Close()
for rows.Next() {
  ...
}

type Result struct {
  Date  time.Time
  Total int64
}
db.Table("orders").Select("date(created_at) as date, sum(amount) as total").Group("date(created_at)").Having("sum(amount) > ?", 100).Scan(&results)
```

## Distinct

値が重複する行を削除して取得します。

```go
db.Distinct("name", "age").Order("name, age desc").Find(&results)
```

`Distinct` は [`Pluck`](advanced_query.html#pluck) および [`Count`](advanced_query.html#count) でも動作します

## Joins

テーブル結合の条件を指定します。

```go
type result struct {
  Name  string
  Email string
}

db.Model(&User{}).Select("users.name, emails.email").Joins("left join emails on emails.user_id = users.id").Scan(&result{})
// SELECT users.name, emails.email FROM `users` left join emails on emails.user_id = users.id

rows, err := db.Table("users").Select("users.name, emails.email").Joins("left join emails on emails.user_id = users.id").Rows()
for rows.Next() {
  ...
}

db.Table("users").Select("users.name, emails.email").Joins("left join emails on emails.user_id = users.id").Scan(&results)

// パラメーターで複数のテーブルを結合
db.Joins("JOIN emails ON emails.user_id = users.id AND emails.email = ?", "jinzhu@example.org").Joins("JOIN credit_cards ON credit_cards.user_id = users.id").Where("credit_cards.number = ?", "411111111111").Find(&user)
```

### Joins Preloading

You can use `Joins` eager loading associations with a single SQL, for example:

```go
db.Joins("Company").Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id`;

// 内部結合
db.InnerJoins("Company").Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` INNER JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id`;
```

条件を指定して結合する

```go
db.Joins("Company", db.Where(&Company{Alive: true})).Find(&users)
// SELECT `users`.`id`,`users`.`name`,`users`.`age`,`Company`.`id` AS `Company__id`,`Company`.`name` AS `Company__name` FROM `users` LEFT JOIN `companies` AS `Company` ON `users`.`company_id` = `Company`.`id` AND `Company`.`alive` = true;
```

詳細については、[事前ローディング (イーガーローディング)](preload.html) を参照してください。

### 導出表の結合

You can also use `Joins` to join a derived table.

```go
type User struct {
    Id  int
    Age int
}

type Order struct {
    UserId     int
    FinishedAt *time.Time
}

query := db.Table("order").Select("MAX(order.finished_at) as latest").Joins("left join user user on order.user_id = user.id").Where("user.age > ?", 18).Group("order.user_id")
db.Model(&Order{}).Joins("join (?) q on order.finished_at = q.latest", query).Scan(&results)
// SELECT `order`.`user_id`,`order`.`finished_at` FROM `order` join (SELECT MAX(order.finished_at) as latest FROM `order` left join user user on order.user_id = user.id WHERE user.age > 18 GROUP BY `order`.`user_id`) q on order.finished_at = q.latest
```


## <span id="scan">Scan</span>

Scanning results into a struct works similarly to the way we use `Find`

```go
type Result struct {
  Name string
  Age  int
}

var result Result
db.Table("users").Select("name", "age").Where("name = ?", "Antonio").Scan(&result)

// Raw SQL
db.Raw("SELECT name, age FROM users WHERE name = ?", "Antonio").Scan(&result)
```
