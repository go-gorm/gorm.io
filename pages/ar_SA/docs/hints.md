---
title: Hints
layout: page
---

GORM provides optimizer/index/comment hints support

https://github.com/go-gorm/hints

## Optimizer Hints

```go
import "gorm.io/hints"

DB. Comment("select", "master")). Find(&User{})
// SELECT /*master*/ * FROM `users`;

DB.
```

## Index Hints

```go
import "gorm.io/hints"

DB. Comment("select", "master")). Find(&User{})
// SELECT /*master*/ * FROM `users`;

DB.
```

## Comment Hints

```go
import "gorm.io/hints"

DB. Comment("select", "master")). Find(&User{})
// SELECT /*master*/ * FROM `users`;

DB. CommentBefore("insert", "node2")). CommentAfter("select", "node2")). CommentAfter("where", "hint")). Find(&User{}, "id = ?", 1)
// SELECT * FROM `users` WHERE id = ? /* hint */ /* hint */
```
