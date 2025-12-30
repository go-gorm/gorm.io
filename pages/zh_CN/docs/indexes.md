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
Note that this will not work for unique composite indexes.

## 复合索引

两个字段使用同一个索引名将创建复合索引，例如：

```go
// create composite index `idx_member` with columns `name`, `number`
type User struct {
    Name   string `gorm:"index:idx_member"`
    Number string `gorm:"index:idx_member"`
}
```

For a unique composite index:

```go
// create unique composite index `idx_member` with columns `name`, and `number`
type User struct {
    Name   string `gorm:"index:idx_member,unique"`
    Number string `gorm:"index:idx_member,unique"`
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

### 共享复合索引

如果您正在创建带有嵌入结构的共享复合索引，您不能指定索引名称。 作为嵌入结构不止一次会导致重复的索引名称在 db。

在这种情况下，您可以使用索引标签 `composite`, 它意味着复合索引的id。 所有具有相同结构复合id的字段都与原始规则一样，被合并到相同的索引中。 但改进使得最受影响/嵌入结构能够通过命名策略生成索引名称。 例如:

```go
type Foo struct {
  IndexA int `gorm:"index:,unique,composite:myname"`
  IndexB int `gorm:"index:,unique,composite:myname"`
}
```

如果表Foo被创建，复合索引的名称将是 `idx_foo_myname`。

```go
type Bar0 struct {
  Foo
}

type Bar1 struct {
  Foo
}
```

复合索引的名称分别是 `idx_bar0_myname` 和 `idx_bar1_myname`。

`复合` 只能在指定索引名称时使用。

## 多索引

一个字段接受多个 `index`、`uniqueIndex` 标签，这会在一个字段上创建多个索引

```go
type UserIndex struct {
    OID          int64  `gorm:"index:idx_id;index:idx_oid,unique"`
    MemberNumber string `gorm:"index:idx_id"`
}
```
