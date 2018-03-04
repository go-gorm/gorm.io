---
title: Delete
layout: page
---
## Eliminar Registro

**ADVERTENCIA** Cuando elimine un registro, debe asegurarse de que el campo primario tenga un valor, y GORM utilizará la clave primaria para eliminarlo, si el campo primario está en blanco, GORM eliminará todos los registros del modelo

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

Si el modelo tiene el campo `DeletedAt`, ¡Tendrá la posibilidad de borrar automáticamente! luego no se eliminará de la base de datos permanentemente cuando se llame a `Eliminar`, sino que solo configure el valor del campo `DeletedAt` a la hora actual

```go
db.Delete(&user) //// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111; // Eliminación por lote db.Where("age = ?", 20).Delete(&User{}) //// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20; // Los registros eliminados se ignorarán cuando se los consulte them db.Where("age = 20").Find(&user) //// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL; // Encuentra registros borrados por Unscope db.Unscoped().Where("age = 20").Find(&users) //// SELECT * FROM users WHERE age = 20; // Delete record permanently with Unscoped db.Unscoped().Delete(&order) //// DELETE FROM orders WHERE id=10;
```