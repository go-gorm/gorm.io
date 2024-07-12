---
title: モデルを宣言する
layout: page
---

GORMは、Goの構造体をデータベーステーブルにマッピングすることで、データベースの相互作用を簡素化します。 GORMでモデルを宣言する方法を理解することは、その機能をフルに活用するための基本です。

## モデルを宣言する

モデルは通常の構造体を使用して定義されます。 これらの構造体には、`database/sql`パッケージの[Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner)インタフェースと[Valuer](https://pkg.go.dev/database/sql/driver#Valuer)インタフェースを実装している限り、基本的なGoの型、それらのポインタまたはエイリアス、あるいはカスタムタイプを含むフィールドを含めることができます。

`User` モデルの次の例を考えてみましょう。

```go
type User struct {
  ID           uint           // 主キーの標準フィールド
  Name         string         // 通常の文字列フィールド
  Email        *string        // 文字列へのポインタ、nullを許可
  Age          uint8          // 符号なし8ビット整数
  Birthday     *time.Time     // time.Timeへのポインタ。nullを許可
  MemberNumber sql.NullString // sql.NullStringを使用して、null可能な文字列をハンドリング
  ActivatedAt  sql.NullTime   // sql.NullTimeを使用したnull可能な時間フィールド
  CreatedAt    time.Time      // GORMによって自動的に管理される作成時間
  UpdatedAt    time.Time      // GORMによって自動的に管理される更新時間
}
```

このモデルでは:

- `uint`, `文字列`, および `uint8` のような基本的なデータ型が直接使用されます。
- `*string` や `*time.Time` のような型へのポインタは、null可能フィールドを示します。
- `sql.NullString` と `sql.NullTime` の `database/sql` パッケージは null可能フィールドでより多くの制御が可能です。
- `CreatedAt` と `UpdatedAt` は、レコードが作成または更新されたときにGORMが自動的に現在の時刻を入力する特別なフィールドです。

GORMにおけるモデル宣言の基本的な機能に加えて、シリアライザタグによるシリアライズのサポートに注目することが重要です。 この機能により、特にカスタム・シリアライズ・ロジックを必要とするフィールドについて、データの格納方法とデータベースからの取得方法の柔軟性が高まります。詳細な説明については [シリアライザー](serializer.html) を参照してください。

### 規約

1. **主キー**: GORMは各モデルのデフォルト主キーとして `ID` という名前のフィールドを使用します。

2. **テーブル名**: デフォルトでは、GORMは構造体名を `スネークケース` に変換し、テーブル名を複数形にします。 例えば、 `User` 構造体は、データベースの `users` テーブルになります。

3. **カラム名**: GORMは、データベース内のカラム名を自動的に `スネークケース` に変換します。

4. **タイムスタンプフィールド**: GORMは `Created` および `UpdatedAt` という名前のフィールドを使用して、レコードの作成と更新時間を自動的に追跡します。

Following these conventions can greatly reduce the amount of configuration or code you need to write. However, GORM is also flexible, allowing you to customize these settings if the default conventions don't fit your requirements. You can learn more about customizing these conventions in GORM's documentation on [conventions](conventions.html).

### `gorm.Model`

GORM provides a predefined struct named `gorm.Model`, which includes commonly used fields:

```go
// gorm.Modelの定義
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

- **Embedding in Your Struct**: You can embed `gorm.Model` directly in your structs to include these fields automatically. This is useful for maintaining consistency across different models and leveraging GORM's built-in conventions, refer [Embedded Struct](#embedded_struct)

- **Fields Included**:
  - `ID`: A unique identifier for each record (primary key).
  - `CreatedAt`: Automatically set to the current time when a record is created.
  - `UpdatedAt`: Automatically updated to the current time whenever a record is updated.
  - `DeletedAt`: Used for soft deletes (marking records as deleted without actually removing them from the database).

## 高度な機能

### <span id="field_permission">フィールドレベルの権限</span>

Exported fields have all permissions when doing CRUD with GORM, and GORM allows you to change the field-level permission with tag, so you can make a field to be read-only, write-only, create-only, update-only or ignored

{% note warn %}
**注意** GORM Migrator を使用してテーブルを作成した場合、除外設定されたフィールドは作成されません
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // 読み取り、作成が可能
  Name string `gorm:"<-:update"` // 読み取り、更新が可能
  Name string `gorm:"<-"`       // 読み取り、書き込みが可能 (createとupdate)
  Name string `gorm:"<-:false"`  // 読み取り可能、書き込み無効
  Name string `gorm:"->"`        // 読み取り専用 (変更されない限り、書き込みが無効 )
  Name string `gorm:"->;<-:create"` // 読み取りと作成が可能
  Name string `gorm:"->:false;<-:create"` // 作成専用 (dbからの読み取りは無効)
  Name string `gorm:"-"`            // 構造体を使用した書き込みと読み込みの際にこのフィールドを無視する
  Name string `gorm:"-:all"`        // 構造体を使用した書き込み、読み取り、マイグレーションの際にこのフィールドを無視する
  Name string `gorm:"-:migration"`  // マイグレーション時にこのフィールドを無視する
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

Tags are optional to use when declaring models, GORM supports the following tags: Tags are case insensitive, however `camelCase` is preferred. If multiple tags are used they should be separated by a semicolon (`;`). Characters that have special meaning to the parser can be escaped with a backslash (`\`) allowing them to be used as parameter values.

| タグ名                    | 説明                                                                                                                                                                                                                                                                                                          |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column                 | データベースのカラム名                                                                                                                                                                                                                                                                                                 |
| type                   | カラムのデータ型を指定します。bool, int, uint, float, string, time, bytes などの全てのデータベースで動作する一般的なデータ型と互換性のあるものが良いでしょう。また、`not null`, `size`, `autoIncrement`... などの他のタグと併用することも可能です。 `varbinary(8)` などの特定のデータベースでのみ使用可能なデータ型もサポートしていますが、それらのデータ型を使用する場合は、データ型をフルで指定する必要があります。例： `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| serializer             | specifies serializer for how to serialize and deserialize data into db, e.g: `serializer:json/gob/unixtime`                                                                                                                                                                                                 |
| size                   | specifies column data size/length, e.g: `size:256`                                                                                                                                                                                                                                                          |
| primaryKey             | 主キーとなるカラムを指定します                                                                                                                                                                                                                                                                                             |
| unique                 | specifies column as unique                                                                                                                                                                                                                                                                                  |
| default                | カラムのデフォルト値を指定します                                                                                                                                                                                                                                                                                            |
| precision              | specifies column precision                                                                                                                                                                                                                                                                                  |
| scale                  | specifies column scale                                                                                                                                                                                                                                                                                      |
| not null               | カラムをNOT NULLで指定します                                                                                                                                                                                                                                                                                          |
| autoIncrement          | specifies column auto incrementable                                                                                                                                                                                                                                                                         |
| autoIncrementIncrement | auto increment step, controls the interval between successive column values                                                                                                                                                                                                                                 |
| embedded               | embed the field                                                                                                                                                                                                                                                                                             |
| embeddedPrefix         | column name prefix for embedded fields                                                                                                                                                                                                                                                                      |
| autoCreateTime         | track current time when creating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoCreateTime:nano`                                                                                                                                       |
| autoUpdateTime         | track current time when creating/updating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoUpdateTime:milli`                                                                                                                             |
| index                  | create index with options, use same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                                                                                                                                                           |
| uniqueIndex            | same as `index`, but create uniqued index                                                                                                                                                                                                                                                                   |
| check                  | creates check constraint, eg: `check:age > 13`, refer [Constraints](constraints.html)                                                                                                                                                                                                                    |
| <-                     | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no write permission, `<-` create and update permission                                                                                                                                   |
| ->                     | set field's read permission, `->:false` no read permission                                                                                                                                                                                                                                               |
| -                      | ignore this field, `-` no read/write permission, `-:migration` no migrate permission, `-:all` no read/write/migrate permission                                                                                                                                                                              |
| comment                | add comment for field when migration                                                                                                                                                                                                                                                                        |

### アソシエーションで使用できるタグ

GORMではアソシエーション用のタグを使用することで、外部キー、制約、many2many（多対多）テーブルなどを設定できます。詳細は [Associations section](associations.html#tags) を参照してください。
