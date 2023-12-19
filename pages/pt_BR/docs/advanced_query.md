---
title: Consulta Avançada
layout: page
---

## <span id="smart_select">Seleção Inteligente de Campos</span>

GORM permite selecionar campos específicos com [`Select`](query.html), se você frequentemente usa isso em seu aplicativo, talvez você queira definir uma estrutura menor para uso da API, que pode selecionar campos específicos automaticamente, por exemplo:

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // milhares de campos
}

type APIUser struct {
  ID   uint
  Name string
}

// Seleciona automaticamente o `id`, `name`
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

{% note warn %}
**NOTA:** o modo `QueryFields` irá selecionar todos os campos do modelo
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  QueryFields: true,
})

db.Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users` // com esta opção

// Session Mode
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users`
```

## Locking

O GORM suporta diferente tipos de bloqueio, por exemplo:

```go
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE
```
The above statement will lock the selected rows for the duration of the transaction. This can be used in scenarios where you are preparing to update the rows and want to prevent other transactions from modifying them until your transaction is complete.

The `Strength` can be also set to `SHARE` which locks the rows in a way that allows other transactions to read the locked rows but not to update or delete them.
```go
db.Clauses(clause.Locking{
  Strength: "SHARE",
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`
```
The `Table` option can be used to specify the table to lock. This is useful when you are joining multiple tables and want to lock only one of them.
```go
db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`
```
Options can be provided like `NOWAIT` which  tries to acquire a lock and fails immediately with an error if the lock is not available. It prevents the transaction from waiting for other transactions to release their locks.
```go
db.Clauses(clause.Locking{
  Strength: "UPDATE",
  Options: "NOWAIT",
}).Find(&users)
// SELECT * FROM `users` FOR UPDATE NOWAIT
```
Another option can be `SKIP LOCKED` which skips over any rows that are already locked by other transactions. This is useful in high concurrency situations where you want to process rows that are not currently locked by other transactions.

## Subconsultas

Uma subconsulta pode ser aninhada dentro de outra consulta, o GORM pode gerar uma subconsulta quando se usa o objeto `*gorm.DB` como parâmetro

```go
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">Consulta a partir de uma subconsulta</span>

O GORM permite que você use uma subconsulta na cláusula FROM com o método `Table`, por exemplo:

```go
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Condições de agrupamento</span>

Mais fácil de escrever uma complicada consulta SQL com condições de agrupamento

```go
db.Where(
    db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## IN com múltiplas colunas

Consulta usando IN com múltimas colunas

```go
db.Where("(name, age, role) IN ?", [][]interface{}{{"jinzhu", 18, "admin"}, {"jinzhu2", 19, "user"}}).Find(&users)
// SELECT * FROM users WHERE (name, age, role) IN (("jinzhu", 18, "admin"), ("jinzhu 2", 19, "user"));
```

## Argumento Nomeado

O GORM suporta argumentos nomeados com [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) ou `map[string]interface{}{}`, por exemplo:

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

Consulte [Raw SQL e SQL Builder](sql_builder.html#named_argument) para mais detalhes

## Mapear resultado de consulta

O GORM mapear o resultado de uma consulta para `map[string]interface{}` ou `[]map[string]interface{}`, não esqueça de definir o `Model` ou `Table`, por exemplo:

```go
result := map[string]interface{}{}
db.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
db.Table("users").Find(&results)
```

## FirstOrInit

Obtenha o primeiro registro correspondente ou inicialize uma nova instância com determinadas condições (funciona apenas com struct ou com condições usando map)

```go
// Usuário não encontrado, inicialize o objeto com os seguintes dados
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"}

// Pesquisa um usuário com `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}

// Usuário encontrado com `name` = `jinzhu`
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

Inicializar struct com mais atributos se o registro não for encontrado, os `Attrs` não serão usados para criar uma consulta SQL

```go
// Usuário não encontrado, inicialize o objeto com os dados
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Usuário não encontrado, inicialize o objeto com os dados
db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Usuário encontrado com `name` = `jinzhu`, os atributos serão ignorados
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

`Assign` atribue a struct independente se o registro foi localizado ou não, esses atributos não serão usados para criar uma consulta SQL e os dados finais não serão gravados no banco de dados

```go
// Usuário não encontrado, inicialize o objeto com os dados e preencha os atributos
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20}

// Usuário encontrado com `name` = `jinzhu`, altere o objeto preenchendo os atributos
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## FirstOrCreate

Seja o primeiro registro correspondente ou crie um novo com determinadas condições (só funciona com estrutura, condições de mapa), `RowsAffected` retornou contagem de registros criados/atualizados

```go
// Usuário não encontrado, crie um novo registro com os dados
result := db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}
// result.RowsAffected // => 1

// Usuário encontrado com `name` = `jinzhu`
result := db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age": 18}
// result.RowsAffected // => 0
```

Cria struct com mais atributos se o registro não for localizado, esses `Attrs` não serão usados para construir uma consulta SQL

```go
// Usuário não encontrado, crie um novo registro com os dados
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Usuário encontrado com `name` = `jinzhu`, os atributos serão ignorados
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

`Assign` atribue ao registro independente se for encontrado ou não e grava de volta no banco de dados.

```go
// Usuário não encontrado, inicialize o objeto com os dados e preencha os atributos
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Usuário encontrado com `name` = `jinzhu`, altere o objeto com os atributos
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "jinzhu", Age: 20}
```

## Sugestões de Otimizer/Índice

Dicas de otimização permitem controlar o otimizador de consultas para escolher um determinado plano de execução de consultas, GORM suporta-o com `gorm.io/hints`, por exemplo:

```go
import "gorm.io/hints"

db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Dicas de índice permitem a aprovação de dicas de índice para o banco de dados caso o planejador de consultas fique confuso.

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```

Consulte [Dicas otimizador/Index/Comentário](hints.html) para obter mais detalhes

## Iteração

GORM suporta iteração através de Linhas

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Rows()
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows é um método do `gorm.DB`, ele pode ser usado para mapear o resultado para uma struct
  db.ScanRows(rows, &user)

  // faça alguma coisa
}
```

## FindInBatches

Consultar e processar registros em lote

```go
// lote com tamanho 100
result := db.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // processando os registros encontrados em lotes
  }

  tx.Save(&results)

  tx.RowsAffected // número de registros no lote

  batch // Lote 1, 2, 3

  // se retornar algum erro os próximos lotes são interrompidos
  return nil
})

result.Error // erro retornado
result.RowsAffected // total de registros processados em todos lotes
```

## Hooks de consulta

GORM permite que hooks `AfterFind` para uma consulta, será chamado quando consultar um registro, consulte [Hooks](hooks.html) para obter detalhes

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.Role == "" {
    u.Role = "user"
  }
  return
}
```

## <span id="pluck">Pluck</span>

Consultar uma coluna única do banco de dados e mapear em um slice, se você quiser consultar múltiplas colunas, use `Select` com [`Scan`](query.html#scan) em vez disso

```go
var ages []int64
db.Model(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Distinct Pluck
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Precisa de mais de uma coluna, use `Scan` ou `Find` como abaixo:
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```

## Escopos

`Scopes` permite que você especifique consultas comumente usadas que podem ser referenciadas como chamadas de método

```go
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
  return db.Where("amount > ?", 1000)
}

func PaidWithCreditCard(db *gorm. B) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func PaidWithCod(db *gorm. B) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func OrderStatus(status []string) func (db *gorm. B) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    return db. aqui("status IN (?)", status)
  }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard). ind(&orders
// Encontrar todas as ordens de cartão de crédito e valor maior que 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod). ind(&orders)
// Encontrar todas as ordens de COD e quantidade superior a 1000

db. copes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Encontrar todas as ordens pagas e enviadas com valor superior a 1000
```

Confira [Scopes](scopes.html) para detalhes

## <span id="count">Count</span>

Obter quantidade de registros correspondentes

```go
var count int64
db.Model(&User{}).Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu'; (count)

db.Table("deleted_users").Count(&count)
// SELECT count(1) FROM deleted_users;

// Count com Distinct
db.Model(&User{}).Distinct("name").Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db.Table("deleted_users").Select("count(distinct(name))").Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Count with Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

db.Model(&User{}).Group("name").Count(&count)
count // => 3
```
