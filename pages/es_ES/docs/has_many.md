---
title: Has Many
layout: page
---
## Has Many

Una asociación `has many` también establece una conexión de uno a muchos con otro modelo, a diferencia de `has one`, el propietario podría tener cero o muchas instancias de modelos.

Por ejemplo, si su aplicación incluye usuarios y tarjetas de crédito, y cada usuario puede tener muchas tarjetas de crédito.

```go
// El Usuario tiene muchos correos electrónicos, UserID es la clave foránea type User struct {     gorm.Model     CreditCards []CreditCard } type CreditCard struct {     gorm.Model     Number string     UserID uint }
```

## Clave Foránea

Para definir una relación a muchos, debe existir una clave foránea, el nombre predeterminado de la clave foránea es el nombre del tipo más su clave principal.

Para el ejemplo anterior, para definir un modelo que pertenece a `User`, la clave foránea debe ser `UserID`.

Para usar otro campo como clave foránea, puede personalizarlo con la etiqueta `foreignkey`, por ejemplo:

```go
type User struct {
    gorm.Model
    CreditCards []CreditCard `gorm:"foreignkey:UserRefer"`
}

type CreditCard struct {
    gorm.Model
    Number    string
  UserRefer uint
}
```

## Asociación ForeignKey

GORM generalmente utiliza la clave principal del usuario como el valor de la clave foránea, para el ejemplo anterior, es `User`'s `ID`,

Cuando asigna tarjetas de crédito a un usuario, GORM guardará el `ID` del usuario en el campo `UserID` de las tarjetas de crédito.

Puede cambiarlo con la etiqueta `association_foreignkey`, por ejemplo:

```go
type User struct {
    gorm.Model
  MemberNumber string
    CreditCards  []CreditCard `gorm:"foreignkey:UserMemberNumber,association_foreignkey:MemberNumber"`
}

type CreditCard struct {
    gorm.Model
    Number           string
  UserMemberNumber string
}
```

## Asociación de Polimorfismo

Admite asociaciones polimórficas para has-many y has-one.

```go
  type Cat struct {
    ID    int
    Name  string
    Toy   []Toy `gorm:"polymorphic:Owner;"`
  }

  type Dog struct {
    ID   int
    Name string
    Toy  []Toy `gorm:"polymorphic:Owner;"`
  }

  type Toy struct {
    ID        int
    Name      string
    OwnerID   int
    OwnerType string
  }
```

Nota: las asociaciones polimórficas belongs-to y many-to-many NO son compatibles y producirán errores.

## Trabajando con Has Many

Puede encontrar asociaciones `has many` con `Related`

```go
db.Model(&user).Related(&emails) //// SELECT * FROM emails WHERE user_id = 111; // 111 es la clave principal del usuario
```

Para un uso avanzado, consulte [Modo de Asociación](/docs/associations.html#Association-Mode)