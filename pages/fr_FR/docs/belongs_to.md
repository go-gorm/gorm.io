---
title: Belongs To
layout: page
---

## Belongs To

Une association `belongs to` (appartient à) met en place une connexion one-to-one avec un autre modèle, de telle sorte que chaque instance du modèle de déclaration "appartient à" une instance de l'autre modèle.

Par exemple, si votre application inclut des utilisateurs et des profils, et que chaque profil peut être assigné à un seul utilisateur

```go
type User struct {
  gorm.Model
  Name string
}

// `Profile` appartient à `User`, `UserID` est la clé étrangère
type Profile struct {
  gorm.Model
  UserID int
  User User
  Name string
}
```

## Foreign Key

Pour définir une relation d'appartenance, la clé étrangère (foreign key) doit exister, la clé étrangère par défaut utilise le nom de type du propriétaire plus sa clé primaire.

Pour l'exemple ci-dessus, pour définir un modèle qui appartient à `User`, la clé étrangère doit être `UserID`.

GORM fournit un moyen de personnaliser la clé étrangère, par exemple :

```go
type User struct {
  gorm.Model
  Name string
}

type Profile struct {
  gorm. odel
  Name string
  User `gorm:"foreignkey:UserRefer"` // utilisation de UserRefer comme clé étrangère
  UserRefer uint
}
```

## Association ForeignKey

Pour une relation d'appartenance, GORM utilise d'habitude la clé primaire du propriétaire comme valeur de clé étrangère. Pour l'exemple ci-dessus, c'est l'`ID` de `User`.

Lorsque vous assignez un profil à un utilisateur, GORM sauvegardera l'`ID` de l'utilisateur dans le champ `UserID` du profil.

Vous pouvez le modifier avec la balise `association_foreignkey`, par exemple:

```go
type User struct {
  gorm.Model
  Refer string
  Name string
}

type Profile struct {
  gorm.Model
  Name      string
  User      User `gorm:"association_foreignkey:Refer"` // utilisation de l'attribut Refer comme association de clé étrangère
  UserRefer string
}
```

## Travailler avec Belongs To

Vous pouvez trouver les associations `belongs to` avec `Related`

```go
db.Model(&user).Related(&profile)
//// SELECT * FROM profiles WHERE user_id = 111; // 111 est l'ID de User
```

Pour une utilisation avancée, référez-vous au [Mode d'association](associations.html#Association-Mode)