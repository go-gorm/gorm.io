---
title: 常规数据库接口 sql.DB
layout: page
---

GORM 提供了 `DB` 方法，可用于从当前 `*gorm.DB` 返回一个通用的数据库接口 [*sql.DB](https://pkg.go.dev/database/sql#DB)

```go
// 获取通用数据库对象 sql.DB，然后使用其提供的功能
sqlDB, err := db.DB()

// Ping
sqlDB.Ping()

// Close
sqlDB.Close()

// 返回数据库统计信息
sqlDB.Stats()
```

**注意** 如果底层连接的数据库不是 `*sql.DB`，它会返回错误

## 连接池

```go
// 获取通用数据库对象 sql.DB ，然后使用其提供的功能
sqlDB, err := db。 B()

// SetMaxIdleConns 用于设置连接池中空闲连接的最大数量。
sqlDB.SetMaxIgleConns(10)

// SetMaxOpenConns 设置打开数据库连接的最大数量。
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime 设置了连接可复用的最大时间。
sqlDB.SetConnMaxLifetime(time.Hour)
```
