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

## Foreign Key

Para definir una relación de pertenencia, la clave foránea debe existir, la clave foránea predeterminada usa el nombre de tipo más su clave principal.

Para el ejemplo anterior, para definir un modelo que pertenece a `User`, la clave foránea debe ser `UserID`.

GORM provides a way to customize the foreign key, for example:

```go
type User struct {     gorm.Model     Name string } type Profile struct {     gorm.Model   Name string   User User `gorm:"foreignkey:UserRefer"` // usa UserRefer como clave foránea  UserRefer string }
```

## Asociación ForeignKey

For a belongs to relationship, GORM usually uses the owner's primary key as the foreign key's value, for above example, it is `User`'s `ID`.

Cuando asigna un perfil a un usuario, GORM guardará el `ID` del usuario en el campo `UserID`.

Puede cambiarlo con la etiqueta `association_foreignkey`, por ejemplo:

```go
type User struct {
    gorm.Model
  Refer int
    Name string
}

type Profile struct {
    gorm.Model
  Name      string
  User      User `gorm:"association_foreignkey:Refer"` // usa Refer como clave foránea de asociación
  UserRefer string
}
```

## Trabajando con Belongs To

You could find `belongs to` associations with `Related`

```go
db.Model(&user).Related(&profile) //// SELECT * FROM profiles WHERE user_id = 111; // 111 es el ID de usuario
```

Para un uso avanzado, consulte [Modo de Asociación](/docs/associations.html#Association-Mode)