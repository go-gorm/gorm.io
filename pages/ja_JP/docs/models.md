---
title: モデルの宣言
layout: page
---

## モデルの宣言

モデルは Goの基本型、ポインタ/エイリアス、 [Scanner](https://pkg.go.dev/database/sql/sql#Scanner) および [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) インターフェイスを実装するカスタム型を持つ通常の構造体です。

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

GORMの方針は「設定より規約」です。デフォルトでは、GORMは主キーとしての`ID`、テーブル名を表すための複数形かつ`スネークケース`な構造体名、 `スネークケース`なカラム名、作成と更新の時間をトラッキングするための`CreatedAt`、`UpdatedAt`フィールドを利用します。

GORMで採用されている規則に従う場合は、設定やコードを記述する手間が激減します。 規則があなたの要件と一致しない場合、 [GORMはそれらを設定することができます](conventions.html)

## gorm.Model

GORMは `gorm.Model` 構造体を定義しました。これにはフィールド `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`が含まれます。

```go
// gorm.Modelの定義
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
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

## 高度な機能

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

GORMでは、規約により、`CreatedAt`, `UpdatedAt`を使用して、作成/更新時間を追跡しています。定義されている場合、GORMは作成/更新時に[current time](gorm_config.html#current_time)を利用することができます。

別の名前のフィールドを使用するには、タグ `autoCreateTime`、 `autoUpdateTime` を持つフィールドを設定できます。

time.Timeの代わりにUNIX (nano)秒を保存したい場合は、フィールドのデータ型を `time.Time` から `int` に変更するだけです。

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updaing or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix NANO seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

### <span id="embedded_struct">埋め込み構造体</span>

匿名フィールドの場合、GORMはそのフィールドをその親の構造体に含めます。例えば:

```go
type User struct {
  gorm.Model
  Name string
}
// これらは同じものです
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
}
```

通常の struct フィールドでは、タグ `embedded`を埋め込むことができます。例:

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
// 上と同じ意味です
type Blog struct {
  ID    int64
    Name  string
    Email string
  Upvotes  int32
}
```

また、タグ `embeddedrefix` を使用して、埋め込みフィールドの db 名にプレフィックスを追加することができます。例：

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


### フィールドタグ

タグはモデル宣言時に使用するオプションです。GORMは以下のタグをサポートしています。

タグ名の場合たいした関心ごとではありませんが、どちらかといえば `キャメルケース` を使用するのが好ましいです。

| タグ名            | 説明                                                                                                                                                                                                                                                                                                                                                                                                |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column         | カラム名                                                                                                                                                                                                                                                                                                                                                                                              |
| type           | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, which works with other tags, like `not null`, `size`, `autoIncrement`... specified database data type like `varbinary(8)` also supported, when using specified database data type, it needs to be a full database data type, for example: `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| size           | 列データのサイズ/長さを指定します。例: `size:256`                                                                                                                                                                                                                                                                                                                                                                   |
| primaryKey     | 主キーを含む列として指定                                                                                                                                                                                                                                                                                                                                                                                      |
| unique         | 一意な列として指定                                                                                                                                                                                                                                                                                                                                                                                         |
| default        | 列のデフォルト値を指定                                                                                                                                                                                                                                                                                                                                                                                       |
| precision      | 列の精度を指定                                                                                                                                                                                                                                                                                                                                                                                           |
| not null       | 列をNOT NULLで指定                                                                                                                                                                                                                                                                                                                                                                                     |
| autoIncrement  | 自動インクリメント可能な列として指定                                                                                                                                                                                                                                                                                                                                                                                |
| embedded       | フィールドの埋め込み                                                                                                                                                                                                                                                                                                                                                                                        |
| embeddedPrefix | 埋め込みフィールドのプレフィクス                                                                                                                                                                                                                                                                                                                                                                                  |
| autoCreateTime | track creating time when creating, `autoCreateTime:nano` track unix nano time for `int` fields                                                                                                                                                                                                                                                                                                    |
| autoUpdateTime | track updating time when creating/updating, `autoUpdateTime:nano` track unix nano time for `int` fields                                                                                                                                                                                                                                                                                           |
| index          | create index with options, same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                                                                                                                                                                                                                                                     |
| uniqueIndex    | `index`と同じですが、一意のインデックスを作成                                                                                                                                                                                                                                                                                                                                                                        |
| check          | creates check constraint, eg: `check:(age > 13)`, refer [Constraints](constraints.html)                                                                                                                                                                                                                                                                                                        |
| <-             | フィールドの書き込み権限を設定 `<-:create` 作成専用フィールド `<-:update` 更新専用フィールド`<-:false` 権限なし                                                                                                                                                                                                                                                                                                               |
| ->             | フィールドの読み取り権限を設定                                                                                                                                                                                                                                                                                                                                                                                   |
| -              | このフィールドを無視（読み取り/書き込み権限を無効にする）                                                                                                                                                                                                                                                                                                                                                                     |

### アソシエーションタグ

GORMでは外部キー、制約、関連タグを介した多数のテーブルを設定できます。詳細は [アソシエーションセクション](associations. html#tags) をご覧ください。
