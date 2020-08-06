---
title: Create
layout: page
---

## Create Record

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

result := db.Create(&user) // データのポインタを渡す。

user.ID             // 挿入されたデータの主キーを返します。
result.Error        // エラーを返します。
result.RowsAffected // 挿入されたレコード数を返します。
```

## Create With Selected Fields

選んだフィールドで作成

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

選んだフィールド以外で作成

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## Create Hooks

GORMは `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate`をフックします。これらのメソッドはレコードを作成する際に呼び出されます。 [Hooks](hooks.html)を参照してください。

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

## <span id="batch_insert">Batch Insert</span>

スライスをメソッド `Create`に渡すと、GORMはすべてのデータを挿入する1つのSQL文を生成し、主キーの値をバックフィルします。フックメソッドも呼び出されます。

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
DB.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

[Upsert](#upsert), [Create With Associations](#create_with_associations) でもバッチインサートはサポートされています。

## Advanced

### <span id="create_with_associations">Create With Associations</span>

モデルがリレーションを定義し、リレーションがゼロ以外の場合、そのデータは作成時に保存されます。

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

`Select`, `Omit` によってアソシエーションによる保存をスキップできます。

```go
db.Omit("CreditCard").Create(&user)

// すべてのアソシエーションをスキップ
db.Omit(clause.Associations).Create(&user)
```

### Default Values

`default`タグによって、フィールドのデフォルト値を定義できます。例:

```go
type User struct {
  ID         int64
  Name       string `gorm:"default:'galeone'"`
  Age        int64  `gorm:"default:18"`
    uuid.UUID  UUID   `gorm:"type:uuid;default:gen_random_uuid()"` // db func
}
```

[ゼロ値](https://tour.golang.org/basics/12) フィールドは、データベースへの挿入の際にデフォルト値が使用されます。

**NOTE** Any zero value like `0`, `''`, `false` won't be saved into the database for those fields defined default value, you might want to use pointer type or Scanner/Valuer to avoid this, for example:

```go
type User struct {
  gorm.Model
  Name string
  Age  *int           `gorm:"default:18"`
  Active sql.NullBool `gorm:"default:true"`
}
```

**NOTE** You have to setup the `default` tag for fields having default value in databae or GORM will use the zero value of the field when creating, for example:

```go
type User struct {
    ID   string `gorm:"default:uuid_generate_v3()"`
    Name string
    Age  uint8
}
```

### <span id="upsert">Upsert / On Conflict</span>

GORMは異なるデータベースに対して互換性のあるUpsertのサポートを提供します。

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

`FirstOrInit`, `FirstOrCreate`については[Advanced Query](advanced_query.html)を参照してください。

詳細については、 [Raw SQL and SQL Builder](sql_builder.html) を参照してください。
