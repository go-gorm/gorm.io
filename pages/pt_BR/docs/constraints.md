---
title: Constraints
layout: page
---

GORM permite criar contraints com a tag, restrições serão criadas quando [ executar o AutoMigrate ou CreateTable com GORM](migration.html)

## CHECK Constraint

Crie CHECK constraints com a tag `check`

```go
type UserIndex struct {
    Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
    Name2 string `gorm:"check:name <> 'jinzhu'"`
    Name3 string `gorm:"check:,name <> 'jinzhu'"`
}
```

## Index Constraint

Consulte [Índices de banco de dados](indexes.html)

## Foreign Key Constraint

GORM irá criar constraints de chaves estrangeiras para relacionamentos, você pode desabilitar esse recurso durante a inicialização:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

O GORM permite configurar as constraints da CHAVE ESTRANGEIRA `OnDelete`, `OnUpdate` com a tag `constraint`, por exemplo:

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
