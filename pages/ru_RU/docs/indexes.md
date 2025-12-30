---
title: Индексы базы данных
layout: страница
---

GORM позволяет создавать индекс базы данных при помощи тегов `index`, `uniqueIndex`, эти индексы будут создаваться, при [AutoMigrate или CreateTable в GORM](migration.html)

## Тег индекса

GORM accepts lots of index settings, like `class`, `type`, `where`, `comment`, `expression`, `sort`, `collate`, `option`

Следующий пример показывает, как это можно использовать

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

### uniqueIndex (уникальный индекс)

тэг `uniqueIndex` работает подобно `index`, аналог `index:,unique`

```go
type User struct {
    Name1 string `gorm:"uniqueIndex"`
    Name2 string `gorm:"uniqueIndex:idx_name,sort:desc"`
}
```
Note that this will not work for unique composite indexes.

## Композитные индексы

Использовать одно и то же имя индекса для двух полей создаст составные индексы, например:

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

### Приоритет полей

Порядок расположения составного индекса в колонках влияет на его производительность, поэтому его необходимо тщательно выбрать

Вы можете указать порядок при помощи параметра `priority`, значение приоритета по умолчанию `10`, если приоритет одинаков, то порядок будет базироваться на порядке полей структуры модели

```go
type User struct {
    Name   string `gorm:"index:idx_member"`
    Number string `gorm:"index:idx_member"`
}
// порядок полей: name, number

type User struct {
    Name   string `gorm:"index:idx_member,priority:2"`
    Number string `gorm:"index:idx_member,priority:1"`
}
// порядо полей: number, name

type User struct {
    Name   string `gorm:"index:idx_member,priority:12"`
    Number string `gorm:"index:idx_member"`
}
// порядо полей: number, name
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

## Несколько индексов

A field accepts multiple `index`, `uniqueIndex` tags that will create multiple indexes on a field

```go
type UserIndex struct {
    OID          int64  `gorm:"index:idx_id;index:idx_oid,unique"`
    MemberNumber string `gorm:"index:idx_id"`
}
```
