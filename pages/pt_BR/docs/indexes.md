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

## Múltiplos índices

Um campo aceita múltiplas tags `index`, `uniqueIndex` que irão criar vários índices em um campo

```go
type UserIndex struct {
    OID          int64  `gorm:"index:idx_id;index:idx_oid,unique"`
    MemberNumber string `gorm:"index:idx_id"`
}
```
