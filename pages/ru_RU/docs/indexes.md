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
    Name5 string `gorm:"index:,class:FULLTEXT,option:WITH PARSER ngram"`
    Age   int64  `gorm:"index:,class:FULLTEXT,comment:hello \\, world,where:age > 10"`
    Age2  int64  `gorm:"index:,expression:ABS(age)"`
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

## Композитные индексы

Использовать одно и то же имя индекса для двух полей создаст составные индексы, например:

```go
type User struct {
    Name   string `gorm:"index:idx_member"`
    Number string `gorm:"index:idx_member"`
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

## Несколько индексов

Поле может иметь несколько тэгов `index`, `uniqueIndex`, которые создадут несколько индексов в поле

```go
type UserIndex struct {
    OID          int64  `gorm:"index:idx_id;index:idx_oid,unique"`
    MemberNumber string `gorm:"index:idx_id"`
}
```
