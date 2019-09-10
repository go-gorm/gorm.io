---
title: 通过数据库接口 sql.DB
layout: page
---

GORM 提供了 `DB`方法 ，可以从当前 `*gorm.DB` 连接内，获取一个通用的数据库接口[*sql.DB](http://golang.org/pkg/database/sql/#DB)

```go
// 获取通用 sql.DB 并使用其方法
db.DB()

// Ping
db.DB().Ping()
```

**注意** 如果数据库底层连接的不是一个 `*sql.DB`，比如在一个事务内，方法会返回`nil`。

## 连接池

```go
// SetMaxIdleCons 设置连接池中的最大闲置连接数。
db.DB().SetMaxIdleConns(10)

// SetMaxOpenCons 设置数据库的最大连接数量。
db.DB().SetMaxOpenConns(100)

// SetConnMaxLifetiment 设置连接的最大可复用时间。
db.DB().SetConnMaxLifetime(time.Hour)
```