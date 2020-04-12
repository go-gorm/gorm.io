---
title: Associations
layout: page
---

## Création/Mise à jour automatique

GORM enregistre automatiquement les associations et leurs référence lors de la création/mise à jour d'un enregistrement. Si une association a une clé primaire, GORM appellera `Update` pour l'enregister. Sinon, l'association sera crée.

```go
user := User{
  Name:            "valem",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "valem@example.com"},
    {Email: "valem-2@example.com"},
  },
  Languages:       []Language{
    {Name: "FR"},
    {Name: "EN"},
  },
}

db.Create(&user)
//// BEGIN TRANSACTION;
//// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1");
//// INSERT INTO "addresses" (address1) VALUES ("Shipping Address - Address 1");
//// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("valem", 1, 2);
//// INSERT INTO "emails" (user_id,email) VALUES (111, "valem@example.com");
//// INSERT INTO "emails" (user_id,email) VALUES (111, "valem-2@example.com");
//// INSERT INTO "languages" ("name") VALUES ('MNE);
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 1);
//// INSERT INTO "languages" ("name") VALUES ('EN');
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 2);
//// COMMIT;

db.Save(&user)
```

## Ignorer la mise à jour automatique

Si votre association existe déjà dans la base de données, vous ne voudrez peut-être pas la mettre à jour.

Vous pouvez définir le paramètre DB `gorm:association_autoupdate` à `false`

```go
// Ne mettra pas à jour les associations ayant une clé primaire, mais sauvera la référence
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
```

ou utiliser les tags GORM, `gorm:"association_autoupdate:false"`

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // Ne mettra pas à jour les associations ayant une clé primaire, mais sauvera la référence
  Company    Company `gorm:"association_autoupdate:false"`
}
```

## Ignorer la création automatique

Même si vous avez désactivé `AutoUpdating`, les associations sans clé primaire doivent quand même être créées et leur référence enregistrée.

Pour désactiver cela, vous pouvez définir le paramètre DB `gorm:association_autocreate` à `false`

```go
// Ne pas créer d'associations sans clé primaire, NE sauve PAS sa référence
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)
```

ou utiliser les tags GORM, `gorm:"association_autocreate:false"`

    type User struct {
      gorm.Model
      Name       string
      // Don't create associations w/o primary key, WON'T save its reference
      Company1   Company `gorm:"association_autocreate:false"`
    }
    

## Sauter la création & la mise à jour automatique

Pour désactiver `AutoCreate` et `AutoUpdate`, vous pouvez utiliser ces deux paramètres ensemble

```go
db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
```

Ou utiliser `gorm:save_associations`

    db.Set("gorm:save_associations", false).Create(&user)
    db.Set("gorm:save_associations", false).Save(&user)
    
    type User struct {
      gorm.Model
      Name    string
      Company Company `gorm:"save_associations:false"`
    }
    

## Sauter l'enregistrement de la référence

Si vous ne voulez même pas enregister la référence d'une association lors de la mise à jour ou de l'enregistrement de données, vous pouvez utiliser les trucs suivants

```go
db.Set("gorm:association_save_reference", false).Save(&user)
db.Set("gorm:association_save_reference", false).Create(&user)
```

ou utiliser le tag

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"association_save_reference:false"`
}
```

## Mode association

Le mode association contient des méthodes d'assistance pour gérer les relations facilement.

```go
// Débuter le mode association
var user User
db.Model(&user).Association("Languages")
// `user` est la source, doit contenir une clé primaire
// `Languages` est le nom du champ de la source pour une relation
// AssociationMode fonctionne seulement si les deux conditions plus haut sont remplies, vérifie si c'est le cas ou pas:
// db.Model(&user).Association("Languages").Error
```

### Trouver des associations

Trouvé les associations correspondantes

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### Joindre les associations

Joint de nouvelles associations pour `many to many`, `has many`, remplace les associations actuelles pour `has one`, `belongs to`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
```

### Remplacer des associations

Remplace les associations actuelles par de nouvelles associations

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Supprimer des associations

Retire la relation entre la source les objets en paramètre, supprime seulement la référence, ne supprimera pas ces objets de la BDD.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Réinitialiser des associations

Retire la référence entre la source et les associations actuelles, ne supprimera pas ces associations

```go
db.Model(&user).Association("Languages").Clear()
```

### Compter les associations

Retourne le compte des associations actuelles

```go
db.Model(&user).Association("Languages").Count()
```