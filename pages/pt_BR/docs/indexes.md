---
title: Índices
layout: page
---

GORM permite criar índice de banco de dados com tag `index`, `uniqueIndex`, esses índices serão criados quando rodam as funções [AutoMigrate ou CreateTable](migration.html)

## Tag Index

GORM aceita muitas configurações de índice, como `class`, `type`, `where`, `comment`,  `expression`, `sort`, `collate`, `option`

Veja o exemplo abaixo para saber como usá-lo

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

A tag `uniqueIndex` funciona de forma similar ao `index`, é igual a `index:unique`

```go
type User struct {
    Name1 string `gorm:"uniqueIndex"`
    Name2 string `gorm:"uniqueIndex:idx_name,sort:desc"`
}
```

## Índices compostos

Usar o mesmo nome de índice para dois campos irá criar índices compostos, por exemplo:

```go
// create composite index `idx_member` with columns `name`, `number`
type User struct {
    Name   string `gorm:"index:idx_member"`
    Number string `gorm:"index:idx_member"`
}
```

### Prioridade dos campos

A ordem das colunas de um índice composto tem um impacto no seu desempenho, então ele deve ser escolhido com cuidado

Você pode especificar a ordem com a opção `priority` , o valor da prioridade padrão é `10`, se o valor da prioridade for o mesmo, a ordem será baseada no índice de campo do modelo de estrutura

```go
type User struct {
    Name   string `gorm:"index:idx_member"`
    Number string `gorm:"index:idx_member"`
}
// ordem das colunas: name, number

type User struct {
    Name   string `gorm:"index:idx_member,priority:2"`
    Number string `gorm:"index:idx_member,priority:1"`
}
// ordem das colunas: number, name

type User struct {
    Name   string `gorm:"index:idx_member,priority:12"`
    Number string `gorm:"index:idx_member"`
}
// ordem das colunas: number, name
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

## Múltiplos índices

A field accepts multiple `index`, `uniqueIndex` tags that will create multiple indexes on a field

```go
type UserIndex struct {
    OID          int64  `gorm:"index:idx_id;index:idx_oid,unique"`
    MemberNumber string `gorm:"index:idx_id"`
}
```
