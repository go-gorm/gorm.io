---
title: Database Indexes
layout: page
---

GORM allows create database index with tag `index`, `uniqueIndex`, those indexes will be created when [AutoMigrate or CreateTable with GORM](migration.html)

## Index Tag

GORM accepts lots of index settings, like `class`, `type`, `where`, `comment`, `expression`, `sort`, `collate`, `option`

Check the following example for how to use it

```go
type User struct {
	Name  string `gorm:"index"`
	Name2 string `gorm:"index:idx_name,unique"`
	Name3 string `gorm:"index:,sort:desc,collate:utf8,type:btree,length:10,where:name3 != 'jinzhu'"`
	Name4 string `gorm:"uniqueIndex"`
	Age   int64  `gorm:"index:,class:FULLTEXT,comment:hello \\, world,where:age > 10"`
	Age2  int64  `gorm:"index:,expression:ABS(age)"`
}

// MySQL option
type User struct {
	Name string `gorm:"index:,class:FULLTEXT,option:WITH PARSER ngram INVISIBLE"`
}

// PostgreSQL option
type User struct {
	Name string `gorm:"index:,option:CONCURRENTLY"`
}
```

### uniqueIndex

tag `uniqueIndex` works similar like `index`, it equals to `index:,unique`

```go
type User struct {
	Name1 string `gorm:"uniqueIndex"`
	Name2 string `gorm:"uniqueIndex:idx_name,sort:desc"`
}
```

## Composite Indexes

Use same index name for two fields will creates composite indexes, for example:

```go
type User struct {
	Name   string `gorm:"index:idx_member"`
	Number string `gorm:"index:idx_member"`
}
```

### Fields Priority

The column order of a composite index has an impact on its performance so it must be chosen carefully

You can specify the order with the `priority` option, the default priority value is `10`, if priority value is the same, the order will be based on model struct's field index

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

## Multiple indexes

A field accepts multiple `index`, `uniqueIndex` tags that will create multiple indexes on a field

```go
type UserIndex struct {
	OID          int64  `gorm:"index:idx_id;index:idx_oid,unique"`
	MemberNumber string `gorm:"index:idx_id"`
}
```
