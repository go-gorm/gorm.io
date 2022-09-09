---
title: レコードの更新
layout: page
---

## すべてのフィールドを保存する

`Save`は 、SQLを実行するときにすべてのフィールドを更新します。

```go
db.First(&user)

user.Name = "jinzhu 2"
user.Age = 100
db.Save(&user)
// UPDATE users SET name='jinzhu 2', age=100, birthday='2016-01-01', updated_at = '2013-11-17 21:34:10' WHERE id=111;
```

## 単一のカラムを更新する

`Update`メソッドで単一のカラムを更新する際には、何らかの条件を持っていないと、`ErrMissingWhereClause`エラーが発生します。詳細については、[Block Global Updates](#block_global_updates) をチェックしてください。`Model`メソッドを使用し、その実体が主キーに値するフィールドを持つ場合、条件として実体が持つ主キーが指定されます。

```go
// Update with conditions
db.Model(&User{}).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE active=true;

// User's ID is `111`:
db.Model(&user).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111;

// Update with conditions and model value
db.Model(&user).Where("active = ?", true).Update("name", "hello")
// UPDATE users SET name='hello', updated_at='2013-11-17 21:34:10' WHERE id=111 AND active=true;
```

## 複数のカラムを更新する

`Updates`は`構造体`もしくは`map[string]interface{}`での更新に対応しています。`構造体`での更新時のみ、ゼロ値のフィールド以外を更新します。

```go
// Update attributes with `struct`, will only update non-zero fields
db.Model(&user).Updates(User{Name: "hello", Age: 18, Active: false})
// UPDATE users SET name='hello', age=18, updated_at = '2013-11-17 21:34:10' WHERE id = 111;

// Update attributes with `map`
db.Model(&user).Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello', age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;
```

{% note warn %}
**注** 構造体を使用して更新を行う場合、GORMは非ゼロ値のフィールドのみ更新します。ゼロ値のフィールドも更新対象に含める場合は、更新に`map`を使用するか、 `Select` で更新するフィールドを指定してください。
{% endnote %}

## 選択したフィールドを更新する

選択したフィールドのみ更新する場合、または更新するフィールドを除外する場合は、 `Select`, `Omit` を使用できます

```go
// Select with Map
// User's ID is `111`:
db.Model(&user).Select("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET name='hello' WHERE id=111;

db.Model(&user).Omit("name").Updates(map[string]interface{}{"name": "hello", "age": 18, "active": false})
// UPDATE users SET age=18, active=false, updated_at='2013-11-17 21:34:10' WHERE id=111;

// Select with Struct (select zero value fields)
db.Model(&user).Select("Name", "Age").Updates(User{Name: "new_name", Age: 0})
// UPDATE users SET name='new_name', age=0 WHERE id=111;

// Select all fields (select all fields include zero value fields)
db.Model(&user).Select("*").Update(User{Name: "jinzhu", Role: "admin", Age: 0})

// Select all fields but omit Role (select all fields include zero value fields)
db.Model(&user).Select("*").Omit("Role").Update(User{Name: "jinzhu", Role: "admin", Age: 0})
```

## 更新時のHook

GORMは `BeforeSave`, `BeforeUpdate`, `AfterSave`, `AfterUpdate`などのhook処理を定義できます。これらのメソッドはレコードを更新する際に呼び出されます。 詳細は[Hooks](hooks.html)を参照してください。

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to update")
    }
    return
}
```

## 一括更新

`Model`で主キーを指定していない場合、GORMは一括更新を行います。

```go
// Update with struct
db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin';

// Update with map
db.Table("users").Where("id IN ?", []int{10, 11}).Updates(map[string]interface{}{"name": "hello", "age": 18})
// UPDATE users SET name='hello', age=18 WHERE id IN (10, 11);
```

### <span id="block_global_updates">Global Updatesを防ぐ</span>

条件なしで一括更新を実行しようとした場合、デフォルトの設定ではGORMは更新処理を実行せず、 `ErrMissingWhereClause` エラーを返します。

条件を指定する、SQLをそのまま実行する、あるいは `AllowGlobalUpdate` モードを有効にする必要があります。例:

```go
db.Model(&User{}).Update("name", "jinzhu").Error // gorm.ErrMissingWhereClause

db.Model(&User{}).Where("1 = 1").Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu" WHERE 1=1

