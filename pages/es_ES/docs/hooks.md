---
title: Hooks
layout: page
---
## Ciclo de Vida del Objeto

Los hooks son funciones que se llaman antes o después de la creación/consulta/actualización/eliminación.

Si ha definido los métodos especificados para un modelo, se llamará automáticamente al crear, actualizar, consultar, eliminar, y si alguna devolución de llamada devuelve un error, GORM detendrá las operaciones futuras y revertirá la transacción actual.

## Hooks

### Creando un objeto

Hooks disponibles para crear

```go
// begin transaction
BeforeSave
BeforeCreate
// save before associations
// update timestamp `CreatedAt`, `UpdatedAt`
// save self
// reload fields that have default value and its value is blank
// save after associations
AfterCreate
AfterSave
// commit or rollback transaction
```

Ejemplo de Código:

```go
func (u *User) BeforeSave() (err error) {
    if u.IsValid() {
        err = errors.New("can't save invalid data")
    }
    return
}

func (u *User) AfterCreate(scope *gorm.Scope) (err error) {
    if u.ID == 1 {
    scope.DB().Model(u).Update("role", "admin")
  }
    return
}
```

**NOTA** Las operaciones de Guardar/Eliminar en GORM se ejecutan en las transacciones de forma predeterminada, por lo que los cambios realizados en esa transacción no estarán visibles hasta que se haya confirmado. Si desea acceder a esos cambios en sus hooks, puede aceptar la transacción actual como argumento en sus hooks, por ejemplo:

```go
func (u *User) AfterCreate(tx *gorm.DB) (err error) {
    tx.Model(u).Update("role", "admin")
    return
}
```

### Actualizando un objeto

Hooks disponibles para actualizar

```go
// begin transaction
BeforeSave
BeforeUpdate
// save before associations
// update timestamp `UpdatedAt`
// save self
// save after associations
AfterUpdate
AfterSave
// commit or rollback transaction
```

Ejemplo de Código:

```go
func (u *User) BeforeUpdate() (err error) {
    if u.readonly() {
        err = errors.New("read only user")
    }
    return
}

// Updating data in same transaction
func (u *User) AfterUpdate(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("verfied", true)
  }
    return
}
```

### Eliminando un objeto

Hooks disponibles para eliminar

```go
// begin transaction
BeforeDelete
// delete self
AfterDelete
// commit or rollback transaction
```

Ejemplo de Código:

```go
// Actualización de datos en la misma transacción
func (u *User) AfterDelete(tx *gorm.DB) (err error) {
  if u.Confirmed {
    tx.Model(&Address{}).Where("user_id = ?", u.ID).Update("invalid", false)
  }
    return
}
```

### Consultando un objeto

Hooks disponibles para consultar

```go
// load data from database
// Preloading (edger loading)
AfterFind
```

Ejemplo de Código:

```go
func (u *User) AfterFind() (err error) {
  if u.MemberShip == "" {
    u.MemberShip = "user"
  }
    return
}
```