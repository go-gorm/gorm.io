---
title: Associations
layout: page
---

## Crear/ actualizar Automáticamente

GORM guardará automáticamente asociaciones y su referencia al usar [Upsert](create.html#upsert), cuando se crear/actualiza un registro.

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

Si desea actualizar los datos de las asociaciones, debe usar el modo `FullSaveAssociations` mode:

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## Crear/ actualizar Automáticamente

Para omitir el guardado automático al crear/actualizar, puede utilizar `Select` o `Omit`, por ejemplo:

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
**NOTA:** Para las asociaciones many2many, GORM actualizará las asociaciones antes de crear las referencias de la tabla de unión, si quieres omitir el upseting de las asociaciones, puedes saltarla:

```go
db.Omit("Languages.*").Create(&user)
```

El siguiente código omitirá la creación de la asociación y sus referencias

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## Seleccionar/Omitir campos de asociación

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

## Modo de asociación

El modo de asociación contiene algunos métodos de ayuda comúnmente utilizados para manejar relaciones

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source model, it must contains primary key
// `Languages` is a relationship's field name
// If the above two requirements matched, the AssociationMode should be started successfully, or it should return error
db.Model(&user).Association("Languages").Error
```

### Buscar asociaciones

Buscar asociaciones coincidentes

```go
db.Model(&user).Association("Languages").Find(&languages)
```

Buscar asociaciones con condiciones

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### Añadir asociaciones

Añadir nuevas asociaciones para `muchas a muchas`, `tiene muchas`, reemplazar asociación actual para `tiene un`, `pertenece a`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
```

### Reemplazar asociaciones

Reemplazar asociaciones actuales por nuevas

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Eliminar Asociaciones

Eliminar la relación entre la fuente & argumentos si existe, solo eliminar la referencia, no eliminará esos objetos de la DB.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Limpiar asociaciones

Eliminar toda referencia entre la fuente & asociación, no eliminará esas asociaciones

```go
db.Model(&user).Association("Languages").Clear()
```

### Contar Asociaciones

Devolver el recuento de asociaciones actuales

```go
db.Model(&user).Association("Languages").Count()

// Count with conditions
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Datos de Lote

El modo de asociación soporta datos por lotes, por ejemplo:

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

## <span id="delete_with_select">Eliminar con Seleccionar</span>

Puede eliminar los registros seleccionados tiene una/tiene muchas/muchos a muchos relaciones con `Select` al eliminar registros, por ejemplo:

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
**NOTA:** Las asociaciones solo se eliminarán si la clave principal de los registros de eliminación no es cero, GORM utilizará esas claves primarias como condiciones para eliminar las asociaciones seleccionadas

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

## <span id="tags">Etiquetas de asociación</span>

| Etiqueta         | Descripción                                                                                                    |
| ---------------- | -------------------------------------------------------------------------------------------------------------- |
| foreignKey       | Especifica el nombre de la columna del modelo actual que se utiliza como clave foránea para la tabla de unión  |
| references       | Especifica el nombre de la columna de la tabla de referencia que se asigna a la clave foránea de la tabla join |
| polymorphic      | Especifica el tipo polimórfico como el nombre del modelo                                                       |
| polymorphicValue | Especifica el valor polimórfico, nombre de tabla por defecto                                                   |
| many2many        | Especifica el nombre de la tabla de unión                                                                      |
| joinForeignKey   | Especifica el nombre de columna de clave foránea de la tabla de unión que mapea a la tabla actual              |
| joinForeignKey   | Especifica el nombre de columna de clave foránea de la tabla de unión que mapea a la tabla de referencia       |
| constraint       | Restricción de relaciones, por ejemplo: `OnUpdate`,`OnDelete`                                                  |
