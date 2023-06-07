---
title: Associações
layout: page
---

## Criar/Atualizar Automaticamente

GORM salvará associações automaticamente e sua referência usando [Upsert](create.html#upsert) quando criar ou atualizar um registro.

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

Se você quiser atualizar os dados das associações, você deve usar o modo `FullSaveAssociations`:

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## Evitar Criação/Atualização Automática

Para evitar o salvamento automático ao criar/atualizar, você pode usar `Select` ou `Omit`, por exemplo:

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
// Não cria BillingAddress quando cria um usuário

db.Omit(clause.Associations).Create(&user)
// Não cria todas associações quando cria um usuário
```

{% note warn %}
**OBSERVE:** Para relacionamentos muitos-para-muitos, GORM irá criar/atualizar automaticamente as associações antes de criar as referências da tabela de junção, se você quiser pular a criação/atualização automática das associações, poderia pular assim:

```go
db.Omit("Languages.*").Create(&user)
```

O código a seguir pulará a criação da associação e suas referências

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## Selecionar/Omitir campos de Associação

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// Cria o usuário e seu BillingAddress, ShippingAddress
// Quando criar o  BillingAddress usa apenas os campos address1, address2 e omite os outros
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## Modo de Associação

O modo de associação contém alguns métodos de ajuda comumente usados para lidar com relacionamento

```go
// Inicia o modo de associação
var user User
db.Model(&user).Association("Languages")
// `user` é o model de origem, ele deve conter uma chave primária
// `Languages` é o nome do campo de um relacionamento
// Se os requisitos acima forem atendidos, o modo de associação deve ser iniciado, caso contrário um erro é retornado
db.Model(&user).Association("Languages").Error
```

### Consultar associações

Encontrar associações correspondentes

```go
db.Model(&user).Association("Languages").Find(&languages)
```

Encontrar associações com as condições

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### Acrescentar associações

Acrescentar novas associações para `many to many`, `has many`, substituir a associação atual para `has one`, `belongs to`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
```

### Substituir associações

Substituir associações atuais por novas

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Excluir associações

Remova a relação entre a origem & argumentos se existir, exclua apenas a referência, não excluirá esses objetos do banco de dados.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Limpar associações

Remover toda referência entre a origem & associação, não excluirá as associações

```go
db.Model(&user).Association("Languages").Clear()
```

### Contar associações

Retornar o total de associações atuais

```go
db.Model(&user).Association("Languages").Count()

// Contar as associações baseadas nas condições
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Lote de dados

Modo de associação suporta dados em lote, por exemplo:

```go
// Consultar todas roles de todos usuários
db.Model(&users).Association("Role").Find(&roles)

// Excluir o usuário A de todos Teams
db.Model(&users).Association("Team").Delete(&userA)

// Consulta o total de usuários únicos de todos os Team
db.Model(&users).Association("Team").Count()

// Para fazesr `Append`, `Replace` com lote de dados, a quantidade de argumentos precisa ser igual a quantidade de dados ou será retornado um erro
var users = []User{user1, user2, user3}
// e.g: nós temos 3 usuários acrescente o userA ao time user1, userB ao user2, userA, userB e userC ao user3
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Redefina o time user1 com o userA，redefina o time user2 com o userB, o time user3 com o userA, userB e userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_association_record">Delete Association Record</span>

By default, `Replace`/`Delete`/`Clear` in `gorm.Association` only delete the reference, that is, set old associations's foreign key to null.

You can delete those objects with `Unscoped` (it has nothing to do with `ManyToMany`).

How to delete is decided by `gorm.DB`.

```go
// Soft delete
// UPDATE `languages` SET `deleted_at`= ...
db.Model(&user).Association("Languages").Unscoped().Clear()

// Delete permanently
// DELETE FROM `languages` WHERE ...
db.Unscoped().Model(&item).Association("Languages").Unscoped().Clear()
```

## <span id="delete_with_select">Delete with Select</span>

You are allowed to delete selected has one/has many/many2many relations with `Select` when deleting records, for example:

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
**NOTE:** Associations will only be deleted if the deleting records's primary key is not zero, GORM will use those primary keys as conditions to delete selected associations

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

## <span id="tags">Association Tags</span>

| Tag              | Descrição                                                                                                      |
| ---------------- | -------------------------------------------------------------------------------------------------------------- |
| foreignKey       | Especifica o nome da coluna do model atual que é usado como uma chave estrangeira para a tabela de junção      |
| references       | Especifica o nome da coluna da tabela de referência que é mapeada para a chave estrangeira da tabela de junção |
| polymorphic      | Especifica o tipo polimórfico como o nome do model                                                             |
| polymorphicValue | Especifica o valor polimórfico, nome da tabela padrão                                                          |
| many2many        | Especifica nome da tabela de junção                                                                            |
| joinForeignKey   | Especifica o nome da coluna que é chave estrangeira na tabela de junção que será mapeada para a tabela atual   |
| joinReferences   | Especifica o nome da coluna estrangeira da tabela de junção que mapeia para a tabela de referência             |
| constraint       | Restrição do relacionamento, ex.: `OnUpdate`,`OnDelete`                                                        |