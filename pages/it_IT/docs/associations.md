---
title: Associazioni
layout: pagina
---
## Crea/Aggiorna automaticamente

GORM salverà automaticamente le associazioni e i relativi riferimenti durante la creazione/aggiornamento di un record. Se l'associazione ha una chiave primaria, GORM chiamerà `Update` per salvarlo, altrimenti verrà creato.

```go
user := User{
    Name:            "jinzhu",
    BillingAddress:  Address{Address1: "Billing Address - Address 1"},
    ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
    Emails:          []Email{
        {Email: "jinzhu@example.com"},
        {Email: "jinzhu-2@example@example.com"},
    },
    Languages:       []Language{
        {Name: "ZH"},
        {Name: "EN"},
    },
}

db.Create(&user)
//// INIZIO TRANSAZIONE;
//// INSERISCI IN "addresses" (address1) IL VALORE ("Billing Address - Address 1");
//// INSERISCI IN "addresses" (address1) IL VALORE ("Shipping Address - Address 1");
//// INSERISCI IN "users" (name,billing_address_id,shipping_address_id) IL VALORE ("jinzhu", 1, 2);
//// INSERISCI IN "emails" (user_id,email) IL VALORE (111, "jinzhu@example.com");
//// INSERISCI IN "emails" (user_id,email) IL VALORE (111, "jinzhu-2@example.com");
//// INSERISCI IN "languages" ("name") IL VALORE ('ZH');
//// INSERISCI IN user_languages ("user_id","language_id") IL VALORE (111, 1);
//// INSERISCI IN "languages" ("name") IL VALORE ('EN');
//// INSERISCI IN user_languages ("user_id","language_id") IL VALORE (111, 2);
//// CONSEGNA;

db.Save(&user)
```

## Salta aggiornamento automatico

Se la sua associazione è già esistente nel database, potresti non volerla aggiornare.

Puoi usare le impostazioni del Database, imposta `gorm:association_autoupdate` a `false`

```go
// Don't update associations having primary key, but will save reference
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
```

or use GORM tags, `gorm:"association_autoupdate:false"`

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // Don't update associations having primary key, but will save reference
  Company    Company `gorm:"association_autoupdate:false"`
}
```

## Skip AutoCreate

Even though you disabled `AutoUpdating`, associations w/o primary key still have to be created and its reference will be saved.

To disable this, you could set DB setting `gorm:association_autocreate` to `false`

```go
// Don't create associations w/o primary key, WON'T save its reference
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)
```

or use GORM tags, `gorm:"association_autocreate:false"`

    type User struct {
      gorm.Model
      Name       string
      // Don't create associations w/o primary key, WON'T save its reference
      Company1   Company `gorm:"association_autocreate:false"`
    }
    

## Skip AutoCreate/Update

To disable both `AutoCreate` and `AutoUpdate`, you could use those two settings togehter

```go
db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
```

Or use `gorm:save_associations`

    db.Set("gorm:save_associations", false).Create(&user)
    db.Set("gorm:save_associations", false).Save(&user)
    
    type User struct {
      gorm.Model
      Name    string
      Company Company `gorm:"association_autoupdate:false"`
    }
    

## Salta il salvataggio delle referenze

Se non si desidera salvare il riferimento dell'associazione durante l'aggiornamento/salvataggio dei dati, è possibile utilizzare i seguenti trucchetti

```go
db.Set("gorm:association_save_reference", false).Save(&user)
db.Set("gorm:association_save_reference", false).Create(&user)
```

oppure usa i tag

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"association_save_reference:false"`
}
```

## Association Mode

Association Mode contains some helper methods to handle relationship related things easily.

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source, is must contains primary key
// `Languages` is source's field name for a relationship
// AssociationMode can only works if above two conditions both matched, check it ok or not:
// db.Model(&user).Association("Languages").Error
```

### Find Associations

Find matched associations

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### Append Associations

Append new associations for `many to many`, `has many`, replace current associations for `has one`, `belongs to`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
```

### Sostituisci le associazioni

Sostituisci le associazioni correnti con delle nuove

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Cancella le associazioni

Rimuove la relazione tra la fonte & e l'argomento oggetto, rimuove solo il riferimento non cancella l'oggetto dal database.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Clear Associations

Remove reference between source & current associations, won't delete those associations

```go
db.Model(&user).Association("Languages").Clear()
```

### Conta le associazioni

Restituisce il conteggio delle associazioni attuali

```go
db.Model(&user).Association("Languages").Count()
```