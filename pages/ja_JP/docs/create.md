---
title: レコードの作成
layout: page
---

## レコードを作成する

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

result := db.Create(&user) // データのポインタを渡してレコードを作成する

user.ID             // 挿入されたデータの主キーを返す
result.Error        // エラーを返す
result.RowsAffected // 挿入されたレコードの件数を返す
```

`Create()` を使用して複数のレコードを作成することもできます:
```go
users := []*User{
    {Name: "Jinzhu", Age: 18, Birthday: time.Now()},
    {Name: "Jackson", Age: 19, Birthday: time.Now()},
}

result := db.Create(users) // スライスを渡して複数の行を挿入する

result.Error        // エラーを返す
result.RowsAffected // 挿入されたレコードの件数を返す
```

{% note warn %}
**注記** 'create' の引数として構造体を渡すことはできません。データへのポインタを渡してください。
{% endnote %}

## フィールドを選択してレコードを作成する

レコード作成時に、Selectで指定されたフィールドのみに対して値をアサインできます。

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

大量のレコードを効率的に挿入するには、スライスを `Create` メソッドに渡します。 GORMはすべてのデータを挿入する1つのSQL文を生成します。SQLが実行されると登録された主キーの値がモデルに代入され、フックメソッドも呼び出されます。 レコードを複数のバッチに分割することが可能な場合には、 **トランザクション** が開始されます。

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

`CreateInBatches` を利用することで、バッチサイズを指定してレコードを作成することができます。

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// batch size 100
db.CreateInBatches(users, 100)
```

[Upsert](#upsert) や [Create With Associations](#create_with_associations) を使用する場合もバッチインサートはサポートされています。

{% note warn %}
**注記** `CreateBatchSize` オプションを使ってGORMを初期化した場合、すべての `INSERT` は、その設定を参照してレコードやアソシエーションを作成します。
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

## 作成時の Hooks

GORMでは、`BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate` としてユーザー定義の Hooks を実装することができます。  これらの Hooks メソッドはレコードの作成時に呼び出されます。ライフサイクルの詳細については [Hooks](hooks.html) を参照してください。

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

`Hooks` メソッドをスキップしたい場合は、`SkipHooks` セッションモードを使用できます。例：

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)
```

## Map からの作成

GORMは `map[string]interface{}` および `[]map[string]interface{}{}` からの作成に対応しています。

```go
db.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// `[]map[string]interface{}{}` からバッチ挿入
db.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**注記** map から作成する場合、hooks は呼び出されません。また、アソシエーションは保存されず、主キーの値は埋め込まれません。
{% endnote %}

## <span id="create_from_sql_expr">SQL式/Context Valuer からの作成</span>

GORMではSQL式でデータの挿入が可能です。これを行うには `map[string]interface{}` から作成する方法と [データ型のカスタマイズ](data_types.html#gorm_valuer_interface) の2つの方法があります。例:

```go
// マップから作成
db.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

// カスタムデータ型から作成
type Location struct {
    X, Y int
}

// Scan は sql.Scanner インターフェースを実装
func (loc *Location) Scan(v interface{}) error {
  // データベースのドライバーから構造体へscan
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

関連付けを使用してデータを作成する場合、関連付けの値がゼロ値ではない場合、これらの関連付けが作成および更新され、`Hooks` メソッドが呼び出されます。

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

`Select` または `Omit` を使用することで関連付けをスキップできます。例:

```go
db.Omit("CreditCard").Create(&user)

// すべての関連付けをスキップ
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">デフォルト値</span>

`default` タグでフィールドのデフォルト値を定義することができます。例:

```go
type User struct {
  ID   int64
  Name string `gorm:"default:galeone"`
  Age  int64  `gorm:"default:18"`
}
```

レコードがデータベースへ挿入されるとき、[ゼロ値](https://tour.golang.org/basics/12) のフィールドにはデフォルト値が *使用されます*。

{% note warn %}
**注意** デフォルト値を定義したフィールドでは、`0`、`''`、`false` といったゼロ値がデータベースに保存されません。これを回避するには、ポインタ型か Scanner/Valuer を使用します。例:
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
**注意** データベース内でデフォルト値や仮想的に生成される値を持つフィールドには、`default` タグを設定する必要があります。マイグレーション時にデフォルト値の定義をスキップする場合は、`default:(-)` を使用します。例:
{% endnote %}

```go
type User struct {
  ID        string `gorm:"default:uuid_generate_v3()"` // データベース関数
  FirstName string
  LastName  string
  Age       uint8
  FullName  string `gorm:"->;type:GENERATED ALWAYS AS (concat(firstname,' ',lastname));default:(-);"`
}
```

{% note warn %}
**注意** **SQLite** はバッチ挿入時のデフォルト値をサポートしていません。 参照: [SQLite Insert stmt](https://www.sqlite.org/lang_insert.html) 例:

```go
type Pet struct {
    Name string `gorm:"default:cat"`
}

// SQLiteでは次の文がサポートされていないため、GORMが構築するSQLが不正となり、エラーが発生します:
// INSERT INTO `pets` (`name`) VALUES ("dog"),(DEFAULT) RETURNING `name`
db.Create(&[]Pet{{Name: "dog"}, {}})
```
フック内のフィールドにデフォルト値を割り当てることで代替できます。例:

```go
func (p *Pet) BeforeCreate(tx *gorm.DB) (err error) {
    if p.Name == "" {
        p.Name = "cat"
    }
}
```

[issues#6335](https://github.com/go-gorm/gorm/issues/6335) でより詳しい情報を確認できます。
{% endnote %}

仮想的に生成される値を使用する場合は、そのフィールドを作成/更新する権限を無効にする必要があります。[フィールドレベル権限](models.html#field_permission) を参照してください。

### <span id="upsert">衝突時の挿入/更新</span>

GORMは各データベースに対して互換性のあるUpsertをサポートしています。

```go
import "gorm.io/gorm/clause"

// 衝突の発生時に何もしない
db.Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// `id` の衝突時にデフォルト値で更新する
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

// SQL文を使用する
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"count": gorm.Expr("GREATEST(count, VALUES(count))")}),
}).Create(&users)
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `count`=GREATEST(count, VALUES(count));

// `id` の衝突時に新しいほうの値で更新する
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age); MySQL

// 衝突の発生時、主キーとSQLの関数によるデフォルト値を持つカラムを除いたすべての列を、新しいほうの値で更新する
db.Clauses(clause.OnConflict{
  UpdateAll: true,
}).Create(&users)
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age", ...;
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age), ...; MySQL
```

[高度なクエリ](advanced_query.html) の `FirstOrInit`、`FirstOrCreate` も確認してください。

詳細については [Raw SQL and SQL Builder](sql_builder.html) を参照してください。
