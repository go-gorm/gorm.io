---
title: Asociaciones
layout: page
---

## Auto Create/Update

GORM guardará automáticamente asociaciones y su referencia cuando crea/actualiza un registro. Si una asociación tiene una clave principal, GORM pedirá `Actualizar` para guardarla, de lo contrario será creado.

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
//// BEGIN TRANSACTION;
//// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1");
//// INSERT INTO "addresses" (address1) VALUES ("Shipping Address - Address 1");
//// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
//// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com");
//// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu-2@example.com");
//// INSERT INTO "languages" ("name") VALUES ('ZH');
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 1);
//// INSERT INTO "languages" ("name") VALUES ('EN');
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 2);
//// COMMIT;

db.Save(&user)
```

## Saltar Actualización Automática

Si su asociación ya existe en la base de datos, podría no querer actualizarla.

Usted podría utilizar configuración DB, establezca `gorm:association_autoupdate` a `falso`

```go
// No actualizar asociaciones que tengan clave principal, pero guardar referencia
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
```

o utilice etiquetas GORM, `gorm:"association_autoupdate:false"`

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // Don't update associations having primary key, but will save reference
  Company    Company `gorm:"association_autoupdate:false"`
}
```

## Saltar Creación Automática

Aún cuando haya deshabilitado `AutoUpdating`, asociaciones sin clave principal aún deben ser creadas y su referencia será guardada.

Para deshabilitar esto, puede establecer la configuración DB `gorm:association_autocreate` a `falso`

```go
//No crear asociaciones sin la clave principal, NO guardará su referencia
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)
```

o use etiquetas GORM, `gorm:"association_autocreate:false"`

    type User struct {
      gorm.Model
      Name       string
      // Don't create associations w/o primary key, WON'T save its reference
      Company1   Company `gorm:"association_autocreate:false"`
    }
    

## Saltar Creación/Actualización Automática

To disable both `AutoCreate` and `AutoUpdate`, you could use those two settings together

```go
db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
```

O utilice `gorm:save_associations`

    db.Set("gorm:save_associations", false).Create(&user)
    db.Set("gorm:save_associations", false).Save(&user)
    
    type User struct {
      gorm.Model
      Name    string
      Company Company `gorm:"save_associations:false"`
    }
    

## Saltar Guardado de Referencia

Si no desea guardar la referencia de asociación cuando actualiza/guarda datos, puede utilizar los siguientes trucos

```go
db.Set("gorm:association_save_reference", false).Save(&user)
db.Set("gorm:association_save_reference", false).Create(&user)
```

o usar la etiqueta

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"association_save_reference:false"`
}
```

## Modo de Asociación

El Modo de Asociación contiene métodos de ayuda para manejar cosas relativas con relaciones fácilmente.

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source, must contains primary key
// `Languages` is source's field name for a relationship
// AssociationMode can only works if above two conditions both matched, check it ok or not:
// db.Model(&user).Association("Languages").Error
```

### Buscar Asociaciones

Encontrar asociaciones compatibles

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### Añadir Asociaciones

Añadir nuevas asociaciones para `numerosas`, `tiene numerosas`, reemplazar asociaciones actuales por `tiene una`,`pertenece a`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
```

### Reemplazar Asociaciones

Reemplazar asociaciones actuales con otras nuevas

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Eliminar Asociaciones

Eliminar relación entre la fuente & objetos de argumento, solo eliminar la referencia, no eliminará esos objetos de DB.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Clear Associations

Remove reference between source & current associations, won't delete those associations

```go
db.Model(&user).Association("Languages").Clear()
```

### Count Associations

Return the count of current associations

```go
db.Model(&user).Association("Languages").Count()
```