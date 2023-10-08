---
title: Associations
layout: page
---

## Auto Create/Update

GORM enregistrera automatiquement les associations et ses références en utilisant [Upsert](create.html#upsert) lors de la création/mise à jour d'un enregistrement.

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db.Create(&user)
// BEGIN TRANSACTION;
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "languages" ("name") VALUES ('ZH'), ('EN') ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "user_languages" ("user_id","language_id") VALUES (111, 1), (111, 2) ON DUPLICATE KEY DO NOTHING;
// COMMIT;

db.Save(&user)
```

Si vous voulez mettre à jour les données des associations, vous devez utiliser le mode `FullSaveAssociations`:

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## Skip Auto Create/Update

Pour ignorer la sauvegarde automatique lors de la création/mise à jour, vous pouvez utiliser ` Select ` ou `Omit`, par exemple :

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db.Select("Name").Create(&user)
// INSERT INTO "users" (name) VALUES ("jinzhu", 1, 2);

db.Omit("BillingAddress").Create(&user)
// Skip create BillingAddress when creating a user

db.Omit(clause.Associations).Create(&user)
// Skip all associations when creating a user
```

{% note warn %}
**NOTE :** Pour de nombreuses associations, GORM fera la mise en valeur des associations avant de créer les références de la table d'association, si vous voulez sauter l'insertion des associations, vous pouvez passer comme :

```go
db.Omit("Languages.*").Create(&user)
```

Le code suivant ignorera la création de l'association et de ses références

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## Select/Omit Champs d'association

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// Create user and his BillingAddress, ShippingAddress
// When creating the BillingAddress only use its address1, address2 fields and omit others
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## Mode d'association

Le mode association contient des méthodes d'aide couramment utilisées pour gérer les relations

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source model, it must contains primary key
// `Languages` is a relationship's field name
// If the above two requirements matched, the AssociationMode should be started successfully, or it should return error
db.Model(&user).Association("Languages").Error
```

### Trouver des associations

Trouver les associations correspondantes

```go
db.Model(&user).Association("Languages").Find(&languages)
```

Trouver des associations avec des conditions

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### Ajouter des associations

Ajouter de nouvelles associations pour `many to many`, `has many`, remplacer l'association actuelle pour `has one`, `belongs to`</code>

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
```

### Remplacer des associations

Remplacer les associations actuelles par de nouvelles associations

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Supprimer des associations

Supprimer la relation entre les arguments source & s'il existe, supprimer seulement la référence, ne supprimera pas ces objets de la base de données.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Clear Associations

Supprimer toutes les références entre l'association source & ne supprimera pas ces associations

```go
db.Model(&user).Association("Languages").Clear()
```

### Nombre d'associations

Renvoie le nombre d'associations actuelles

```go
db.Model(&user).Association("Languages").Count()

// Count with conditions
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Batch Data

Le mode association supporte les données par lot, par exemple:

```go
// Find all roles for all users
db.Model(&users).Association("Role").Find(&roles)

// Delete User A from all user's team
db.Model(&users).Association("Team").Delete(&userA)

// Get distinct count of all users' teams
db.Model(&users).Association("Team").Count()

// For `Append`, `Replace` with batch data, the length of the arguments needs to be equal to the data's length or else it will return an error
var users = []User{user1, user2, user3}
// e.g: we have 3 users, Append userA to user1's team, append userB to user2's team, append userA, userB and userC to user3's team
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Reset user1's team to userA，reset user2's team to userB, reset user3's team to userA, userB and userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_association_record">Supprimer l'enregistrement de l'association</span>

Par défaut `Replace`/`Delete`/`Clear` dans `gorm.Association` ne supprime que la référence, qui est, définit la clé étrangère des anciennes associations à null.

Vous pouvez supprimer ces objets avec `Unscoped` (cela n'a rien à voir avec `ManyToMany`).

How to delete is decided by `gorm.DB`.

```go
// Soft delete
// UPDATE `languages` SET `deleted_at`= ...
db.Model(&user).Association("Languages").Unscoped().Clear()

// Delete permanently
// DELETE FROM `languages` WHERE ...
db.Unscoped().Model(&item).Association("Languages").Unscoped().Clear()
```

## <span id="delete_with_select">Delete with Select</span>

You are allowed to delete selected has one/has many/many2many relations with `Select` when deleting records, for example:

```go
// delete user's account when deleting user
db.Select("Account").Delete(&user)

// delete user's Orders, CreditCards relations when deleting user
db.Select("Orders", "CreditCards").Delete(&user)

// delete user's has one/many/many2many relations when deleting user
db.Select(clause.Associations).Delete(&user)

// delete each user's account when deleting users
db.Select("Account").Delete(&users)
```

{% note warn %}
**NOTE:** Associations will only be deleted if the deleting records's primary key is not zero, GORM will use those primary keys as conditions to delete selected associations

```go
// DOESN'T WORK
db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{})
// will delete all user with name `jinzhu`, but those user's account won't be deleted

db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{ID: 1})
// will delete the user with name = `jinzhu` and id = `1`, and user `1`'s account will be deleted

db.Select("Account").Delete(&User{ID: 1})
// will delete the user with id = `1`, and user `1`'s account will be deleted
```
{% endnote %}

## <span id="tags">Association Tags</span>

| Tag              | Description                                                                                        |
| ---------------- | -------------------------------------------------------------------------------------------------- |
| foreignKey       | Specifies column name of the current model that is used as a foreign key to the join table         |
| references       | Specifies column name of the reference's table that is mapped to the foreign key of the join table |
| polymorphic      | Specifies polymorphic type such as model name                                                      |
| polymorphicValue | Specifies polymorphic value, default table name                                                    |
| many2many        | Specifies join table name                                                                          |
| joinForeignKey   | Specifies foreign key column name of join table that maps to the current table                     |
| joinReferences   | Specifies foreign key column name of join table that maps to the reference's table                 |
| constraint       | Relations constraint, e.g: `OnUpdate`,`OnDelete`                                                   |
