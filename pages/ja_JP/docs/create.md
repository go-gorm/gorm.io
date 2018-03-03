---
title: 作成します。
layout: ページ
---
## レコードを作成します。

```go
ユーザー: ユーザーを = {名前:"Jinzhu"、年齢: 18、誕生日: 時間。Now()} db。NewRecord(user)//主キーは空白 db> 'true' 返しますを =。(&ユーザー) db を作成します。NewRecord(user)/> 戻り値 'false' を 'ユーザー' が作成した後 =/
```

## 既定値

たとえば、タグのフィールドの既定値を定義できます。

```go
構造体の動物を入力 {ID int64 名文字列 ' gorm:"既定: 'galeone'"' 年齢 int64}
```

その後、挿入の SQL しない値を持つまたは [0 値](https://tour.golang.org/basics/12)、データベースにレコードを挿入した後、gorm はこれらのフィールドの値をデータベースから読み込むフィールドが除外されます。

```go
var 動物動物 = {年齢: 99、名:""} db。(&動物) を作成/animals("age") values('99'); を挿入/動物 ID どこから選択して名前 = 111;返される主キーは 111/動物/。名前 => 'galeone'
```

**NOTE** all fields having zero value, like ``, `''`, `false` or other [zero values](https://tour.golang.org/basics/12) won't be saved into database but will use its default value, it you want to avoid this, consider to use pointer type or scaner/valuer, e.g:

```go
// Use pointer value
type User struct {
  gorm.Model
  Name string
  Age  *int `gorm:"default:18"`
}

// Use scanner/valuer
type User struct {
  gorm.Model
  Name string
  Age  sql.NullInt64 `gorm:"default:18"`
}
```

## Setting Field Values In Hooks

If you want to update field's value in `BeforeCreate` hook, you could use `scope.SetColumn`, for example:

```go
func (user *User) BeforeCreate(scope *gorm.Scope) error {
  scope.SetColumn("ID", uuid.New())
  return nil
}
```

## Extra Creating option

```go
// Add extra SQL option for inserting SQL
db.Set("gorm:insert_option", "ON CONFLICT").Create(&product)
// INSERT INTO products (name, code) VALUES ("name", "code") ON CONFLICT;
```