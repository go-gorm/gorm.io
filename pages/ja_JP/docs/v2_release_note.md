---
title: GORM 2.0 リリースノート
layout: page
---

GORM2.0はスクラッチから書き直しているため、互換性のないAPIの変更と多くの改善が導入されています。

**Highlights**

* パフォーマンスの改善
* モジュール化
* Contextへの対応、Batch Insertの追加、Prepared State Modeの追加、DryRun Modeの追加、Join Preload機能の追加、Find結果のマップへの変換、マップでのCreate、FindInBatchesのサポート
* トランザクションのネスト、セーブポイント、セーブポイントへのロールバックのサポート
* SQL Builder、名前付き引数、集約条件、Upsert、ロック、Optimizer/Index/Comment Hintsのサポート、サブクエリの改善、SQL式とContext ValuerによるCRUD
* 自己参照の完全なサポート、テーブル結合の改善、大量データでのAssociation Modeの対応
* 複数フィールドでの作成・更新日時のトラッキング、Unix (ミリ・ナノ) 秒でのトラッキングのサポート
* フィールド権限のサポート：読み取り専用、書き込み専用、作成専用、更新専用、無視するフィールド
* 新しいプラグインシステム、複数データベースで使用可能な公式プラグインの提供、読み取り/書き込み分離、prometheusとのインテグレーション
* 新しいHooksのAPI：プラグインと統合されたインターフェイス
* 新しいマイグレーション処理：リレーション用の外部キーの作成への対応、スマートなAutoMigrate、制約/checkへの対応、強化されたインデックスのサポート
* 新しいLogger：contextへの対応、拡張性の向上
* 統一された命名規約：テーブル名、フィールド名、結合テーブル名、外部キー、Check制約、インデックス名のルール
* 独自のデータ型へのさらなるサポート（例：JSON）

## How To Upgrade

* GORMの開発は [github.com/go-gorm](https://github.com/go-gorm) に移行し、インポートパスが `gorm.io/gorm` に変わりました。以前のプロジェクトは `github.com/jinzhu/gorm` [GORM V1 Document](http://v1.gorm.io/) を利用できます。
* データベースドライバーは、以下のような別々のプロジェクトに分割されています。 [github.com/go-gorm/sqlite](https://github.com/go-gorm/sqlite) インポートパスも `gorm.io/driver/sqlite` に変更されました。

### Install

```go
go get gorm.io/gorm
// **Note** git `v2.0.0` with git tag `v1.20.0`
```

### Quick Start

```go
import (
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
)

func init() {
  db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})

  // 多くの CRUD API は互換性を保っています
  db.AutoMigrate(&Product{})
  db.Create(&user)
  db.First(&user, 1)
  db.Model(&user).Update("Age", 18)
  db.Model(&user).Omit("Role").Updates(map[string]interface{}{"Name": "jinzhu", "Role": "admin"})
  db.Delete(&user)
}
```

## Major Features

リリースノートはクイックリファレンスリストとしてGORMV2で導入された主要な変更のみをカバーしています

#### Context のサポート

* `WithContext` メソッドを使うことでデータベース操作における `context.Context` の利用をサポート
* Logger もトレースのために context を受け付けます

```go
db.WithContext(ctx).Find(&users)
```

#### Batch Insert

大量のレコードを効率的に挿入するには、スライスを `Create` メソッドに渡します。 スライスをメソッド Createメソッドに渡すと、GORMはすべてのデータを挿入する1つのSQL文を生成します（主キーの値は埋め戻しされます）。フックメソッドも呼び出されます。

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

`CreateInBatch` を利用する際にはバッチサイズを指定できます。

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// batch size 100
db.CreateInBatches(users, 100)
```

#### Prepared Statement Mode

Prepared Statement Mode はプリペアドステートメントを作成し、またその後の呼出を高速化するためにそれらをキャッシュします。

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

SQLを実行せずに生成のみ行い、生成されたSQLを確認またはテストするために使用できます。

```go
stmt := db.Session(&Session{DryRun: true}).Find(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 // PostgreSQL
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = ?  // MySQL
stmt.Vars         //=> []interface{}{1}
```

#### Joins による Preload

INNER JOIN を使用して関連データをPreloadし、scanに失敗しないようnullデータのハンドリングも行います。

```go
db.Joins("Company").Joins("Manager").Joins("Account").Find(&users, "users.id IN ?", []int{1,2})
```

#### 取得結果をマップに代入

レコードの取得結果を `map[string]interface{}` や `[]map[string]interface{}` にscanすることができます。

```go
var result map[string]interface{}
db.Model(&User{}).First(&result, "id = ?", 1)
```

#### Mapを使ってレコードを作成する

`map[string]interface{}` や `[]map[string]interface{}` でレコードを作成することができます。

```go
db.Model(&User{}).Create(map[string]interface{}{"Name": "jinzhu", "Age": 18})

datas := []map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 19},
  {"name": "jinzhu_2", "Age": 20},
}

db.Model(&User{}).Create(datas)
```

#### FindInBatches

バッチ処理におけるクエリやレコード処理を行うことができます。

```go
result := db.Where("age>?", 13).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  // batch processing
  return nil
})
```

#### トランザクションのネスト

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

#### 名前付き引数

GORMでは `sql.NamedArg`, `map[string]interface{}` を名前付き引数で使用できます。

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

#### 条件のグループ化

```go
db.Where(
  db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
  db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&pizzas)

