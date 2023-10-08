---
title: Appartient à (Belongs To)
layout: page
---

## Appartient à (Belongs To)

Une association `belongs to` met en place une connexion individuelle avec un autre modèle, de telle sorte que chaque instance du modèle déclarant "appartient" à une instance de l'autre modèle.

Par exemple, si votre application comprend des utilisateurs et des entreprises, et que chaque utilisateur peut être assigné à une seule entreprise, les types suivants représentent cette relation. Notez ici que, sur l'objet `User` , il y a à la fois une `CompanyID` ainsi qu'une `Company`. Par défaut, la `CompanyID` est implicitement utilisée pour créer une relation clé étrangère entre les tables `User` et `Company` et donc doit être inclus dans la structure `User` afin de remplir la structure intérieure `Company`.

```go
// `User` appartient à `Company`, `CompanyID` est la clé étrangère
type User struct {
  gorm.Model
  Name string
  CompanyID int
  Company
}

type Company struct {
  ID int
  Name string
}
```

Reportez-vous à [Eager Loading](belongs_to.html#Eager-Loading) pour plus de détails sur le remplissage de la structure intérieure.

## Redéfinir la clé étrangère

Pour définir une relation d'appartenance, la clé étrangère doit exister, la clé étrangère par défaut utilise le nom de type du propriétaire plus son nom de champ primaire.

Pour l'exemple ci-dessus, définir le modèle `User` qui appartient à `Company`, la clé étrangère doit être `CompanyID` par convention

GORM fournit un moyen de personnaliser la clé étrangère, par exemple :

```go
type User struct {
  gorm.Model
  Name string
  CompanyRefer int
  Company `gorm:"foreignKey:CompanyRefer"`
  // utiliser CompanyRefer comme clé étrangère
}

type Company struct {
  ID int
  Name string
}
```

## Surcharger les références

Pour une appartenance à une relation, GORM utilise généralement le champ principal du propriétaire comme valeur de la clé étrangère, pour l'exemple ci-dessus, il s'agit du champ `Company`du champ `ID`.

Lorsque vous assignez un utilisateur à une entreprise, GORM enregistrera l' `ID` de l'entreprise dans le champ `CompanyID` de l'utilisateur.

Vous pouvez le modifier avec le tag `references`, par exemple:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // utilise Code comme references
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

{% note warn %}
**NOTE** GORM devine généralement la relation comme `has one` si le nom de la clé étrangère est déjà remplacé dans le type du propriétaire, nous devons spécifier `references` dans la relation `belongs to`.
{% endnote %}

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:CompanyID"` // utilise Company.CompanyID comme references
}

type Company struct {
  CompanyID   int
  Code        string
  Name        string
}
```

## CRUD avec Belongs To

Veuillez consulter le [Mode d'association](associations.html#Association-Mode) pour travailler avec les relations belongs to

## Chargement Eager (pressé)

GORM permet au chargement désireux d'appartenir à des associations avec `Preload` ou `Joins`, se référer à [Préchargement (Eager loading)](preload.html) pour plus de détails

## Contraintes de la CLÉ étrangère

Vous pouvez configurer les contraintes `OnUpdate`, `OnDelete` avec la contrainte de balise `constraint`, il sera créé lors de la migration avec GORM, par exemple :

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
