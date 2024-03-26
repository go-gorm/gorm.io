---
title: 创建
layout: page
---

## 创建记录

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

result := db.Create(&user) // 通过数据的指针来创建

user.ID             // 返回插入数据的主键
result.Error        // 返回 error
result.RowsAffected // 返回插入记录的条数
```

我们还可以使用 `Create()` 创建多项记录：
```go
users := []*User{
    User{Name: "Jinzhu", Age: 18, Birthday: time.Now()},
    User{Name: "Jackson", Age: 19, Birthday: time.Now()},
}

result := db.Create(users) // 传递切片以插入多行数据

result.Error        // 返回 error
result.RowsAffected // 返回插入记录的条数    
```
**NOTE** 你无法向 'create' 传递结构体，所以你应该传入数据的指针.
{% endnote %}

## 用指定的字段创建记录

创建记录并为指定字段赋值。

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

创建记录并忽略传递给 'Omit' 的字段值

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## <span id="batch_insert">批量插入</span>

要高效地插入大量记录，请将切片传递给`Create`方法。 GORM 将生成一条 SQL 来插入所有数据，以返回所有主键值，并触发 `Hook` 方法。 当这些记录可以被分割成多个批次时，GORM会开启一个</strong>事务</0>来处理它们。

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

你可以通过`db.CreateInBatches`方法来指定批量插入的批次大小

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// batch size 100
db.CreateInBatches(users, 100)
```

[Upsert](#upsert) 和 [Create With Associations](#create_with_associations)同样支持批量插入

{% note warn %}
**注意** 使用`CreateBatchSize` 选项初始化GORM实例后，此后进行创建& 关联操作时所有的`INSERT`行为都会遵循初始化时的配置。
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  CreateBatchSize: 1000,
})

db := db.Session(&gorm.Session{CreateBatchSize: 1000})

users = [5000]User{{Name: "jinzhu", Pets: []Pet{pet1, pet2, pet3}}...}

db.Create(&users)
// INSERT INTO users xxx (5 batches)
// INSERT INTO pets xxx (15 batches)
```

## 创建钩子

GROM允许用户通过实现这些接口 `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate`来自定义钩子。  这些钩子方法会在创建一条记录时被调用，关于钩子的生命周期请参阅[Hooks](hooks.html)。

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

如果你想跳过`Hooks`方法，可以使用`SkipHooks`会话模式，例子如下

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)
```

## 根据 Map 创建

GORM支持通过 `map[string]interface{}` 与 `[]map[string]interface{}{}`来创建记录。

```go
db.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// batch insert from `[]map[string]interface{}{}`
db.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**注意**当使用map来创建时，钩子方法不会执行，关联不会被保存且不会回写主键。
{% endnote %}

## <span id="create_from_sql_expr">使用 SQL 表达式、Context Valuer 创建记录</span>

GORM允许使用SQL表达式来插入数据，有两种方法可以达成该目的，使用`map[string]interface{}` 或者 [Customized Data Types](data_types.html#gorm_valuer_interface)， 示例如下：

```go
// Create from map
db.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

// Create from customized data type
type Location struct {
    X, Y int
}

// Scan implements the sql.Scanner interface
func (loc *Location) Scan(v interface{}) error {
  // Scan a value into struct from database driver
}

func (loc Location) GormDataType() string {
  return "geometry"
}

func (loc Location) GormValue(ctx context.Context, db *gorm.DB) clause.Expr {
  return clause.Expr{
    SQL:  "ST_PointFromText(?)",
    Vars: []interface{}{fmt.Sprintf("POINT(%d %d)", loc.X, loc.Y)},
  }
}

type User struct {
  Name     string
  Location Location
}

db.Create(&User{
  Name:     "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"))
```

## 高级选项

### <span id="create_with_associations">关联创建</span>

创建关联数据时，如果关联值非零，这些关联会被upsert，并且它们的`Hooks`方法也会被调用。

```go
type CreditCard struct {
  gorm.Model
  Number   string
  UserID   uint
}

