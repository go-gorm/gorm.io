---
title: Hints
layout: page
---

GORM 提供了 optimizer/index/comment hint 支持

https://github.com/go-gorm/hints

## Optimizer Hints

```go
import "gorm.io/hints"

db.Clauses(hints.New("hint")).Find(&User{})
// SELECT * /*+ hint */ FROM `users`
```

## Index Hints

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"

db.Clauses(
    hints.ForceIndex("idx_user_name", "idx_user_id").ForOrderBy(),
    hints.IgnoreIndex("idx_user_name").ForGroupBy(),
).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR ORDER BY (`idx_user_name`,`idx_user_id`) IGNORE INDEX FOR GROUP BY (`idx_user_name`)"
```

## Comment Hints

```go
import "gorm.io/hints"

db.Clauses(hints.Comment("select", "master")).Find(&User{})
// SELECT /*master*/ * FROM `users`;

db.Clauses(hints.CommentBefore("insert", "node2")).Create(&user)
// /*node2*/ INSERT INTO `users` ...;

db.Clauses(hints.CommentAfter("select", "node2")).Create(&user)
// /*node2*/ INSERT INTO `users` ...;

db.Clauses(hints.CommentAfter("where", "hint")).Find(&User{}, "id = ?", 1)
// SELECT * FROM `users` WHERE id = ? /* hint */
```
