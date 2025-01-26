---
title: モデルを宣言する
layout: page
---

GORMは、Goの構造体をデータベーステーブルにマッピングすることで、データベースの相互作用を簡素化します。 GOMRの機能をフルに活用するために、基本となるモデルの宣言方法を理解しましょう。

## モデルを宣言する

モデルは通常の構造体を使用して定義されます。 これらの構造体には、`database/sql`パッケージの[Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner)インタフェースと[Valuer](https://pkg.go.dev/database/sql/driver#Valuer)インタフェースを実装している限り、基本的なGoの型、それらのポインタまたはエイリアス、あるいはカスタムタイプを含むフィールドを含めることができます。

`User` モデルの次の例を考えてみましょう。

```go
type User struct {
  ID           uint           // 主キーの標準フィールド
  Name         string         // 通常の文字列フィールド
  Email        *string        // 文字列へのポインタ、nullを許容
  Age          uint8          // 符号なし8ビット整数
  Birthday     *time.Time     // time.Timeへのポインタ。nullを許容
  MemberNumber sql.NullString // sql.NullStringを使用してnull許容文字列に対応
  ActivatedAt  sql.NullTime   // sql.NullTimeを使用したnull許容の時間フィールド
  CreatedAt    time.Time      // GORMによって自動的に管理される作成時間
  UpdatedAt    time.Time      // GORMによって自動的に管理される更新時間
  ignored      string         // エクスポートされていないフィールドは無視される
}
```

このモデルは次のように扱われます。

- `uint`, `string`, および `uint8` のような基本的なデータ型がそのまま使用されます。
- `*string` や `*time.Time` のような型へのポインタは、null許容型のフィールドを示します。
- `database/sql` パッケージの `sql.NullString` と `sql.NullTime` を使用することで、null許容フィールドを細かく制御できます。
- `CreatedAt` と `UpdatedAt` は特別なフィールドとして扱われ、レコードが作成または更新されたとき、GORMが自動的に現在の時刻をセットします。
- エクスポートされていないフィールド（先頭が小文字）はマップされません

GORMにおけるモデル宣言の基本的な機能に加えて、シリアライザタグによるシリアライズのサポートに注目することが重要です。 この機能により、特にカスタム・シリアライズ・ロジックを必要とするフィールドについて、データの格納方法とデータベースからの取得方法の柔軟性が高まります。詳細な説明については [シリアライザー](serializer.html) を参照してください。

### 規約

1. **主キー**: GORMは各モデルのデフォルト主キーとして `ID` という名前のフィールドを使用します。

2. **テーブル名**: デフォルトでは、GORMは構造体名を `スネークケース` に変換し、テーブル名を複数形にします。 たとえば、 `User` 構造体はデータベース内では `users` になり、 `GormUserName` は `gorm_user_names` になります。

3. **カラム名**: GORMは、データベース内のカラム名を自動的に `スネークケース` に変換します。

4. **タイムスタンプフィールド**: GORMは `Created` および `UpdatedAt` という名前のフィールドを使用して、レコードの作成と更新時間を自動的に追跡します。

次の規約に従うことで、コンフィグやコードを書く量を大幅に減らすことができます。 もちろん、GORMには柔軟性があるため、標準の規約が要件に沿わない場合はこれらの設定をカスタマイズすることもできます。 規約のカスタマイズについては、GORMドキュメントの [規約](conventions.html)を参照してください。

### `gorm.Model`

GORMで使用できる定義済み構造体 `gorm.Model`には、一般的に使用される以下のフィールドが含まれます。

```go
// gorm.Modelの定義
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

- **構造体への埋め込み**: あなたが作成した構造体に `gorm.Model` を直接埋め込むことで、これらのフィールドを自動的に含めることができます。 これは、異なる複数のモデル間で一貫性を維持し、GORMの組み込み規則を活用する場合に便利です。参照: [構造体の埋め込み](#embedded_struct)

- **フィールド**:
  - `ID`: 各レコードの一意の識別子（主キー）。
  - `CreatedAt`: レコードの作成時に自動的に現在時刻がセットされます。
  - `UpdatedAt`: レコードが更新されるたびに、自動的に現在の時刻に更新されます。
  - `DeletedAt`: 論理削除（実際にはデータベースからレコードを削除せず、削除済みとしてマークする）に使用されます。

## 高度な機能

### <span id="field_permission">フィールドレベルの権限</span>

エクスポートされたフィールドはGORMでCRUDを実行するための権限をすべて持ちます。フィールド単位で権限を変更したいときはタグを使用することにより、特定のフィールドを読み取り専用、書き込み専用、作成専用、更新専用、あるいは無視にすることができます。

{% note warn %}
**注意** GORM Migrator を使用してテーブルを作成した場合、除外設定されたフィールドは作成されません
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // 読み取り、作成が可能
  Name string `gorm:"<-:update"` // 読み取り、更新が可能
  Name string `gorm:"<-"`        // 読み取り、書き込み (createとupdate) が可能
  Name string `gorm:"<-:false"`  // 読み取り可能、書き込み無効
  Name string `gorm:"->"`        // 読み取り専用 (変更されない限り、書き込みが無効)
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
  Updated   int64 `gorm:"autoUpdateTime:milli"`// 更新時間としてUNIXミリ秒を使用する
  Created   int64 `gorm:"autoCreateTime"`      // 作成時間としてUNIX秒を使用する
}
```

### <span id="embedded_struct">構造体の埋め込み</span>

匿名（anonymous field）フィールドでモデルの定義がなされている場合、埋め込まれた構造体のフィールドは親の構造体のフィールドとして含まれることになります。例：

```go
type Author struct {
  Name  string
  Email string
}

type Blog struct {
  Author
  ID      int
  Upvotes int32
}
// 上記は下記と同等
type Blog struct {
  ID      int64
  Name    string
  Email   string
  Upvotes int32
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

タグはモデル宣言時に任意で使用できます。GORMは以下のタグをサポートしています。大文字小文字は区別されませんが、`camelCase` にすることを推奨します。 複数のタグを使用するには、セミコロン (`;`)で区切ります。 パーサーにとって特別な意味を持つ文字は、バックスラッシュ (`\`) でエスケープすることでパラメーターの値として使用できます。

| タグ名                    | 説明                                                                                                                                                                                                                                                                                                          |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column                 | データベースのカラム名                                                                                                                                                                                                                                                                                                 |
| type                   | カラムのデータ型を指定します。bool, int, uint, float, string, time, bytes などの全てのデータベースで動作する一般的なデータ型と互換性のあるものが良いでしょう。また、`not null`, `size`, `autoIncrement`... などの他のタグと併用することも可能です。 `varbinary(8)` などの特定のデータベースでのみ使用可能なデータ型もサポートしていますが、それらのデータ型を使用する場合は、データ型をフルで指定する必要があります。例： `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| serializer             | データを直列化および並列化するためのシリアライザを指定します。例: `serializer:json/gob/unixtime`                                                                                                                                                                                                                                            |
| size                   | カラムのデータサイズ/長さを指定します。例: `size:256`                                                                                                                                                                                                                                                                           |
| primaryKey             | 主キーとなるカラムを指定します                                                                                                                                                                                                                                                                                             |
| unique                 | カラムを一意として指定します。                                                                                                                                                                                                                                                                                             |
| default                | カラムのデフォルト値を指定します                                                                                                                                                                                                                                                                                            |
| precision              | カラムの精度を指定します                                                                                                                                                                                                                                                                                                |
| scale                  | カラムの位取りを指定します                                                                                                                                                                                                                                                                                               |
| not null               | カラムをNOT NULLで指定します                                                                                                                                                                                                                                                                                          |
| autoIncrement          | カラムが自動でインクリメントされるように指定します                                                                                                                                                                                                                                                                                   |
| autoIncrementIncrement | 自動インクリメントによって加算される値                                                                                                                                                                                                                                                                                         |
| embedded               | フィールドを埋め込みます                                                                                                                                                                                                                                                                                                |
| embeddedPrefix         | 埋め込みフィールドのカラム名に付く接頭語句                                                                                                                                                                                                                                                                                       |
| autoCreateTime         | カラムの作成時に現在日時を自動でセットします。`int` 型のフィールドに対してはUNIX秒でセットされます。ナノ秒/ミリ秒でセットしたい場合は値に `nano`/`milli` を指定します。例: `autoCreateTime:nano`                                                                                                                                                                                   |
| autoUpdateTime         | カラムの作成時/更新時に現在日時を自動でセットします。`int` 型のフィールドに対してはUNIX秒でセットされます。ナノ秒/ミリ秒でセットしたい場合は値に `nano`/`milli` を指定します。例: `autoUpdateTime: milli`                                                                                                                                                                             |
| index                  | インデックスを作成します。複数のフィールドで同じ名前を使用した場合は複合インデックスが作成されます。詳細は[インデックス](indexes.html)を参照してください。                                                                                                                                                                                                                       |
| uniqueIndex            | `index` と同様です。ただし、一意なインデックスを作成します。                                                                                                                                                                                                                                                                          |
| check                  | CHECK制約を作成します（例: `check:age > 13` ）。[制約](constraints.html)を参照のこと                                                                                                                                                                                                                                         |
| <-                     | フィールドの書き込み権限を設定します。`<-:create`: 作成のみ可能。`<-:update`: 更新のみ可能。`<-:false`: 書き込み権限なし。`<-`: 作成/更新権限あり。                                                                                                                                                                                                |
| ->                     | フィールドの読み込み権限を設定します。`->:false`: 読み込み権限なし。                                                                                                                                                                                                                                                                 |
| -                      | フィールドを無視します。 `-`: 読み取り/書き込み権限なし。`-:migration`: マイグレーション権限なし。`-:all`: 読み取り/書き込み/マイグレーション権限なし。                                                                                                                                                                                                                |
| comment                | マイグレーション実行時にフィールドにコメントを追加します                                                                                                                                                                                                                                                                                |

### アソシエーションで使用できるタグ

GORMではアソシエーション用のタグを使用することで、外部キー、制約、many2many（多対多）テーブルなどを設定できます。詳細は [Associations section](associations.html#tags) を参照してください。
