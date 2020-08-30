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

## 选定字段创建

用选定字段的来创建

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

创建时排除选定字段

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## 创建钩子

GORM 允许 `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate` 等钩子，创建记录时会调用这些方法, 详情请参阅 [钩子](hooks.html)

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

## <span id="batch_insert">批量插入</span>

将切片数据传递给 `Create` 方法，GORM 将生成一个单一的 SQL 语句来插入所有数据，并回填主键的值，钩子方法也会被调用。

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
DB.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

[Upsert](#upsert) 和 [Create With Associations](#create_with_associations) 也支持批量插入

## Create From Map

GORM 支持根据 `map[string]interface{}` 和 `[]map[string]interface{}{}` 创建记录，例如：

```go
DB.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// 根据 `[]map[string]interface{}{}` 批量插入
DB.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**NOTE** When creating from map, hooks won't be invoked, associations won't be saved and primary key values won't be back filled
{% endnote %}

## <span id="create_from_sql_expr">使用 SQL 表达式、Context Valuer 创建记录</span>

GORM allows insert data with SQL expression, there are two ways to achieve this goal, create from `map[string]interface{}` or [Customized Data Types](data_types.html#gorm_valuer_interface), for example:

```go
// 根据 map Create
DB.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`point`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

// 根据自定义数据类型 Create
type Location struct {
    X, Y int
}

// Scan 实现了 sql.Scanner 接口
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

DB.Create(&User{
  Name:     "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// INSERT INTO `users` (`name`,`point`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"))
```

## 高级选项

### <span id="create_with_associations">关联创建</span>

When creating some data with associations, if its associations value is not zero-value, those associations will be upserted, and its `Hooks` methods will be invoked.

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

You can skip saving associations with `Select`, `Omit`, for example:

```go
db.Omit("CreditCard").Create(&user)

// 跳过所有关联
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">默认值</span>

You can define default values for fields with tag `default`, for example:

```go
type User struct {
  ID         int64
  Name       string `gorm:"default:galeone"`
  Age        int64  `gorm:"default:18"`
    uuid.UUID  UUID   `gorm:"type:uuid;default:gen_random_uuid()"` // 数据库函数
}
```

Then the default value *will be used* when inserting into the database for [zero-value](https://tour.golang.org/basics/12) fields

**NOTE** Any zero value like `0`, `''`, `false` won't be saved into the database for those fields defined default value, you might want to use pointer type or Scanner/Valuer to avoid this, for example:

```go
type User struct {
  gorm.Model
  Name string
  Age  *int           `gorm:"default:18"`
  Active sql.NullBool `gorm:"default:true"`
}
```

**NOTE** You have to setup the `default` tag for fields having default value in databae or GORM will use the zero value of the field when creating, for example:

```go
type User struct {
    ID   string `gorm:"default:uuid_generate_v3()"`
    Name string
    Age  uint8
}
```

### <span id="upsert">Upsert 及冲突</span>

GORM provides compatible Upsert support for different databases

```go
import "gorm.io/gorm/clause"

// 不处理冲突
DB.Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// `id` 冲突时，将字段值更新为默认值
DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

// Update columns to new value on `id` conflict
DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age=VALUES(age); MySQL
```

Also checkout `FirstOrInit`, `FirstOrCreate` on [Advanced Query](advanced_query.html)

Checkout [Raw SQL and SQL Builder](sql_builder.html) for more details