type User struct {
  gorm.Model
  Name       string
  CreditCard CreditCard
}

db.Create(&User{
  Name: "jinzhu",
  CreditCard: CreditCard{Number: "411111111111"}
})
// INSERT INTO `users` ...
// INSERT INTO `credit_cards` ...
```

你可以通过`Select`, `Omit`方法来跳过关联更新，示例如下：

```go
db.Omit("CreditCard").Create(&user)

// skip all associations
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">默认值</span>

你可以通过结构体Tag `default`来定义字段的默认值，示例如下：

```go
type User struct {
  ID   int64
  Name string `gorm:"default:galeone"`
  Age  int64  `gorm:"default:18"`
}
```

这些默认值会被当作结构体字段的[零值](https://tour.golang.org/basics/12)插入到数据库中

{% note warn %}
**注意**，当结构体的字段默认值是零值的时候比如 `0`, `''`, `false`，这些字段值将不会被保存到数据库中，你可以使用指针类型或者Scanner/Valuer来避免这种情况。
{% endnote %}

```go
type User struct {
  gorm.Model
  Name string
  Age  *int           `gorm:"default:18"`
  Active sql.NullBool `gorm:"default:true"`
}
```

{% note warn %}
**注意**，若要让字段在数据库中拥有默认值则必须使用`default`Tag来为结构体字段设置默认值。如果想要在数据库迁移的时候跳过默认值，可以使用 `default:(-)`，示例如下：
{% endnote %}

```go
type User struct {
  ID        string `gorm:"default:uuid_generate_v3()"` // db func
  FirstName string
  LastName  string
  Age       uint8
  FullName  string `gorm:"->;type:GENERATED ALWAYS AS (concat(firstname,' ',lastname));default:(-);"`
}
```

{% note warn %}
**注意** **SQLite** 不支持批量插入的时候使用默认值。 前往 [SQLite Insert stmt](https://www.sqlite.org/lang_insert.html)了解。 下面是一个使用案例：

```go
type Pet struct {
    Name string `gorm:"default:cat"`
}

// 在SqlLite中，这是不允许的, 所以GORM会通过构建错误的SQL来返回错误:
// INSERT INTO `pets` (`name`) VALUES ("dog"),(DEFAULT) RETURNING `name`
db.Create(&[]Pet{{Name: "dog"}, {}})
```
一个可行的替代方案是通过钩子方法来设置默认字段

```go
func (p *Pet) BeforeCreate(tx *gorm.DB) (err error) {
    if p.Name == "" {
        p.Name = "cat"
    }
}
```

你可以在[issues#6335](https://github.com/go-gorm/gorm/issues/6335)了解到更多有关信息。
{% endnote %}

当使用virtual/generated value时，你可能需要禁用它的创建/更新权限，前往[Field-Level Permission](models.html#field_permission)了解字段权限。

### <span id="upsert">Upsert 及冲突</span>

GORM为不同数据库提供了对Upsert的兼容性支持。

```go
import "gorm.io/gorm/clause"

// Do nothing on conflict
db.Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// Update columns to default value on `id` conflict
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

// Use SQL expression
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"count": gorm.Expr("GREATEST(count, VALUES(count))")}),
}).Create(&users)
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `count`=GREATEST(count, VALUES(count));

// Update columns to new value on `id` conflict
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age); MySQL

// Update all columns to new value on conflict except primary keys and those columns having default values from sql func
db.Clauses(clause.OnConflict{
  UpdateAll: true,
}).Create(&users)
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age", ...;
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age), ...; MySQL
```

前往[Advanced Query](advanced_query.html)了解有关`FirstOrInit`, `FirstOrCreate`的信息。

查看 [Raw SQL and SQL Builder](sql_builder.html)获取详情
