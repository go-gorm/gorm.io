---
title: モデルの宣言
layout: page
---
## モデルの宣言

Models are usually just normal Golang structs, basic Go types, or pointers of them. [`sql.Scanner`](https://golang.org/pkg/database/sql/#Scanner) and [`driver.Valuer`](https://golang.org/pkg/database/sql/driver/#Valuer) interfaces are also supported.

モデル例:

```go
type User struct {
  gorm.Model
  Name         string
  Age          sql.NullInt64
  Birthday     *time.Time
  Email        string  `gorm:"type:varchar(100);unique_index"`
  Role         string  `gorm:"size:255"` // フィールドサイズを255にセットします
  MemberNumber *string `gorm:"unique;not null"` // MemberNumberをuniqueかつnot nullにセットします
  Num          int     `gorm:"AUTO_INCREMENT"` // Numを自動インクリメントにセットします
  Address      string  `gorm:"index:addr"` // `addr`という名前のインデックスを作ります
  IgnoreMe     int     `gorm:"-"` // このフィールドは無視します
}
```

## 構造体のタグ

Tags are optional to use when declaring models. GORM supports the following tags:

### サポートされている構造体タグ

| タグ              | 説明                                              |
| --------------- | ----------------------------------------------- |
| Column          | カラム名を指定します                                      |
| Type            | カラムのデータ型を指定します                                  |
| Size            | カラムサイズのサイズを指定します。デフォルトは255です                    |
| PRIMARY_KEY     | カラムを主キーに指定します                                   |
| UNIQUE          | カラムにユニーク制約を指定します                                |
| DEFAULT         | カラムのデフォルト値を指定します                                |
| PRECISION       | カラムの精度を指定します                                    |
| NOT NULL        | カラムにNOT NULL制約を指定します                            |
| AUTO_INCREMENT  | カラムに自動インクリメントかそうでないかを指定します                      |
| INDEX           | 名前有りか名前無しでインデックスを作成します。同名のインデックスは複合インデックスになります。 |
| UNIQUE_INDEX    | `INDEX`と同様にユニークインデックスを作成します                     |
| EMBEDDED        | 埋め込み構造体に設定します                                   |
| EMBEDDED_PREFIX | 埋め込み構造体のプレフィックス名を設定します                          |
| -               | このフィールドを無視します                                   |

### 関連のための構造体のタグ

Check out the Associations section for details

| タグ                                 | 説明                      |
| ---------------------------------- | ----------------------- |
| MANY2MANY                          | joinするテーブル名を指定します       |
| FOREIGNKEY                         | 外部キーを指定します              |
| ASSOCIATION_FOREIGNKEY             | 関連する外部キーを指定します          |
| POLYMORPHIC                        | ポリモーフィック型を指定します         |
| POLYMORPHIC_VALUE                  | ポリモーフィック値を指定します         |
| JOINTABLE_FOREIGNKEY               | joinするテーブルの外部キーを指定します   |
| ASSOCIATION_JOINTABLE_FOREIGNKEY | joinするテーブルの関連外部キーを指定します |
| SAVE_ASSOCIATIONS                  | 関連を自動保存するか否か            |
| ASSOCIATION_AUTOUPDATE             | 関連を自動更新するか否か            |
| ASSOCIATION_AUTOCREATE             | 関連を自動生成するか否か            |
| ASSOCIATION_SAVE_REFERENCE       | 関連の参照を自動保存するか否か         |
| PRELOAD                            | 関連を自動プリロードするか否か         |