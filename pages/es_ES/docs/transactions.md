---
title: Transacciones
layout: page
---
GORM realiza operaciones `create`, `update`, `delete` simples en transacciones por defecto para asegurar la integridad de la base de datos.

If you want to tread multiple `create`, `update`, `delete` as one atomic operation, `Transaction` is made for that.

## Transacciones

Para realizar una serie de operaciones en una transacción, el flujo general es como el siguiente.

```go
// begin a transaction
tx := db.Begin()

// do some database operations in the transaction (use 'tx' from this point, not 'db')
tx.Create(...)

// ...

// rollback the transaction in case of error
tx.Rollback()

// Or commit the transaction
tx.Commit()
```

## Un Ejemplo Específico

```go
func CreateAnimals(db *gorm.DB) error {
  // Note the use of tx as the database handle once you are within a transaction
  tx := db.Begin()
  defer func() {
    if r := recover(); r != nil {
      tx.Rollback()
    }
  }()

  if err := tx.Error; err != nil {
    return err
  }

  if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
     tx.Rollback()
     return err
  }

  return tx.Commit().Error
}
```