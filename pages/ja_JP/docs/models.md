---
title: モデルの宣言
layout: page
---

## モデルの宣言

モデルは基本的な Go 型、ポインタ/エイリアス、 [Scanner](https://pkg.go.dev/database/sql/sql#Scanner) および [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) インターフェイスを実装するカスタム型を持つ通常の構造体です。

例：

```go
type User struct {
  ID           uint
  Name         string
  Email        *string
  Age          uint8
  Birthday     *time.Time
  MemberNumber sql.NullString
  ActivedAt    sql.NullTime
  CreatedAt    time.Time
  UpdatedAt    time.Time
}
```

## 規約

GORMは「設定より規約」を好みます。デフォルトでは、GORMは主キーとしての`ID`、テーブル名を表すための複数形かつ`スネークケース`な構造体名、 `スネークケース`なカラム名、作成時と更新時をトラッキングするための`CreatedAt`、`UpdatedAt`フィールドを利用します。

GORMで採用されている規則に従う場合は、設定やコードを記述する手間が激減します。 規則があなたの要件と一致しない場合、 [GORMはそれらを設定することができます](conventions.html)

## gorm.Model

GORMは `gorm.Model` 構造体を定義しました。これにはフィールド `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`が含まれます。

```go
// gorm.Model定義
type Model struct {
  ID uint `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.
  DeletedAt `gorm:"index"`
}
```

これらのフィールドを含めるには、構造体に埋め込むことができます。 [埋め込み構造体](#embedded_struct)

```go
type User struct {
  gorm.Model
  Name string
}
// これら２つは同じものです
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
}
```

## 上級者向け

### フィールドレベルの権限

エクスポートされたフィールドはGORMでCRUDを実行するときにすべての権限を持ちますが、GORMはタグでフィールドレベルの権限を変更することができます。 これにより、読み取り専用、書き込み専用、作成専用、更新専用、または無視するフィールドを作成できます。

```go
type User struct {
  Name string `gorm:"<-:create"` // 読み取り、作成が可能
  Name string `gorm:"<-:update"` // 読み取り、更新が可能
  Name string `gorm:"<-"`        // 読み取り、書き込みが可能 (createとupdateの両方)
  Name string `gorm:"<-:false"`  // 読み取り可能、書き込み無効
  Name string `gorm:"->"`        //  読み取り専用 (設定されていない限り、書き込みを無効にします。 )
  Name string `gorm:"->;<-:create"` // 読み取りと作成が可能
  Name string `gorm:"->:false;<-:create"` // 作成専用 (dbからの読み取りは無効)
  Name string `gorm:"-"`  // 書き込みと読み込みの際にこのフィールドを無視します。
}
```

### <name id="time_tracking">Auto Creating/Updating Time/Unix (Nano) Second</span>

GORM use `CreatedAt`, `UpdatedAt` to track creating/updating time by convention, and GORM will fill [current time](gorm_config.html#current_time) into it when creating/updating if they are defined

To use fields with a different name, you can configure those fields with tag `autoCreateTime`, `autoUpdateTime`

If you prefer to save UNIX (nano) seconds instead of time, you can simply change the field's data type from `time.Time` to `int`

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updaing or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix NANO seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

### <span id="embedded_struct">Embedded Struct</span>

For anonymous fields, GORM will include its fields into its parent struct, for example:

```go
type User struct {
  gorm.Model
  Name string
}
// equals
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
}
```

For a normal struct field, you can embed it with the tag `embedded`, for example:

```go
type Author struct {
    Name  string
    Email string
}

type Blog struct {
  ID      int
  Author  Author `gorm:"embedded"`
  Upvotes int32
}
// equals
type Blog struct {
  ID    int64
    Name  string
    Email string
  Upvotes  int32
}
```

And you can use tag `embeddedrefix` to add prefix to embedded fields' db name, for example:

```go
type Blog struct {
  ID      int
  Author  Author `gorm:"embedded;embeddedPrefix:author_"`
  Upvotes int32
}
// equals
type Blog struct {
  ID          int64
    AuthorName  string
    AuthorEmail string
  Upvotes     int32
}
```


### Fields Tags

Tags are optional to use when declaring models, GORM supports the following tags:

Tag Name case doesn't matter, `camelCase` is preferred to use.

| Tag Name       | Description                                                                                                                                                              |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| column         | column db name                                                                                                                                                           |
| type           | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, specified database data type like varbinary(8) also supported |
| size           | specifies column data size/length, e.g: `size:256`                                                                                                                       |
| primaryKey     | specifies column as primary key                                                                                                                                          |
| unique         | specifies column as unique                                                                                                                                               |
| default        | specifies column default value                                                                                                                                           |
| precision      | specifies column precision                                                                                                                                               |
| not null       | specifies column as NOT NULL                                                                                                                                             |
| autoIncrement  | specifies column auto incrementable                                                                                                                                      |
| embedded       | embed a field                                                                                                                                                            |
| embeddedPrefix | prefix for embedded field                                                                                                                                                |
| autoCreateTime | track creating time when creating, `autoCreateTime:nano` track unix nano time for `int` fields                                                                           |
| autoUpdateTime | track updating time when creating/updating, `autoUpdateTime:nano` track unix nano time for `int` fields                                                                  |
| index          | create index with options, same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                            |
| uniqueIndex    | same as `index`, but create uniqued index                                                                                                                                |
| check          | creates check constraint, eg: `check:(age > 13)`, refer [Constraints](constraints.html)                                                                               |
| <-             | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no permission                                            |
| ->             | set field's read permission                                                                                                                                              |
| -              | ignore this fields (disable read/write permission)                                                                                                                       |

### Associations Tags

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