// SELECT * FROM pizzas WHERE (pizza = 'pepperoni' AND (size = 'small' OR size = 'medium')) OR (pizza = 'hawaiian' AND size = 'xlarge')
```

#### サブクエリ

```go
// Where SubQuery
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)

// From SubQuery
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18}).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE age = 18

// Update SubQuery
db.Model(&user).Update(
  "price", db.Model(&Company{}).Select("name").Where("companies.id = users.company_id"),
)
```

#### Upsert

`clause.OnConflict` は複数のデータベース(SQLite, MySQL, PostgreSQL, SQL Server) に対応したUpsertを提供しています。

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

詳細については [Hints](hints.html) を参照してください。

#### SQL式/Context Valuer でのCRUD処理

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

詳細については [データ型のカスタマイズ](data_types.html#gorm_valuer_interface) を参照してください。

#### フィールドに対する権限

フィールド権限のサポートと権限レベル：読み取り専用、書き込み専用、作成専用、更新専用、無視するフィールド

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

#### 複数フィールドでの作成・更新時間のトラッキング／Unix (ミリ・ナノ) 秒でのトラッキング

```go
type User struct {
  CreatedAt time.Time // 作成時に値がゼロ値の場合、現在時間がセットされる
  UpdatedAt int       // 更新時、または作成時の値がゼロ値の場合、現在のUNIX秒がセットされる
  Updated   int64 `gorm:"autoUpdateTime:nano"` // 更新時間としてUNIXナノ秒を使用する
  Updated2  int64 `gorm:"autoUpdateTime:milli"`// 更新時間としてUNIXミリ秒を使用する
  Created   int64 `gorm:"autoCreateTime"`      // 作成時間としてUNIX秒を使用する
}
```

#### 複数データベース、読み取り/書き込み分離

GORMは `DB Resolver` プラグインでの複数データベース接続や読み取り／書き込みの分離をサポートしています。また、構造体やテーブルに基づくデータベースやテーブルの自動切替や、複数DBソース、独自のロードバランシングロジックを用いた複数レプリカもサポートしています。

詳細については、 [Database Resolver](dbresolver.html) を参照してください。

#### Prometheus

GORMは `Prometheus` プラグインを提供しており、これを利用して `DBStats` やユーザー定義のメトリクスを収集することができます。

詳細については [Prometheus](prometheus.html) を参照してください。

#### 命名戦略

GORMでは、デフォルトの `NamingStrategy` をオーバーライドすることで、デフォルトの命名規約を変更することができます。`NameingStrategy` は `TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName` の構築で利用されています。詳細については [GORM Config](gorm_config.html) を参照してください。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NamingStrategy: schema.NamingStrategy{TablePrefix: "t_", SingularTable: true},
})
```

#### Logger

* Context のサポート
* ログ出力時のカラーのカスタマイズ／出力オフ可能
* スロークエリログ（デフォルトのスロークエリの基準は200ms）
* データベースコンソールでのコピー・実行を可能にするSQLログフォーマットを最適化

#### Transaction Mode

デフォルトでは、すべてのGORMの書き込み操作はデータの一貫性を確保するためにトランザクション内で実行されます。 不要であれば初期化時にこれ無効化して、書き込み操作を高速化することもできます。

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

#### データ型（例：JSON）

独自型のサポートを最適化し、すべてのデータベースをサポートする構造体を定義することができます。

