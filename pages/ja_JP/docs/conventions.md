---
title: Conventions
layout: page
---

## `ID` as Primary Key

GORMはデフォルトで、テーブルの主キーとして `ID` という名前のフィールドを使用します。

```go
type User struct {
  ID   string //フィールドはデフォルトでは `ID` という名前のフィールドがプライマリフィールドとして使われます。
  Name string
}
```

他のフィールドを `primaryKey` タグで主キーとして設定できます

```go
// `AnimalID`フィールドをプライマリフィールドとして設定します
type Animal struct {
  ID     int64
  UUID   string `gorm:"primaryKey"`
  Name   string
  Age    int64
}
```

[Composite Primary Key](composite_primary_key.html) も参照してください。

## Pluralized Table Name

GORMは構造体名をテーブル名として`snake_cases`のように複数形にします。構造体 `User` の場合、対応するテーブル名は規約により `users` となります。

### TableName

`Tableer` インターフェイスを実装することで、デフォルトのテーブル名を変更することができます。例：

```go
type Tabler interface {
    TableName() string
}

// TableName overrides the table name used by User to `profiles`
func (User) TableName() string {
  return "profiles"
}
```

**注：**`TableName`は動的な名前を許可していません、その結果は将来のためにキャッシュされます、動的な名前を使用するには、次のコードを使用することができます。

```go
func UserTable(user User) func (db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    if user.Admin {
      return db.Table("admin_users")
    }

    return db.Table("users")
  }
}

DB.Scopes(UserTable(user)).Create(&user)
```

### Temporarily specify a name

`Table`メソッドで一時的にテーブル名を指定できます。例：

```go
// Create table `deleted_users` with struct User's fields
db.Table("deleted_users").AutoMigrate(&User{})

// Query data from another table
var deletedUsers []User
db.Table("deleted_users").Find(&deletedUsers)
// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete(&User{})
// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

FROM句でサブクエリを使用する方法については、 [From SubQuery](advanced_query.html#from_subquery) を参照してください。

### <span id="naming_strategy">NamingStrategy</span>

`TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`の構築に使用されている`NamingStrategy`をオーバーライドすることで、デフォルトの命名規則を変更できます。詳細は[GORM Config](gorm_config.html)を参照してください。

## Column Name

規約によって、データベースのカラム名はフィールドの名前の`snake_case`を使用します。

```go
type User struct {
  ID        uint      // column name is `id`
  Name      string    // column name is `name`
  Birthday  time.Time // column name is `birthday`
  CreatedAt time.Time // column name is `created_at`
}
```

`column`タグか[`NamingStrategy`](#naming_strategy)を利用することでカラム名を上書きできます。

```go
type Animal struct {
  AnimalID int64     `gorm:"column:beast_id"`         // set name to `beast_id`
  Birthday time.Time `gorm:"column:day_of_the_beast"` // set name to `day_of_the_beast`
  Age      int64     `gorm:"column:age_of_the_beast"` // set name to `age_of_the_beast`
}
```

## Timestamp Tracking

### CreatedAt

`CreatedAt`フィールドを持つモデルの場合、値がゼロ値であり、レコードが最初に作成されたとき、フィールドは現在時刻に設定されます

```go
db.Create(&user) // set `CreatedAt` to current time

// To change its value, you could use `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

### UpdatedAt

`UpdatedAt`フィールドを持つモデルの場合、値がゼロ値であり、レコードが更新または作成されると、フィールドは現在時刻に設定されます。

```go
db.Save(&user) // set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time
```

**注：**GORMは複数の時間トラッキングフィールド、他のフィールドとのトラッキング、UNIX秒/UNIXナノ秒でのトラッキングをサポートしています。詳細は[ Models](models.html#time_tracking)を参照してください。
