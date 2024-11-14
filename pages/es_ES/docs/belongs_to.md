---
title: Pertenecer a
layout: page
---

## Pertenecer a

Un `pertenece a` establece una conexión de uno a uno con otro modelo, de tal manera que cada instancia del modelo declarante "pertenece" a una instancia del otro modelo.

Por ejemplo, si su aplicación incluye usuarios y empresas, y cada usuario puede ser asignado a una empresa exactamente, los siguientes tipos representan esa relación. Ten en cuenta que en el objeto `User` hay tanto un `CompanyID` como una `Company`. Por defecto, el `CompanyID` se utiliza implícitamente para crear una relación de clave foránea entre las tablas `User` y `Company`, y por lo tanto debe incluirse en la estructura `User` con el fin de llenar el struct `Company`.

```go
// `User` belongs to `Company`, `CompanyID` is the foreign key
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

Consulte [Carga diligente](belongs_to.html#Eager-Loading) para obtener detalles sobre cómo llenar la estructura interior.

## Sobrescritura de Clave Foránea

Para definir una relación de pertenencia, la clave foránea debe existir, la clave foránea por defecto utiliza el nombre del tipo del propietario más el nombre del campo principal.

Para el ejemplo anterior, para definir el modelo `User` que pertenece a `Company`, la clave foránea debe ser `CompanyID` por convención

GORM proporciona una manera de personalizar la clave foránea, por ejemplo:

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // use CompanyRefer as foreign key
}

type Company struct {
  ID   int
  Name string
}
```

## Sobrescritura de Referencias

Para una relación perteneciente, GORM usualmente usa el campo primario del propietario como el valor de la clave foránea, para el ejemplo anterior, es el campo `ID` de `Company`.

Al asignar un usuario a una empresa, GORM guardará el `ID` de la empresa en el campo `CompanyID` del usuario.

Puedes cambiarlo con la etiqueta `references`, por ejemplo:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // use Code as references
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

{% note warn %}
**NOTA** GORM generalmente asume la relación como `tiene una` si el nombre de clave foránea ya existe en el tipo del propietario, necesitamos especificar `references` en la relación `pertenece a`.
{% endnote %}

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company `gorm:"references:CompanyID"` // use Company.CompanyID as references
}

type Company struct {
  CompanyID   int
  Code        string
  Name        string
}
```

## CRUD con Pertenece a

Por favor, compruebe que [el modo de asociación](associations.html#Association-Mode) para trabajar con relaciones pertenece a

## Carga diligente

GORM permite la carga diligente con asociaciones pertenece a usando `precarga` o `Uniones`, consulte [precarga (carga diligente)](preload.html) para más detalles

## Restricciones de Clave Foránea

Puede configurar `OnUpdate`, `OnDelete` restricciones con la etiqueta `constraint`, se creará al migrar con GORM, por ejemplo:

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