以下はJSONを例としてあげています。(SQLite、MySQL、Postgresをサポートしています。詳細は https://github.com/go-gorm/datatypes/blob/master/json.go を参照してください。)

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

GORMでは [``Select](query.html) を使用して、特定のフィールドのみ選択することができます。またV2では、より小さい構造体でレコードを取得する場合に向けて、smart select modeを提供しています。

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

Association Mode はデータの一括処理をサポートしています。例:

```go
// 全てのユーザの全役割を取得する
db.Model(&users).Association("Role").Find(&roles)

// 全ユーザのチームからユーザAを削除する
db.Model(&users).Association("Team").Delete(&userA)

// 重複を取り除いた全ユーザのチームの件数を取得する
db.Model(&users).Association("Team").Count()

// 一括処理で `Append` や `Replace` を使用する場合は、それらの関数の引数とデータの数（以下でいう users の数）が一致している必要があります。
// 一致していない場合はエラーが返却されます
var users = []User{user1, user2, user3}
// 例: 3人のユーザがいて、user1のチームにユーザA、user2のチームにユーザB、user3のチームにユーザABCを全員追加します
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// user1のチームをユーザAのみに、user2のチームをユーザBのみに、user3のチームをユーザABCのみにそれぞれリセットします
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

#### レコード削除時に関連付けを削除

レコード削除時に `Select` を使用することで、has one / has many / many2many 関係にある関連も同時に削除することができます。例:

```go
// ユーザ削除時に ユーザのアカウントも削除します
db.Select("Account").Delete(&user)

// ユーザ削除時に ユーザの注文とクレジットカードの関連レコードも削除します
db.Select("Orders", "CreditCards").Delete(&user)

// ユーザ削除時に ユーザ全ての has one / has many / many2many の関連レコードも削除します
db.Select(clause.Associations).Delete(&user)

// 複数ユーザ削除時に それぞれのユーザのアカウントも削除します
db.Select("Account").Delete(&users)
```

## 後方互換性のない変更

大きな破壊的変更やコンパイラで把握できない変更をリスト化しています。記載されていない破壊的変更を見つけた場合は、issue または pull request を [ここ](https://github.com/go-gorm/gorm.io) で作成することをお願いしています。

#### タグ

* GORM V2ではタグ名は `camelCase` となり、`snake_case` でのタグは無効になります。（例： `auto_increment`, `unique_index`, `polymorphic_value`, `embedded_prefix`）詳細は [モデルのタグ](models.html#tags) を参照してください。
* 外部キーを指定するために使用するタグは `foreignKey`, `references` に変更されました。詳細は [アソシエーションのタグ](associations.html#tags) を参照してください。

#### テーブル名

`TableName` は動的なテーブル名を *許可しなくなります* 。`TableName` の結果はのちの処理のためにキャッシュされます。

```go
func (User) TableName() string {
  return "t_user"
}
```

動的にテーブル名を変更するには、 `Scopes` を使用してください。例:

```go
func UserTable(u *User) func(*gorm.DB) *gorm.DB {
  return func(db *gorm.DB) *gorm.DB {
    return db.Table("user_" + u.Role)
  }
}

db.Scopes(UserTable(&user)).Create(&user)
```

#### テーブル作成・削除時のMigratorの使用必須化

以前は以下のようにテーブルを作成・削除することができました:

```go
db.CreateTable(&MyTable{})
db.DropTable(&MyTable{})
```

これからは以下のようになります:

```go
db.Migrator().CreateTable(&MyTable{})
db.Migrator().DropTable(&MyTable{})
```

####  外部キー

外部キー制約を追加する方法は以下のようにする必要がありました:

```go
db.Model(&MyTable{}).AddForeignKey("profile_id", "profiles(id)", "NO ACTION", "NO ACTION")
```

これからは以下のようにして制約を追加します:

```go
db.Migrator().CreateConstraint(&Users{}), "Profiles")
db.Migrator().CreateConstraint(&Users{}), "fk_users_profiles")
```

これは postgresの場合は以下のSQLコードに変換されます:

```sql
ALTER TABLE `Profiles` ADD CONSTRAINT `fk_users_profiles` FORIEGN KEY (`useres_id`) REFRENCES `users`(`id`))
```

#### Method Chain Safety/Goroutine Safety

GCアロケーションを削減するため、GORM V2では メソッドチェインを使用時に `Statement` を共有します。新しく初期化された `*gorm.DB` や `New Session Method` 後にのみ、新規の `Statement` インスタンスを作成します。`*gorm.DB` を再利用するには、`New Session Method` コール後であることを確認する必要があります。

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

詳細については [Method Chain](method_chaining.html) を参照してください。

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