db.Exec("UPDATE users SET name = ?", "jinzhu")
// UPDATE users SET name = "jinzhu"

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Model(&User{}).Update("name", "jinzhu")
// UPDATE users SET `name` = "jinzhu"
```

### 更新されたレコード数をカウントする

更新されたレコードの行数を取得することができます。

```go
// Get updated records count with `RowsAffected`
result := db.Model(User{}).Where("role = ?", "admin").Updates(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE role = 'admin';

result.RowsAffected // returns updated records count
result.Error        // returns updating error
```

## 高度な機能

### <span id="update_from_sql_expr">SQL式で更新する</span>

GORMはSQL式でカラムを更新することができます。例:

```go
// product's ID is `3`
db.Model(&product).Update("price", gorm.Expr("price * ? + ?", 2, 100))
// UPDATE "products" SET "price" = price * 2 + 100, "updated_at" = '2013-11-17 21:34:10' WHERE "id" = 3;

db.Model(&product).Updates(map[string]interface{}{"price": gorm.Expr("price * ? + ?", 2, 100)})
// UPDATE "products" SET "price" = price * 2 + 100, "updated_at" = '2013-11-17 21:34:10' WHERE "id" = 3;

db.Model(&product).UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = 3;

db.Model(&product).Where("quantity > 1").UpdateColumn("quantity", gorm.Expr("quantity - ?", 1))
// UPDATE "products" SET "quantity" = quantity - 1 WHERE "id" = 3 AND quantity > 1;
```

また、[Customized Data Types](data_types.html#gorm_valuer_interface)に記載されているSQL Expression/Context Valuerを使用しての更新も行うことができます。例：

```go
// Create from customized data type
type Location struct {
    X, Y int
}

func (loc Location) GormValue(ctx context.Context, db *gorm.DB) clause.Expr {
  return clause.Expr{
    SQL:  "ST_PointFromText(?)",
    Vars: []interface{}{fmt.Sprintf("POINT(%d %d)", loc.X, loc.Y)},
  }
}

db.Model(&User{ID: 1}).Updates(User{
  Name:  "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// UPDATE `user_with_points` SET `name`="jinzhu",`location`=ST_PointFromText("POINT(100 100)") WHERE `id` = 1
```

### サブクエリでの更新

サブクエリを使用してテーブルを更新することができます。

```go
db.Model(&user).Update("company_name", db.Model(&Company{}).Select("name").Where("companies.id = users.company_id"))
// UPDATE "users" SET "company_name" = (SELECT name FROM companies WHERE companies.id = users.company_id);

db.Table("users as u").Where("name = ?", "jinzhu").Update("company_name", db.Table("companies as c").Select("name").Where("c.id = u.company_id"))

db.Table("users as u").Where("name = ?", "jinzhu").Updates(map[string]interface{}{"company_name": db.Table("companies as c").Select("name").Where("c.id = u.company_id")})
```

### Hooksやタイムトラッキングなしでの更新

`Hooks` メソッドの実行を回避したい場合や、更新時間をトラッキングしたくない場合、 `Update`、 `Updates`と似た、`UpdateColumn`、 `UpdateColumns` を使用することができます。

```go
// Update single column
db.Model(&user).UpdateColumn("name", "hello")
// UPDATE users SET name='hello' WHERE id = 111;

// Update multiple columns
db.Model(&user).UpdateColumns(User{Name: "hello", Age: 18})
// UPDATE users SET name='hello', age=18 WHERE id = 111;

// Update selected columns
db.Model(&user).Select("name", "age").UpdateColumns(User{Name: "hello", Age: 0})
// UPDATE users SET name='hello', age=0 WHERE id = 111;
```

### 変更されたレコードのデータを返却する

Returningをサポートしているデータベースであれば、変更されたデータを取得することができます。例：

```go
// すべてのカラムを返却する
var users []User
DB.Model(&users).Clauses(clause.Returning{}).Where("role = ?", "admin").Update("salary", gorm.Expr("salary * ?", 2))
// UPDATE `users` SET `salary`=salary * 2,`updated_at`="2021-10-28 17:37:23.19" WHERE role = "admin" RETURNING *
// users => []User{{ID: 1, Name: "jinzhu", Role: "admin", Salary: 100}, {ID: 2, Name: "jinzhu.2", Role: "admin", Salary: 1000}}

// 指定のカラムのみ返却する
DB.Model(&users).Clauses(clause.Returning{Columns: []clause.Column{{Name: "name"}, {Name: "salary"}}}).Where("role = ?", "admin").Update("salary", gorm.Expr("salary * ?", 2))
// UPDATE `users` SET `salary`=salary * 2,`updated_at`="2021-10-28 17:37:23.19" WHERE role = "admin" RETURNING `name`, `salary`
// users => []User{{ID: 0, Name: "jinzhu", Role: "", Salary: 100}, {ID: 0, Name: "jinzhu.2", Role: "", Salary: 1000}}
```

### フィールドが変更されたかチェックする

GORMには **Before Update Hooks** で使用できる `Changed` メソッドをがあります。これはフィールドが変更されたかどうかを返却します。

`Changed` は `Update`, `Updates` メソッド実行時のみ機能します。また、 `Update` / `Updates` に渡す値とモデルの値が比較可能である場合のみ更新をチェックし、値が変更されていて かつ 更新対象から除外されていなければ true を返却します。

```go
func (u *User) BeforeUpdate(tx *gorm.DB) (err error) {
  // if Role changed
  if tx.Statement.Changed("Role") {
    return errors.New("role not allowed to change")
  }

  if tx.Statement.Changed("Name", "Admin") { // if Name or Role changed
    tx.Statement.SetColumn("Age", 18)
  }

  // if any fields changed
  if tx.Statement.Changed() {
    tx.Statement.SetColumn("RefreshedAt", time.Now())
  }
  return nil
}

db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu2"})
// Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(map[string]interface{"name": "jinzhu"})
// Changed("Name") => false, `Name` not changed
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(map[string]interface{
  "name": "jinzhu2", "admin": false,
})
// Changed("Name") => false, `Name` not selected to update

db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu2"})
// Changed("Name") => true
db.Model(&User{ID: 1, Name: "jinzhu"}).Updates(User{Name: "jinzhu"})
// Changed("Name") => false, `Name` not changed
db.Model(&User{ID: 1, Name: "jinzhu"}).Select("Admin").Updates(User{Name: "jinzhu2"})
// Changed("Name") => false, `Name` not selected to update
```

### 更新値の変更

`Save` による全フィールドの更新でなければ、`SetColumn` を使用して Before Hooks 内で更新値を変更することができます。例：

```go
func (user *User) BeforeSave(tx *gorm.DB) (err error) {
  if pw, err := bcrypt.GenerateFromPassword(user.Password, 0); err == nil {
    tx.Statement.SetColumn("EncryptedPassword", pw)
  }

  if tx.Statement.Changed("Code") {
    user.Age += 20
    tx.Statement.SetColumn("Age", user.Age)
  }
}

db.Model(&user).Update("Name", "jinzhu")
```
