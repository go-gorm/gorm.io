---
title: Delete
layout: page
---

## Eliminar Registro

**WARNING** When deleting a record, you need to ensure its primary field has value, and GORM will use the primary key to delete the record, if the primary key field is blank, GORM will delete all records for the model

```go
// Eliminar un registro existente db.Delete(&email) //// DELETE from emails where id=10; // Agregar una opción de SQL adicional para eliminar SQL db.Set("gorm:delete_option", "OPTION (OPTIMIZE FOR UNKNOWN)").Delete(&email) //// DELETE from emails where id=10 OPTION (OPTIMIZE FOR UNKNOWN);
```

## Eliminar por Lotes

Eliminar todos los registros que coinciden

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(Email{})
//// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(Email{}, "email LIKE ?", "%jinzhu%")
//// DELETE from emails where email LIKE "%jinzhu%";
```

## Borrado Rápido

If a model has a `DeletedAt` field, it will get a soft delete ability automatically! When calling `Delete`, the record will not be permanently removed from the database; rather, the `DeletedAt`'s value will be set to the current time

```go
db.Delete(&user)
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Batch Delete
db.Where("age = ?", 20).Delete(&User{})
//// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Soft deleted records will be ignored when query them
db.Where("age = 20").Find(&user)
//// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;

// Find soft deleted records with Unscoped
db.Unscoped().Where("age = 20").Find(&users)
//// SELECT * FROM users WHERE age = 20;
```

## Delete record permanently

    // Delete record permanently with Unscoped
    db.Unscoped().Delete(&order)
    //// DELETE FROM orders WHERE id=10;
