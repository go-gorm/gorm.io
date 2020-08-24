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

[Upsert](#upsert)、[关联创建](#create_with_associations) 同样支持批量插入

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

**注意：** 根据 map 创建记录时，association 不会被调用，且主键也不会自动填充

## 高级

### <span id="create_with_associations">关联创建</span>

如果您的模型定义了任何关系（relation），并且它有非零关系，那么在创建时这些数据也会被保存

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

您也可以通过 `Select`、 `Omit` 跳过关联保存

```go
db.Omit("CreditCard").Create(&user)

// 跳过所有关联
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">默认值</span>

您可以通过标签 `default` 为字段定义默认值，如：

```go
type User struct {
  ID         int64
  Name       string `gorm:"default:'galeone'"`
  Age        int64  `gorm:"default:18"`
    uuid.UUID  UUID   `gorm:"type:uuid;default:gen_random_uuid()"` // db 函数
}
```

插入记录到数据库时，[零值](https://tour.golang.org/basics/12) 字段将使用默认值

**注意** 像 `0`、`''`、`false` 等零值，不会将这些字段定义的默认值保存到数据库。您需要使用指针类型或 Scanner/Valuer 来避免这个问题，例如：

```go
type User struct {
  gorm.Model
  Name string
  Age  *int           `gorm:"default:18"`
  Active sql.NullBool `gorm:"default:true"`
}
```

**注意** 对于在数据库中有默认值的字段，你必须为其 struct 设置 `default` 标签，否则 GORM 将在创建时使用该字段的零值，例如：

```go
type User struct {
    ID   string `gorm:"default:uuid_generate_v3()"`
    Name string
    Age  uint8
}
```

### <span id="upsert">Upsert 及冲突</span>

GORM 为不同数据库提供了兼容的 Upsert 支持

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

// 当 `id` 冲突时，为其更新一个新的值
DB.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age=VALUES(age); MySQL
```

您还可以查看 [高级查询](advanced_query.html) 中的 `FirstOrInit`、`FirstOrCreate`

查看 [原生 SQL 及构造器](sql_builder.html) 获取更多细节
