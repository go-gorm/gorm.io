---
title: 创建Gen
layout: page
---

## 创建

您可以使用安全类型 `创建` 方法插入记录，该方法只能在创建数据时接受当前模型的指针。

```go
// u refer to query.user
user := model.User{Name: "Modi", Age: 18, Birthday: time.Now()}

u := query.User
err := u.WithContext(ctx).Create(&user) // pass pointer of data to Create

err // returns error
```

## 用选定字段的来创建

您可以在创建数据时使用 `Select` ，指定插入的字段

```go
u := query.User
u.WithContext(ctx).Select(u.Name, u.Age).Create(&user)
// INSERT INTO `users` (`name`,`age`) VALUES ("modi", 18)
```

忽略字段使用 `Omit`

```go
u := query.User
u.WithContext(ctx).Omit(u.Name, u.Age).Create(&user)
// INSERT INTO `users` (`address`, `birthday`) VALUES ("2021-08-17 20:54:12.000", 18)
```

## 批量插入

更高效地插入大量记录，可以将一个 slice 传递给 `Create` 方法。 将切片数据传递给 Create 方法，GORM 将生成单个 SQL 语句来插入所有数据，并回填主键的值。

```go
var users = []*model.User{{Name: "modi"}, {Name: "zhangqiang"}, {Name: "songyuan"}}
query.User.WithContext(ctx).Create(users...)

for _, user := range users {
  user.ID // 1,2,3
}
```

使用 `CreateInBatches` 创建时，你还可以指定创建的数量，例如：

```go
var users = []*User{{Name: "modi_1"}, ...., {Name: "modi_10000"}}

// batch size 100
query.User.WithContext(ctx).CreateInBatches(users, 100)
```

It will works if you set `CreateBatchSize` in `gorm.Config` / `gorm.Session`

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  CreateBatchSize: 1000,
})
// OR
db = db.Session(&gorm.Session{CreateBatchSize: 1000})

u := query.NewUser(db)

var users = []User{{Name: "modi_1"}, ...., {Name: "modi_5000"}}

u.WithContext(ctx).Create(&users)
// INSERT INTO users xxx (5 batches)
```

## Upsert / On Conflict

Gen 为不同数据库提供兼容的 Upsert 支持

```go
import "gorm.io/gorm/clause"

// Do nothing on conflict
err := query.User.WithContext(ctx).Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// Update columns to default value on `id` conflict
err := query.User.WithContext(ctx).Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

err := query.User.WithContext(ctx).Clauses(clause.OnConflict{DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),}).Create(&user).Error
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age); MySQL

// Update all columns, except primary keys, to new value on conflict
err := query.User.WithContext(ctx).Clauses(clause.OnConflict{
  UpdateAll: true,
}).Create(&users)
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age", ...;
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age), ...; MySQL
```
