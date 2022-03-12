---
title: Transações
layout: page
---

## Desabilitar a transação padrão

O GORM executa operações de escrita (create/update/delete) dentro de uma transação para garantir a consistência de dados, você pode desativá-la durante a inicialização se não for necessário, você ganhará cerca de 30%+ de melhoria de desempenho depois disso

```go
// Desabilitar globalmente
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})

// Desabilita durante a sessão
tx := db.Session(&Session{SkipDefaultTransaction: true})
tx.First(&user, 1)
tx.Find(&users)
tx.Model(&user).Update("Age", 18)
```

## Transação

Para executar um conjunto de operações dentro de uma transação, o fluxo geral será como o mostrado abaixo.

```go
db.Transaction(func(tx *gorm.DB) error {
  // do some database operations in the transaction (use 'tx' from this point, not 'db')
  if err := tx.Create(&Animal{Name: "Giraffe"}).Error; err != nil {
    // return any error will rollback
    return err
  }

  if err := tx.Create(&Animal{Name: "Lion"}).Error; err != nil {
    return err
  }

  // return nil will commit the whole transaction
  return nil
})
```

### Transações aninhadas

O GORM suporta transações aninhadas, você pode reverter um subconjunto de operações realizadas dentro do escopo de uma transação maior, por exemplo:

```go
db.Transaction(func(tx *gorm.DB) error {
  tx.Create(&user1)

  tx.Transaction(func(tx2 *gorm.DB) error {
    tx2.Create(&user2)
    return errors.New("rollback user2") // Rollback user2
  })

  tx.Transaction(func(tx2 *gorm.DB) error {
    tx2.Create(&user3)
    return nil
  })

  return nil
})

// Commit user1, user3
```

## Controle manualmente a transação

O Gorm suporta chamadas diretas às funções de controle da transação  (commit / rollback), por exemplo:

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

### Um Exemplo Específico

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

## SavePoint, RollbackTo

O GORM fornece `SavePoint`, `RollbackPara` para salvar pontos e voltar a um ponto de salvamento, por exemplo:

```go
tx := db.Begin()
tx.Create(&user1)

tx.SavePoint("sp1")
tx.Create(&user2)
tx.RollbackTo("sp1") // Rollback user2

tx.Commit() // Commit user1
```
