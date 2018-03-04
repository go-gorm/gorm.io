---
title: Belongs To
layout: page
---
## Belongs To

Una asociación `belongs to` establece una conexión uno a uno con otro modelo, de modo que cada instancia del modelo de declaración "pertenece a" una instancia del otro modelo.

Por ejemplo, si su aplicación incluye usuarios y perfiles, y cada perfil puede asignarse exactamente a un usuario

```go
type User struct {   gorm.Model   Name string } // `Profile` pertenece a `User`, `UserID` es la clave foránea type Profile struct {   gorm.Model   UserID int   User User   Name string }
```

## Clave Foránea

Para definir una relación de pertenencia, la clave foránea debe existir, la clave foránea predeterminada usa el nombre de tipo más su clave principal.

Para el ejemplo anterior, para definir un modelo que pertenece a `User`, la clave foránea debe ser `UserID`.

GORM proporciona una manera de personalizar la clave foránea, por ejemplo:

```go
type User struct {
    gorm.Model
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"foreignkey:UserRefer"` // use UserRefer as foreign key
  UserRefer string
}
```

## Association ForeignKey

For a belongs to relationship, GORM usually use owner's primary key as the foreign key's value, for above example, it is `User`'s `ID`.

When you assign a profile to a user, GORM will save user's `ID` into profile's `UserID` field.

You are able to change it with tag `association_foreignkey`, e.g:

```go
type User struct {
    gorm.Model
  Refer int
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"association_foreignkey:Refer"` // use Refer as association foreign key
  UserRefer string
}
```

## Working with Belongs To

You could find `belongs to` assciations with `Related`

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 is user's ID
```

For advanced usage, refer [Association Mode](/docs/associations.html#Association-Mode)