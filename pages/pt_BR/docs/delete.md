---
title: Excluir
layout: page
---

## Apagar um registro

Quando for remover um registro, o valor a ser removido precisa ter uma chave primária ou ele vai disparar uma [Remoção em lote](#batch_delete), por exemplo:

```go
// O ID do Email é `10`
db.Delete(&email)
// DELETE from emails where id = 10;

// Remover registro com condições adicionais
db.Where("name = ?", "jinzhu").Delete(&email)
// DELETE from emails where id = 10 AND name = "jinzhu";
```

## Remover usando uma chave primária

GORM permite a remoção de objetos usando chave primária com uma condição "inline", funciona com números, acesse: [Query Inline Conditions](query.html#inline_conditions) para mais detalhes

```go
db.Delete(&User{}, 10)
// DELETE FROM users WHERE id = 10;

db.Delete(&User{}, "10")
// DELETE FROM users WHERE id = 10;

db.Delete(&users, []int{1,2,3})
// DELETE FROM users WHERE id IN (1,2,3);
```

## Delete Hooks

GORM permite os seguintes hooks `BeforeDelete`, `AfterDelete`, estes métodos vão ser chamados quando um registro estiver sendo removido, confira [Hooks](hooks.html) para mais detalhes

```go
func (u *User) BeforeDelete(tx *gorm.DB) (err error) {
    if u.Role == "admin" {
        return errors.New("admin user not allowed to delete")
    }
    return
}
```

## <span id="batch_delete">Batch Delete</span>

Se o valor especificado não estiver dentro uma chave primária, GORM vai executar uma remoção em massa, ele vai remover todos os registros que satisfaçam a condição

```go
db.Where("email LIKE ?", "%jinzhu%").Delete(&Email{})
// DELETE from emails where email LIKE "%jinzhu%";

db.Delete(&Email{}, "email LIKE ?", "%jinzhu%")
// DELETE from emails where email LIKE "%jinzhu%";
```

Para uma remoção eficiente de um grande número de registros, passe um slice de chaves primárias para o método  `Delete`

```go
var users = []User{{ID: 1}, {ID: 2}, {ID: 3}}
db.Delete(&users)
// DELETE FROM users WHERE id IN (1,2,3);

db.Delete(&users, "name LIKE ?", "%jinzhu%")
// DELETE FROM users WHERE name LIKE "%jinzhu%" AND id IN (1,2,3); 
```

### Bloqueio de remoções globais

Se você tentar executar uma remoção em massa sem nenhuma condição, GORMO NÃO vai executar a instrução, e irá retornar o erro `ErrMissingWhereClause`

Você precisa inserir alguma condição, usar uma instrução SQL nativa ou habilitar o modo `AllowGlobalUpdate`, por exemplo:

```go
db.Delete(&User{}).Error // gorm.ErrMissingWhereClause

db.Delete(&[]User{{Name: "jinzhu1"}, {Name: "jinzhu2"}}).Error // gorm.ErrMissingWhereClause

db.Where("1 = 1").Delete(&User{})
// DELETE FROM `users` WHERE 1=1

db.Exec("DELETE FROM users")
// DELETE FROM users

db.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&User{})
// DELETE FROM users
```

### Retornando dados de registros excluídos

O retorno do dado removido, somente funciona para bancos de dados que suportam "returning", por exemplo:

```go
// return all columns
var users []User
DB.Clauses(clause.Returning{}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING *
// users => []User{{ID: 1, Name: "jinzhu", Role: "admin", Salary: 100}, {ID: 2, Name: "jinzhu.2", Role: "admin", Salary: 1000}}

// return specified columns
DB.Clauses(clause.Returning{Columns: []clause.Column{{Name: "name"}, {Name: "salary"}}}).Where("role = ?", "admin").Delete(&users)
// DELETE FROM `users` WHERE role = "admin" RETURNING `name`, `salary`
// users => []User{{ID: 0, Name: "jinzhu", Role: "", Salary: 100}, {ID: 0, Name: "jinzhu.2", Role: "", Salary: 1000}}
```

## Soft Delete

Se o seu modelo inclui o campo `gorm.DeletedAt`, (que está em `gorm.Model`), ele irá trabalhar com "soft delete" automaticamente!

Quando o método `Delete` for executado, o registro NÃO será removido do banco de dados, GORM irá definir o valor do campo `DeletedAt` com a data e hora atuais, dessa forma, o registro não poderá mais ser encontrado por nenhum método de query.

```go
// user's ID is `111`
db.Delete(&user)
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE id = 111;

// Batch Delete
db.Where("age = ?", 20).Delete(&User{})
// UPDATE users SET deleted_at="2013-10-29 10:23" WHERE age = 20;

// Soft deleted records will be ignored when querying
db.Where("age = 20").Find(&user)
// SELECT * FROM users WHERE age = 20 AND deleted_at IS NULL;
```

Se você não incluir `gorm.Model`, você pode habilitar o mecanismo da "soft delete" da seguinte forma:

```go
type User struct {
  ID      int
  Deleted gorm.DeletedAt
  Name    string
}
```

### Buscando registros que sofreram um soft delete

Você pode procurar por registros que sofreram "soft delete" com `Unscoped`

```go
db.Unscoped().Where("age = 20").Find(&users)
// SELECT * FROM users WHERE age = 20;
```

### Remoção permanente

Você pode remover registros permanentemente com `Unscoped`

```go
db.Unscoped().Delete(&order)
// DELETE FROM orders WHERE id=10;
```

### Delete Flag

Por padrão, `gorm.Model` utiliza `*time.Time` como valor para o campo `DeletedAt`, mas o GORM fornece outros tipos de dados com o plugin `gorm.io/plugin/soft_delete`

{% note warn %}
**INFO** quando estiver criando um índice composto para o campo DeletedAt, você precisa utilizar outro formato de dado como unix second/flag com o plugin `gorm.io/plugin/soft_delete` exemplo:

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string                `gorm:"uniqueIndex:udx_name"`
  DeletedAt soft_delete.DeletedAt `gorm:"uniqueIndex:udx_name"`
}
```
{% endnote %}

#### Segundos no formato unix

Utilize segundos no formato unix como uma flag de remoção

```go
import "gorm.io/plugin/soft_delete"

type User struct {
  ID        uint
  Name      string
  DeletedAt soft_delete.DeletedAt
}

// Query
SELECT * FROM users WHERE deleted_at = 0;

// Delete
UPDATE users SET deleted_at = /* current unix second */ WHERE ID = 1;
```

Você também pode especificar o uso de `milli` ou `nano` segundos como valor, por exemplo:

```go
type User struct {
  ID    uint
  Name  string
  DeletedAt soft_delete.DeletedAt `gorm:"softDelete:milli"`
  // DeletedAt soft_delete.DeletedAt `gorm:"softDelete:nano"`
}

// Query
SELECT * FROM users WHERE deleted_at = 0;

// Delete
UPDATE users SET deleted_at = /* current unix milli second or nano second */ WHERE ID = 1;
```

#### Utilize `1` / `0` como Delete Flag

```go

type User struct {
  ID    uint
  Name  string
  IsDel soft_delete.DeletedAt `gorm:"softDelete:flag"`
}

// Query
SELECT * FROM users WHERE is_del = 0;

// Delete
UPDATE users SET is_del = 1 WHERE ID = 1;
```

#### Mixed Mode

Mixed mode pode utilizar `0`, `1` ou segundos no formato unix para marcar um registro como removido, e salvar data e hora ao mesmo tempo.

```go
type User struct {
  ID        uint
  Name      string
  DeletedAt time.Time
  IsDel     soft_delete.DeletedAt `gorm:"softDelete:flag,DeletedAtField:DeletedAt"` // use `1` `0`
  // IsDel     soft_delete.DeletedAt `gorm:"softDelete:,DeletedAtField:DeletedAt"` // use `unix second`
  // IsDel     soft_delete.DeletedAt `gorm:"softDelete:nano,DeletedAtField:DeletedAt"` // use `unix nano second`
}

// Query
SELECT * FROM users WHERE is_del = 0;

// Delete
UPDATE users SET is_del = 1, deleted_at = /* current unix second */ WHERE ID = 1;
```
