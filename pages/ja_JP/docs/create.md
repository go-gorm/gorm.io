---
title: レコードの作成
layout: page
---

## レコードを作成する

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

result := db.Create(&user) // pass pointer of data to Create

user.ID             // returns inserted data's primary key
result.Error        // returns error
result.RowsAffected // returns inserted records count
```

`Create()` を使用して複数のレコードを作成することもできます:
```go
users := []*User{
    User{Name: "Jinzhu", Age: 18, Birthday: time.Now()},
    User{Name: "Jackson", Age: 19, Birthday: time.Now()},
}

result := db.Create(users) // pass a slice to insert multiple row

result.Error        // returns error
result.RowsAffected // returns inserted records count
```

## フィールドを選択してレコードを作成する

レコードを作成し、指定したフィールドに値を割り当てます。

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

省略する項目を指定し、レコードを作成します。

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## <span id="batch_insert">一括作成</span>

大量のレコードを効率的に挿入するには、スライスを `Create` メソッドに渡します。 モデルのスライスをCreateメソッドに渡すと、GORMはすべてのデータを挿入する1つのSQL文を生成します。SQLが実行されると登録された主キーの値がモデルに代入され、フックメソッドも呼び出されます。 レコードが複数のバッチに分割されると、 **トランザクション** が開始されます。

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

`CreateInBatches` を利用して、バッチサイズを指定してレコードを作成できます。

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// batch size 100
db.CreateInBatches(users, 100)
```

[Upsert](#upsert) や [Create With Associations](#create_with_associations) を使用する場合もバッチインサートはサポートされています。

{% note warn %}
**NOTE** `CreateBatchSize` オプションでGORMを初期化した場合、 `INSERT` メソッドはその設定を参照して、レコードを作成します。
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

## 作成時のHook

GORMでは、 `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate`といったメソッドを実装することで、独自のHook処理を定義できます。  これらのメソッドはレコードを作成するときに呼び出されます。ライフサイクルの詳細については [Hooks](hooks.html) を参照してください。

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

`Hooks` メソッドをスキップしたい場合は、 `SkipHooks` セッションモードを使用できます。例:

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)
```

## Mapを使って作成する

GORMでは `map[string]interface{}` や `[]map[string]interface{}{}`を使ってレコード作成できます。例:

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
**注意** Mapを使用してレコードを作成する場合、Hookは呼び出されません。また、関連テーブルのレコードも保存されず、主キーの値もモデルに代入されません。
{% endnote %}

## <span id="create_from_sql_expr">SQL式/Context Valuer で作成する</span>

GORMはSQL式でデータを挿入することができます。これを行うには `map[string]interface{}` と [Customized Data Types](data_types.html#gorm_valuer_interface) の2つの方法があります。例:

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

## 高度な機能

### <span id="create_with_associations">関連データと関連付けて作成する</span>

関連データと共にレコードを作成する場合、その値がゼロ値でなければ関連データもupsertされます。またその際には、関連データの `Hooks` メソッドも実行されます。

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

`Select`, `Omit` を使うことで関連付けをスキップできます。例:

```go
db.Omit("CreditCard").Create(&user)

// skip all associations
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">デフォルト値</span>

`default`タグによって、フィールドのデフォルト値を定義できます。例:

```go
type User struct {
  ID   int64
  Name string `gorm:"default:galeone"`
  Age  int64  `gorm:"default:18"`
}
```

データベースへの挿入時にフィールドが [ ゼロ値 ](https://tour.golang.org/basics/12) の場合、*デフォルト値が使用されます*。

{% note warn %}
**注意** デフォルト値を定義したフィールドには、 `0`, `''`, `false`のようなゼロ値はデータベースに保存されないため、これを避けるにはポインタ型やScanner/Valuerを使用するとよいでしょう。例:
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
**注意** データベース内でのデフォルト値、あるいは仮想の生成された値を持つフィールドには ` default ` タグを設定する必要があります。マイグレーション時にデフォルト値の定義をスキップする場合は、 `default:(-)`, 例:
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

仮想の生成された値を使用する場合は、作成/更新権限を無効にする必要がある場合があります。 [Field-Level Permission](models.html#field_permission) を確認してください。

### <span id="upsert">コンフリクト発生時のUpsert</span>

GORMは異なるデータベースに対して互換性のあるUpsertをサポートしています。

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

[Advanced Query](advanced_query.html) の `FirstOrInit`, `FirstOrCreate` も確認してみてください。

より詳細については、 [Raw SQL and SQL Builder](sql_builder.html) も参照してみてください。
