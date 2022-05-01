---
title: 規約
layout: page
---

## 主キーとしての `ID`

GORMはデフォルトで、テーブルの主キーとして `ID` という名前のフィールドを使用します。

```go
type User struct {
  ID   string //フィールドはデフォルトでは `ID` という名前のフィールドがプライマリフィールドとして使われます。
  Name string
}
```

他のフィールドを `primaryKey` タグで主キーとして設定できます

```go
// Set field `UUID` as primary field
type Animal struct {
  ID     int64
  UUID   string `gorm:"primaryKey"`
  Name   string
  Age    int64
}
```

[Composite Primary Key](composite_primary_key.html) も参照してください。

## 複数形のテーブル名

GORMは構造体名をテーブル名として`snake_cases`のように複数形にします。構造体 `User` の場合、対応するテーブル名は規約により `users` となります。

### テーブル名

`Tabler` インターフェイスを実装することで、デフォルトのテーブル名を変更することができます。例：

```go
type Tabler interface {
    TableName() string
}

// TableName overrides the table name used by User to `profiles`
func (User) TableName() string {
  return "profiles"
}
```

{% note warn %}
**注意** メソッドの戻り値はキャッシュされるため、 `TableName`は動的な名前を許可していません。動的にテーブル名を変更するには、 `Scopes` で解決することができます。例:
{% endnote %}

```go
func UserTable(user User) func (tx *gorm.DB) *gorm.DB {
  return func (tx *gorm.DB) *gorm.DB {
    if user.Admin {
      return tx.Table("admin_users")
    }

    return tx.Table("users")
  }
}

db.Scopes(UserTable(user)).Create(&user)
```

### 一時的に名前を指定する

`Table`メソッドで一時的にテーブル名を指定できます。例:

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

`TableName`, `ColumnName`, `JoinTableName`, `RelationshipFKName`, `CheckerName`, `IndexName`の生成に使用されている`NamingStrategy`をオーバーライドすることで、デフォルトの命名規則を変更できます。詳細は[GORM Config](gorm_config.html#naming_strategy)を参照してください。

## カラム名

規約に従い、データベースのカラム名はフィールド名の`snake_case`を使用します。

```go
type User struct {
  ID        uint      // column name is `id`
  Name      string    // column name is `name`
  Birthday  time.Time // column name is `birthday`
  CreatedAt time.Time // column name is `created_at`
}
```

`column` タグか [`NamingStrategy`](#naming_strategy) を利用することでカラム名を上書きできます。

```go
type Animal struct {
  AnimalID int64     `gorm:"column:beast_id"`         // set name to `beast_id`
  Birthday time.Time `gorm:"column:day_of_the_beast"` // set name to `day_of_the_beast`
  Age      int64     `gorm:"column:age_of_the_beast"` // set name to `age_of_the_beast`
}
```

## タイムスタンプのトラッキング

### CreatedAt

`CreatedAt`フィールドを持つモデルの場合、フィールドの値がゼロ値であれば、レコード作成時に現在時刻が設定されます。

```go
db.Create(&user) // set `CreatedAt` to current time

user2 := User{Name: "jinzhu", CreatedAt: time.Now()}
db.Create(&user2) // user2's `CreatedAt` won't be changed

// To change its value, you could use `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

You can disable the timestamp tracking by setting `autoCreateTime` tag to `false`, for example:

```go
type User struct {
  CreatedAt time.Time `gorm:"autoCreateTime:false"`
}
```

### UpdatedAt

For models having `UpdatedAt` field, the field will be set to the current time when the record is updated or created if its value is zero

```go
db.Save(&user) // set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time

db.Model(&user).UpdateColumn("name", "jinzhu") // `UpdatedAt` won't be changed

user2 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Create(&user2) // user2's `UpdatedAt` won't be changed when creating

user3 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Save(&user3) // user3's `UpdatedAt` will change to current time when updating
```

You can disable the timestamp tracking by setting `autoUpdateTime` tag to `false`, for example:

```go
type User struct {
  UpdatedAt time.Time `gorm:"autoUpdateTime:false"`
}
```

{% note %}
**NOTE** GORM supports having multiple time tracking fields and track with UNIX (nano/milli) seconds, checkout [Models](models.html#time_tracking) for more details
{% endnote %}
