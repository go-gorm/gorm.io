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
user := model.User{Name: "modi", Age: 18, Address: "Beijing", Birthday: time.Now()}
u.WithContext(ctx).Omit(u.Name, u.Age).Create(&user)
// INSERT INTO `users` (`address`,`birthday`) VALUES ("Beijing", "2021-08-17 20:54:12.000")
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
var users = []*model.User{{Name: "modi_1"}, /*...*/, {Name: "modi_10000"}}

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

u := query.Use(db).User

var users = []*model.User{{Name: "modi_1"}, /*...*/, {Name: "modi_5000"}}

err = u.WithContext(ctx).Create(users...)
// INSERT INTO users xxx (5 batches)
```

## Upsert / On Conflict

Gen provides compatible Upsert support for different databases

```go
import "gorm.io/gorm/clause"

// Do nothing on conflict
err := query.User.WithContext(ctx).Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// Update columns to default value on `id` conflict
err := query.User.WithContext(ctx).Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(users...)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

err = query.User.WithContext(ctx).Clauses(clause.OnConflict{DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),}).Create(&user)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age); MySQL

// Update all columns, except primary keys, to new value on conflict
err := query.User.WithContext(ctx).Clauses(clause.OnConflict{
  UpdateAll: true,
}).Create(users...)
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age", ...;
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age), ...; MySQL
```

> **NOTE** `Clauses` passes its arguments through Gen's clause security check.
> `clause.OnConflict.DoUpdates` values must not be `gorm.Expr` — such assignments
> are rejected with "OnConflict clause assignment with gorm.Expr is banned for
> security reasons for now". See [Clauses](./clause.html).

## Save

`Save` is an upsert: it inserts the records and, on primary-key conflict, updates
**all** columns. Unlike GORM's `Save` (which runs an UPDATE when the primary key
is set), the generated `Save` **always** executes
`Clauses(clause.OnConflict{UpdateAll: true}).Create(values)` — a record with a set
primary key is still INSERTed, and the conflict turns it into a full-column update:

```go
u := query.Use(db).User

// Insert (zero primary key)
err := u.WithContext(ctx).Save(&model.User{Name: "modi", Age: 18})
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age),...; MySQL
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name",...; PostgreSQL

// Primary key set: still an INSERT that conflicts and updates every column
err = u.WithContext(ctx).Save(&model.User{Model: gorm.Model{ID: 1}, Name: "modi2", Age: 20})
// same INSERT ... ON CONFLICT ("id") DO UPDATE SET ... SQL as above
```

See [Clauses](./clause.html) for the security check that applies to the
`OnConflict` clause.

## Returning

On databases that support it (PostgreSQL, SQL Server; SQLite >= 3.35), `Returning`
appends a `RETURNING` clause to **write** statements and passes the destination
you provide to the driver:

```go
u := query.Use(db).User

// Update: the destination given to Returning is used as the Model of the
// UPDATE, so the returned row is scanned into it
var updated []*model.User
info, err := u.WithContext(ctx).Returning(&updated).Where(u.Age.Lt(18)).UpdateSimple(u.Age.Value(18))
// UPDATE "users" SET "age"=18 WHERE age < 18 RETURNING *;

// Delete: same Model-target semantics — the deleted rows are scanned back
var deleted []*model.User
info, err = u.WithContext(ctx).Returning(&deleted).Where(u.Age.Lt(18)).Delete()
// DELETE FROM "users" WHERE age < 18 RETURNING *;
```

For **queries**, GORM does not emit `RETURNING` (it is a write-statement clause),
so `First`/`Take`/`Last` run a plain `SELECT` — but they scan into the
destination given to `Returning` when one is set, instead of allocating their
own result. `Find` always allocates its own result slice and ignores the
`Returning` destination.
