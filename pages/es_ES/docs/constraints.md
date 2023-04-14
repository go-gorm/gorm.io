---
title: Restricciones
layout: page
---

GORM permite crear restricciones de base de datos con [tag](https://pkg.go.dev/reflect#StructTag), las restricciones serán creadas al usar [AutoMigrate or CreateTable con GORM](migration.html)

## Restricción CHECK

Crear restricción CHECK con tag `check`

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## Restricción INDEX

Ver [Índices Base de Datos](indexes.html)

## Restricción Llave foránea

GORM creará restricciones de llaves foráneas para asociaciones, usted puede deshabilitar esta característica durante la inicialización:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

GORM permite configurar restricciones de llaves foráneas usando el tag `constraint` con las opciones `OnDelete` o `OnUpdate`, ver ejemplo:

```go
type User struct {
  gorm.Model
  CompanyID  int
  Company    Company    `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
  CreditCard CreditCard `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}

type Company struct {
  ID   int
  Name string
}
```
