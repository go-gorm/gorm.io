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
  Name string `gorm:"<-:create"` // 読み取り、作成が可能
  Name string `gorm:"<-:update"` // 読み取り、更新が可能
  Name string `gorm:"<-"`        // 読み取り、書き込みが可能 (createとupdate)
  Name string `gorm:"<-:false"`  // 読み取り可能、書き込み無効
  Name string `gorm:"->"`        // 読み取り専用 (変更されない限り、書き込みが無効 )
  Name string `gorm:"->;<-:create"` // 読み取りと作成が可能
  Name string `gorm:"->:false;<-:create"` // 作成専用 (dbからの読み取りは無効)
  Name string `gorm:"-"`  // 構造体を使用した書き込みと読み込みの際にこのフィールドを無視する
  Name string `gorm:"migration"` // マイグレーション時にこのフィールドを無視する
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

| タグ名                    | 説明                                                                                                                                                                                                                                                                                                         |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column                 | データベースのカラム名                                                                                                                                                                                                                                                                                                |
| type                   | 列のデータ型を指定できます。bool, int, uint, float, string, time, bytes などの全てのデータベースで動作する一般的なデータ型と互換性のあるものが良いでしょう。また、`not null`, `size`, `autoIncrement`... などの他のタグと併用することも可能です。 `varbinary(8)` などの特定のデータベースでのみ使用可能なデータ型もサポートしていますが、それらのデータ型を使用する場合は、データ型をフルで指定する必要があります。例： `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| size                   | 列データのサイズ/長さを指定できます。例: `size:256`                                                                                                                                                                                                                                                                           |
| primaryKey             | 主キーとなる列を指定できます                                                                                                                                                                                                                                                                                             |
| unique                 | 一意な列として指定できます                                                                                                                                                                                                                                                                                              |
| default                | 列のデフォルト値を指定できます                                                                                                                                                                                                                                                                                            |
| precision              | 列の精度（小数の有効桁数）を指定できます                                                                                                                                                                                                                                                                                       |
| scale                  | 列の小数点以下桁数を指定できます                                                                                                                                                                                                                                                                                           |
| not null               | 列をNOT NULLに指定できます                                                                                                                                                                                                                                                                                          |
| autoIncrement          | AutoIncrement可能な列として指定できます                                                                                                                                                                                                                                                                                 |
| autoIncrementIncrement | AutoIncrementで処理毎にインクリメントされる値の増加分を指定できます                                                                                                                                                                                                                                                                   |
| embedded               | フィールドの埋め込みを指定できます                                                                                                                                                                                                                                                                                          |
| embeddedPrefix         | 埋め込まれたフィールドに対して、列名のプレフィックスを指定できます                                                                                                                                                                                                                                                                          |
| autoCreateTime         | 作成時に現在日時が自動で登録されるカラムを指定できます。 `int` 型のフィールドに対してはUNIX秒の値が設定されますが、ナノ秒/ミリ秒で登録したい場合は `nano`/`milli` を指定します。例： `autoCreateTime:nano`                                                                                                                                                                             |
| autoUpdateTime         | 作成/更新時に現在日時が自動で登録されるカラムを指定できます。 `int` 型のフィールドに対してはUNIX秒の値が設定されますが、ナノ秒/ミリ秒で登録したい場合は `nano`/`milli` を指定します。例： `autoUpdateTime:milli`                                                                                                                                                                         |
| index                  | オプション付きのインデックスを作成できます。複数のフィールドで同じ名前を使用した場合は複合インデックスが作成されます。詳細は [インデックス](indexes.html) を参照してください。                                                                                                                                                                                                           |
| uniqueIndex            | `index` と同じですが、こちらはユニークインデックスを作成します。                                                                                                                                                                                                                                                                       |
| check                  | CHECK制約を作成します（例： `check:age > 13` ）。[制約](constraints.html) も参照                                                                                                                                                                                                                                          |
| <-                     | フィールドの書き込み権限を設定します。`<-:create` は作成のみ可能、 `<-:update` は更新のみ可能、`<-:false` は書き込み権限がない、`<-` は作成／更新権限があることを意味します                                                                                                                                                                                     |
| ->                     | フィールドの読み込み権限を設定します。`->:false` は読み込み権限がないことを意味します                                                                                                                                                                                                                                                        |
| -                      | ignore this field, `-` no read/write permission, `-:migration` no migrate permission, `-:all` no read/write/migrate permission                                                                                                                                                                             |
| comment                | マイグレーション実行時にフィールドにコメントを追加できます                                                                                                                                                                                                                                                                              |

### アソシエーションで使用できるタグ

GORMではアソシエーション用のタグを使用することで、外部キー、制約、many2many（多対多）テーブルなどを設定できます。詳細は [Associations section](associations.html#tags) を参照してください。
