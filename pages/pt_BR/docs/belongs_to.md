---
title: Associação "pertente a" (belongs to)
layout: page
---

## Associação "pertente a" (belongs to)

Uma associação `belongs to` cria uma conexão um-para-um com outro model, que cada instância do model de declaração "pertença" a uma instância do outro modelo.

Por exemplo, se seu aplicativo inclui users e companies, e cada user pode ser atribuído a exatamente uma company, os seguintes tipos representam esse relacionamento. Observe aqui que, no objeto</code>User`, há uma <code>CompanyID` e também uma `Company`. Por padrão, o `CompanyID` é implicitamente usado para criar uma relação de chave estrangeira entre as tabelas `User` e `Company` , e assim deve ser incluído no componente `User` para preencher a estrutura interna da `Company`.

```go
// `User` pertence a `Company`, `CompanyID` é a chave estrangeira
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company
}

type Company struct {
  ID   int
  Name string
}
```

Consulte o [Eager Loading](belongs_to.html#Eager-Loading) para detalhes sobre como preencher a estrutura interna.

## Sobrescrever Chave Externa

Para definir um relacionamento "pertence a" (belongs to), a chave estrangeira deve existir, a chave estrangeira padrão usa o tipo do campo mais seu nome de campo primário.

Para o exemplo acima, para definir o model `User` que pertence à `Company`, a chave estrangeira deve ser `CompanyID` por convenção

GORM fornece uma maneira de personalizar a chave estrangeira, por exemplo:

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // use CompanyRefer como chave estrangeira
}

type Company struct {
  ID   int
  Name string
}
```

## Sobrepor referências

Para um relacionamento "pertence a" (belongs to), GORM geralmente usa o campo da chave primária como o valor da chave estrangeira, para o exemplo acima, é o campo `ID` do `Company`.

Quando você vincular um user a uma Company, GORM salvará o `ID` da Company no campo `Company`.

Você é capaz de alterá-lo com a tag `references`, por exemplo:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // use Code como referência
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

{% note warn %}
**OBSERVE** GORM geralmente considera o relacionamento como `has one` se o nome da chave estrangeira já existe no type de origem, precisamos especificar `references` no relacionamento `belongs to`.
{% endnote %}

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:CompanyID"` // use Company.CompanyID como referência
}

type Company struct {
  CompanyID   int
  Code        string
  Name        string
}
```

## CRUD com "pertence a" (Belongs To)

Consulte [Modo de Associação](associations.html#Association-Mode) para trabalhar com relacionamentos "pertence a" (Belongs to)

## Eager Loading

GORM permite que o Eager Loading em relacionamentos "pertence a" (Belongs to) com `Preload` ou `Joins`, consulte [Pré-carregamento (Eager Loading)](preload.html) para detalhes

## Restrições (constraints) de chaves estrangeiras

Você pode configurar as restrições (constraints) `OnUpdate`, `OnDelete` com a tag `OnDelete`, ela será criada quando realizar as migrates com o GORM, por exemplo:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type Company struct {
  ID   int
  Name string
}
```
