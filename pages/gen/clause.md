---
title: Clause
layout: page
---

## Upsert

```go
u := query.User

user := model.User{Name: "Modi", Age: 18, Birthday: time.Now()}

u.Save(&mode)
// equal to
u.Clauses(clause.OnConflict{UpdateAll: true}).Create(value).Error
```

## Hints

Optimizer hints allow to control the query optimizer to choose a certain query execution plan, GORM supports it with `gorm.io/hints`, e.g:

```go
import "gorm.io/hints"

u := query.Use(db).User

users, err := u.WithContext(ctx).Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find()
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Index hints allow passing index hints to the database in case the query planner gets confused.

```go
import "gorm.io/hints"

u := query.Use(db).User

users, err := u.WithContext(ctx).Clauses(hints.UseIndex("idx_user_name")).Find()
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

users, err := u.WithContext(ctx).Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find()
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```
