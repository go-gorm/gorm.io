---
title: 数据库索引
layout: page
---

GORM 允许通过 `index`、`uniqueIndex` 标签创建索引，这些索引将在使用 GORM 进行[AutoMigrate 或 Createtable ](migration.html) 时创建

## 索引标签

GORM 可以接受很多索引设置，例如`class`、`type`、`where`、`comment`、`expression`、`sort`、`collate`、`option`

下面的示例演示了如何使用它：

```go
type User struct {
    Name  string `gorm:"index"`
    Name2 string `gorm:"index:idx_name,unique"`
    Name3 string `gorm:"index:,sort:desc,collate:utf8,type:btree,length:10,where:name3 != 'jinzhu'"`
    Name4 string `gorm:"uniqueIndex"`
    Age   int64  `gorm:"index:,class:FULLTEXT,comment:hello \\, world,where:age > 10"`
    Age2  int64  `gorm:"index:,expression:ABS(age)"`
}

// MySQL 选项
type User struct {
    Name string `gorm:"index:,class:FULLTEXT,option:WITH PARSER ngram INVISIBLE"`
}

// PostgreSQL 选项
type User struct {
    Name string `gorm:"index:,option:CONCURRENTLY"`
}
```

### 唯一索引

`uniqueIndex` 标签的作用与 `index` 类似，它等效于 `index:,unique`

```go
type User struct {
    Name1 string `gorm:"uniqueIndex"`
    Name2 string `gorm:"uniqueIndex:idx_name,sort:desc"`
}
```

## 复合索引

两个字段使用同一个索引名将创建复合索引，例如：

```go
// create composite index `idx_member` with columns `name`, `number`
type User struct {
    Name   string `gorm:"index:idx_member"`
    Number string `gorm:"index:idx_member"`
}
```

### 字段优先级

复合索引列的顺序会影响其性能，因此必须仔细考虑

您可以使用 `priority` 指定顺序，默认优先级值是 `10`，如果优先级值相同，则顺序取决于模型结构体字段的顺序

```go
type User struct {
    Name   string `gorm:"index:idx_member"`
    Number string `gorm:"index:idx_member"`
}
// column order: name, number

type User struct {
    Name   string `gorm:"index:idx_member,priority:2"`
    Number string `gorm:"index:idx_member,priority:1"`
}
// column order: number, name

type User struct {
    Name   string `gorm:"index:idx_member,priority:12"`
    Number string `gorm:"index:idx_member"`
}
// column order: number, name
```

### Shared composite indexes

If you are creating shared composite indexes with an embedding struct, you can't specify the index name, as embedding the struct more than once results in the duplicated index name in db.

In this case, you can use index tag `composite`, it means the id of the composite index. All fields which have the same composite id of the struct are put together to the same index, just like the original rule. But the improvement is it lets the most derived/embedding struct generates the name of index by NamingStrategy. For example:

```go
type Foo struct {
  IndexA int `gorm:"index:,unique,composite:myname"`
  IndexB int `gorm:"index:,unique,composite:myname"`
}
```

If the table Foo is created, the name of composite index will be `idx_foo_myname`.

```go
type Bar0 struct {
  Foo
}

type Bar1 struct {
  Foo
}
```

Respectively, the name of composite index is `idx_bar0_myname` and `idx_bar1_myname`.

`composite` only works if not specify the name of index.

## 多索引

A field accepts multiple `index`, `uniqueIndex` tags that will create multiple indexes on a field

```go
type UserIndex struct {
    OID          int64  `gorm:"index:idx_id;index:idx_oid,unique"`
    MemberNumber string `gorm:"index:idx_id"`
}
```
