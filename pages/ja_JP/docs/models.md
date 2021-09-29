---
title: モデルを宣言する
layout: page
---

## モデルを宣言する

モデルは Goの基本型、（基本型の）ポインタ/エイリアス、 [Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner) および [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) インターフェイスを実装するカスタム型からなる通常の構造体です。

例：

```go
type User struct {
  ID           uint
  Name         string
  Email        *string
  Age          uint8
  Birthday     *time.Time
  MemberNumber sql.NullString
  ActivatedAt  sql.NullTime
  CreatedAt    time.Time
  UpdatedAt    time.Time
}
```

## 規約

GORMの方針は「設定より規約」です。デフォルトでは、GORMは主キーとしての`ID`、テーブル名を表すための複数形かつ`スネークケース`な構造体名、 `スネークケース`なカラム名、作成と更新の時間をトラッキングするための`CreatedAt`、`UpdatedAt`フィールドを利用します。

GORMで採用されている規約に従うと、設定やコードを記述する手間が大幅に減少します。 要件が規約と一致しない場合、 [GORMではそれらを設定を変更することができます](conventions.html)

## gorm.Model

GORMは `gorm.Model` 構造体を定義しています。これには `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt` のフィールドが含まれます。

```go
// gorm.Modelの定義
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

この構造体を埋め込むことで、これらのフィールドを自身の構造体に含めることができます。 [Embedded Struct](#embedded_struct) も参照してください。

## 高度な機能

### <span id="field_permission">フィールドレベルの権限</span>

エクスポートされているフィールドは、GORMでのCRUD操作が全て可能となっていますが、タグでフィールドレベルの権限を変更することができます。 これにより、読み取り専用、書き込み専用、作成専用、更新専用、または除外するフィールドを作成できます。

{% note warn %}
**注意** GORM Migrator を使用してテーブルを作成した場合、除外設定されたフィールドは作成されません
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // allow read and create
  Name string `gorm:"<-:update"` // allow read and update
  Name string `gorm:"<-"`        // allow read and write (create and update)
  Name string `gorm:"<-:false"`  // allow read, disable write permission
  Name string `gorm:"->"`        // readonly (disable write permission unless it configured )
  Name string `gorm:"->;<-:create"` // allow read and create
  Name string `gorm:"->:false;<-:create"` // createonly (disabled read from db)
  Name string `gorm:"-"`  // ignore this field when write and read with struct
}
```

### <name id="time_tracking">作成・更新日時のトラッキング／Unix (ミリ・ナノ) 秒でのトラッキング</span>

GORMの規約では、作成/更新時間をトラッキングするのに `CreatedAt`, `UpdatedAt` を使用します。それらのフィールドがモデルに定義されている場合、作成/更新時間に[現在時刻](gorm_config.html#now_func)を値としてセットします。

別の名前のフィールドを使用する場合、 `autoCreateTime`、 `autoUpdateTime` タグを使用することで設定を変更することができます。

time.Timeの代わりにUNIX (ミリ/ナノ) 秒を保存したい場合、フィールドのデータ型を `time.Time` から `int` に変更するだけで保存が可能になります。

```go
type User struct {
  CreatedAt time.Time // 作成時に値がゼロ値の場合、現在時間がセットされる
  UpdatedAt int       // 更新時、または作成時の値がゼロ値の場合、現在のUNIX秒がセットされる
  Updated   int64 `gorm:"autoUpdateTime:nano"` // 更新時間としてUNIXナノ秒を使用する
  Updated   int64 `gorm:"autoUpdateTime:milli"`// 更新時間としてUNIX msを使用する
  Created   int64 `gorm:"autoCreateTime"`      // 作成時間としてUNIX秒を使用する
}
```

### <span id="embedded_struct">構造体の埋め込み</span>

匿名（anonymous field）フィールドでモデルの定義がなされている場合、埋め込まれた構造体のフィールドは親の構造体のフィールドとして含まれることになります。例：

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

通常のフィールドで構造体の定義がなされている場合、 `embedded` タグを使用して構造体の埋め込みを行うことができます。例：

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

また、 `embeddedPrefix` タグを使用することで、埋め込まれた構造体のフィールド名にプレフィックスを追加することができます。例：

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


### <span id="tags">フィールドに指定可能なタグ</span>

タグはモデル宣言時に任意で使用できます。GORMは以下のタグをサポートしています。（タグは大文字小文字を区別しませんが、 `camelCase` が推奨されます）

| タグ名                    | 説明                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column                 | データベースのカラム名                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| type                   | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, which works for all databases, and can be used with other tags together, like `not null`, `size`, `autoIncrement`... specified database data type like `varbinary(8)` also supported, when using specified database data type, it needs to be a full database data type, for example: `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| size                   | 列データのサイズ/長さを指定します。例: `size:256`                                                                                                                                                                                                                                                                                                                                                                                                               |
| primaryKey             | 主キーを含む列として指定                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| unique                 | 一意な列として指定                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| default                | 列のデフォルト値を指定                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| precision              | 列の精度を指定                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| scale                  | specifies column scale                                                                                                                                                                                                                                                                                                                                                                                                                        |
| not null               | specifies column as NOT NULL                                                                                                                                                                                                                                                                                                                                                                                                                  |
| autoIncrement          | specifies column auto incrementable                                                                                                                                                                                                                                                                                                                                                                                                           |
| autoIncrementIncrement | auto increment step, controls the interval between successive column values                                                                                                                                                                                                                                                                                                                                                                   |
| embedded               | embed the field                                                                                                                                                                                                                                                                                                                                                                                                                               |
| embeddedPrefix         | column name prefix for embedded fields                                                                                                                                                                                                                                                                                                                                                                                                        |
| autoCreateTime         | track current time when creating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoCreateTime:nano`                                                                                                                                                                                                                                                                         |
| autoUpdateTime         | track current time when creating/updating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoUpdateTime:milli`                                                                                                                                                                                                                                                               |
| index                  | create index with options, use same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                                                                                                                                                                                                                                                                                             |
| uniqueIndex            | same as `index`, but create uniqued index                                                                                                                                                                                                                                                                                                                                                                                                     |
| check                  | creates check constraint, eg: `check:age > 13`, refer [Constraints](constraints.html)                                                                                                                                                                                                                                                                                                                                                      |
| <-                     | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no write permission, `<-` create and update permission                                                                                                                                                                                                                                                                     |
| ->                     | set field's read permission, `->:false` no read permission                                                                                                                                                                                                                                                                                                                                                                                 |
| -                      | ignore this field, `-` no read/write permission                                                                                                                                                                                                                                                                                                                                                                                               |
| comment                | add comment for field when migration                                                                                                                                                                                                                                                                                                                                                                                                          |

### Associations Tags

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
