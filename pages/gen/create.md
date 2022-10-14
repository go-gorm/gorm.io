---
title: Gen Create
layout: page
---

## Create record

You can insert a record using the type-safe `Create` method, which only accepts pointer of current model when creating data

```go
// u refer to query.user
user := model.User{Name: "Modi", Age: 18, Birthday: time.Now()}

u := query.User
err := u.WithContext(ctx).Create(&user) // pass pointer of data to Create

err // returns error
```

## Create record with selected fields

You can use `Select` when creating data, it will only insert those selected fields

```go
u := query.User
u.WithContext(ctx).Select(u.Name, u.Age).Create(&user)
// INSERT INTO `users` (`name`,`age`) VALUES ("modi", 18)
```

ignore fields with `Omit`

```go
u := query.User
u.WithContext(ctx).Omit(u.Name, u.Age).Create(&user)
// INSERT INTO `users` (`address`, `birthday`) VALUES ("2021-08-17 20:54:12.000", 18)
```

## Batch Insert

To efficiently insert large number of records, pass a slice to the `Create` method. GORM will generate a single SQL statement to insert all the data and backfill primary key values.

```go
var users = []*model.User{{Name: "modi"}, {Name: "zhangqiang"}, {Name: "songyuan"}}
query.User.WithContext(ctx).Create(users...)

for _, user := range users {
  user.ID // 1,2,3
}
```

You can specify batch size when creating with `CreateInBatches`, e.g:

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

