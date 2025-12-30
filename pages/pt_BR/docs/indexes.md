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
Note that this will not work for unique composite indexes.

## Índices compostos

Usar o mesmo nome de índice para dois campos irá criar índices compostos, por exemplo:

```go
// Cria índice composto `idx_member` com colunas `name`, `number`
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

### Índices Compostos Compartilhados

Se você estiver criando índices compostos compartilhados com uma estrutura de incorporação, você não poderá especificar o nome do índice. como incorporar o struct mais de uma vez resulta no nome do índice duplicado no banco de dados.

Nesse caso, você pode usar a tag de índice `composite`, isso significa o id do índice composto. Todos os campos com a mesma identificação composta da construção são agrupados no mesmo índice, tal como a regra original. Mas a melhoria permite que a construção mais derivada/incorporada gere o nome do índice pela NamingStrategy. Por exemplo:

```go
type Foo struct {
  IndexA int `gorm:"index:,unique,composite:myname"`
  IndexB int `gorm:"index:,unique,composite:myname"`
}
```

Se a tabela Foo é criada, o nome do índice composto será `idx_foo_myname`.

```go
type Bar0 struct {
  Foo
}

type Bar1 struct {
  Foo
}
```

Espectivamente, o nome do índice composto é `idx_bar0_myname` e `idx_bar1_myname`.

`composite` só funciona se não especificar o nome do índice.

## Múltiplos índices

Um campo aceita múltiplas tags `index`, `uniqueIndex` que irão criar vários índices em um campo

```go
type UserIndex struct {
    OID          int64  `gorm:"index:idx_id;index:idx_oid,unique"`
    MemberNumber string `gorm:"index:idx_id"`
}
```
