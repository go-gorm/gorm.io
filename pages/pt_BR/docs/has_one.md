---
title: Has One
layout: page
---

## Has One

Uma associação `has one`, confgura uma conexão um para um com outro modelo, mas com semântica diferente de alguma forma (e consequências). Essa associação indica que cada instância do modelo contem ou possui uma instância de outro modelo.

Por exemplo, se sua aplicação inclui usuários e cartão de crédito, e cada usuário só pode ter um cartão de crédito.

### Declare
```go
// User has one CreditCard, UserID is the foreign key
type User struct {
  gorm.Model
  CreditCard CreditCard
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```

### Retrieve
```go
// Retrieve user list with eager loading credit card
func GetAll(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("CreditCard").Find(&users).Error
    return users, err
}
```

## Override Foreign Key

Para um relacionamento `has one`, um campo de chave estrangeira deve existir, o dono irá salvar a chave primária do modelo que pertence a ele nesse campo.

O nome do campo geralmente é gerado com o tipo do modelo do `has one`, mais a sua `primary key`, para o exemplo acima é `UserID`.

Quando você der um cartão de crédito para o usuário, ele vai salvar o `ID` do Usuário no campo `UserID`.

Se você quiser usar outro campo para salvar o relacionamento, você pode mudar isso com a tag `foreignKey`, ex:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"foreignKey:UserName"`
  // utilizar UserName como chave estrangeira
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## Sobrescrever referências

Po padrão, a entidade irá salvar a chave primária do modelo `has one` em uma chave estrangeira, você pode alterar para salvar em outro campo, como por exemplo `Name` para o exemplo abaixo.

Você pode mudar isso com a tag `references`, ex:

```go
type User struct {
  gorm.Model
  Name       string     `gorm:"index"`
  CreditCard CreditCard `gorm:"foreignKey:UserName;references:name"`
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## CRUD with Has One

Please checkout [Association Mode](associations.html#Association-Mode) for working with `has one` relations

## Eager Loading

GORM allows eager loading `has one` associations with `Preload` or `Joins`, refer [Preloading (Eager loading)](preload.html) for details

## Self-Referential Has One

```go
type User struct {
  gorm.Model
  Name      string
  ManagerID *uint
  Manager   *User
}
```

## FOREIGN KEY Constraints

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, it will be created when migrating with GORM, for example:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```

You are also allowed to delete selected has one associations with `Select` when deleting, checkout [Delete with Select](associations.html#delete_with_select) for details
