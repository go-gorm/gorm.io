---
title: Declaring Models
layout: page
---
## モデルの宣言

モデルは通常、単なる普通のGolangの構造体、Goの基本的な型、それらのポインタ、[`sql.Scanner`](https://golang.org/pkg/database/sql/#Scanner)、[`driver.Valuer`](https://golang.org/pkg/database/sql/driver/#Valuer)インタフェースをサポートします。

モデル例:

```go
type User struct {
  gorm.Model
  Name         string
  Age          sql.NullInt64
  Birthday     *time.Time
  Email        string  `gorm:"type:varchar(100);unique_index"`
  Role         string  `gorm:"size:255"` // フィールドサイズを255にセットします
  MemberNumber *string `gorm:"unique;not null"` // MemberNumberをuniqueかつnot
 nullにセットします
  Num          int     `gorm:"AUTO_INCREMENT"` // Numを自動インクリメントにセットします
  Address      string  `gorm:"index:addr"` // `addr`という名前のインデックスを作ります
  IgnoreMe     int     `gorm:"-"` // このフィールドは無視します
}
```

## 構造体のタグ

タグはモデル宣言時に任意で使用します。GORMがサポートするタグは以下の通りです。

### サポートされている構造体タグ

| タグ              | 説明                                                                     |
| --------------- | ---------------------------------------------------------------------- |
| Column          | カラム名を指定します                                                             |
| Type            | カラムのデータ型を指定します                                                         |
| Size            | カラムサイズのデフォルトサイズを255に指定します                                              |
| PRIMARY_KEY     | カラムを主キーに指定します                                                          |
| UNIQUE          | Specifies column as unique                                             |
| DEFAULT         | Specifies column default value                                         |
| PRECISION       | Specifies column precision                                             |
| NOT NULL        | Specifies column as NOT NULL                                           |
| AUTO_INCREMENT  | Specifies column auto incrementable or not                             |
| INDEX           | Create index with or without name, same name creates composite indexes |
| UNIQUE_INDEX    | Like `INDEX`, create unique index                                      |
| EMBEDDED        | Set struct as embedded                                                 |
| EMBEDDED_PREFIX | Set embedded struct's prefix name                                      |
| -               | Ignore this fields                                                     |

### Struct tags for Associations

Check out Associations section for details

| Tag                                | Description                                    |
| ---------------------------------- | ---------------------------------------------- |
| MANY2MANY                          | Specifies join table name                      |
| FOREIGNKEY                         | Specifies foreign key                          |
| ASSOCIATION_FOREIGNKEY             | Specifies association foreign key              |
| POLYMORPHIC                        | Specifies polymorphic type                     |
| POLYMORPHIC_VALUE                  | Specifies polymorphic value                    |
| JOINTABLE_FOREIGNKEY               | Specifies foreign key of jointable             |
| ASSOCIATION_JOINTABLE_FOREIGNKEY | Specifies association foreign key of jointable |
| SAVE_ASSOCIATIONS                  | AutoSave associations or not                   |
| ASSOCIATION_AUTOUPDATE             | AutoUpdate associations or not                 |
| ASSOCIATION_AUTOCREATE             | AutoCreate associations or not                 |
| ASSOCIATION_SAVE_REFERENCE       | AutoSave associations reference or not         |
| PRELOAD                            | Auto Preload associations or not               |