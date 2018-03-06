---
title: Has One
layout: page
---
## Has One

Una asociación `has one` también establece una conexión uno a uno con otro modelo, pero con semántica (y consecuencias) diferentes. Esta asociación indica que cada instancia de un modelo contiene o posee una instancia de otro modelo.

Por ejemplo, si su aplicación incluye usuarios y tarjetas de crédito, y cada usuario sólo puede tener una tarjeta de crédito.

```go
// El usuario tiene una tarjeta de crédito, CreditCardID es la clave foránea
type User struct {
    gorm.Model
    CreditCard   CreditCard
   CreditCardID uint
}

type CreditCard struct {
    gorm.Model
    Number   string
}
```

## Clave Foránea

Para una relación has one, también debe existir un campo de clave foránea, el usuario guardará la clave primaria del modelo que le pertenece en este campo.

El nombre del campo generalmente se genera con `belongs to model`'s más su `primary key`, para el ejemplo anterior, es `CreditCardID`

Cuando se le da una tarjeta de crédito al usuario, guardará el `ID` de la tarjeta de crédito en su campo `CreditCardID`.

Si desea usar otro campo para guardar la relación, puede cambiarlo con la etiqueta `foreignkey`, por ejemplo:

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"foreignkey:CardRefer"`
  CardRefer uint
}

type CreditCard struct {
    gorm.Model
    Number string
}
```

## Asociación ForeignKey

Por defecto, el usuario guardará la asociación `belogns to model` en una clave foránea, puede cambiarla para guardar en otro campo, tal como `Number` para el siguiente ejemplo.

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"association_foreignkey:Number"`
  CardRefer uint
}

type CreditCard struct {
    gorm.Model
    Number string
}
```

## Asociación de Polimorfismo

Admite asociaciones polimórficas para has-many y has-one.

```go
  type Cat struct {
    ID    int
    Name  string
    Toy   Toy `gorm:"polymorphic:Owner;"`
  }

  type Dog struct {
    ID   int
    Name string
    Toy  Toy `gorm:"polymorphic:Owner;"`
  }

  type Toy struct {
    ID        int
    Name      string
    OwnerID   int
    OwnerType string
  }
```

Nota: las asociaciones polimórficas belongs-to y many-to-many NO son compatibles y producirán errores.

## Trabajando con Has One

Puede encontrar asociaciones `has one` con `Related`

```go
var card CreditCard
db.Model(&user).Related(&card, "CreditCard")
//// SELECT * FROM credit_cards WHERE user_id = 123;
// 123 es la clave principal del usuario
// CreditCard es el nombre del campo del usuario, es decir obtener las relaciones CreditCard del usuario y llenar en una tarjeta variable
// si es igual que el nombre de tipo de la variable, como en el ejemplo anterior, podría omitirse, tal como:
db.Model(&user).Related(&card)
```

Para un uso avanzado, consulte [Modo de Asociación](/docs/associations.html#Association-Mode)