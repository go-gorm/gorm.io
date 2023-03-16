---
title: Consulta avanzada
layout: página
---

## <span id="smart_select">Campos de selección inteligentes</span>

GORM permite seleccionar campos específicos con [`Select`](query.html), si usas esto a menudo en tu aplicación, tal vez quieras definir una estructura más pequeña para el uso del API que pueda seleccionar automáticamente campos específicos, por ejemplo:

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // cientos de campos
}

type APIUser struct {
  ID   uint
  Name string
}

// Select `id`, `name` automáticamente cuando consulta
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

{% note warn %}
**NOTA:** En el modo `QueryFields`, se seleccionarán automáticamente todos los campos del modelo actual por su nombre
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  QueryFields: true,
})

db.Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users` // con esta opción

// Modo de sesión
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users`
```

## Bloqueo (Para Actualizaciones)

GORM soporta diferentes tipos de bloqueos, por ejemplo:

```go
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

db. lauses(clause.Locking{
  Fuerza: "SHARE",
  Tabla: cláusula.Table{Name: clause.CurrentTable},
}). ind(&users)
// SELECT * FROM `users` FOR SHARE OF `users`

db.Clauses(clause. ocking{
  Strength: "UPDATE",
  Options: "NOWAIT",
}).Find(&users)
// SELECT * FROM `users` FOR UPDATE NOWAIT
```

Consulte [Raw SQL y SQL Builder](sql_builder.html) para más detalles

## Subconsultas

Una subconsulta puede ser anidada dentro de una consulta, GORM puede generar subconsulta al usar un objeto `*gorm.DB` como parámetro

```go
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")). ind(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%"). able("usuarios")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery). ind(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` TIENE AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">Desde Subconsulta</span>

GORM permite usar subconsultas en la cláusula FROM con el método `Table`, por ejemplo:

```go
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Condiciones de grupo</span>

Fácil de escribir una consulta SQL complicada con las condiciones de grupo

```go
db.Where(
    db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small"). r("size = ?", "medium")),
).Or(
    db.Where("pizza = ?", "hawaiian"). aquí("size = ?", "xlarge"),
).Find(&Pizza{}). tatement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## IN con múltiples columnas

Seleccionando IN con múltiples columnas

```go
db.Where("(name, age, role) IN ?", [][]interface{}{{"jinzhu", 18, "admin"}, {"jinzhu2", 19, "user"}}).Find(&users)
// SELECT * FROM users WHERE (name, age, role) IN (("jinzhu", 18, "admin"), ("jinzhu 2", 19, "user"));
```

## Argumentos nombrados

GORM soporta argumentos nombrados con [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) o `map[string]interface{}{}`, por ejemplo:

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

Consulta [Raw SQL and SQL Builder](sql_builder.html#named_argument) para más detalles

## Buscar en Mapa

GORM permite escanear resultados a `map[string]interface{}` o `[]map[string]interface{}`, no olvide especificar el `Modelo` o `Tabla`, por ejemplo:

```go
result := map[string]interface{}{}
db.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
db.Table("users").Find(&results)
```

## FirstOrInit

Obtener el primer registro coincidente o inicializar una nueva instancia con determinadas condiciones (sólo funciona con la estructura o condiciones del mapa)

```go
// User not found, initialize it with give conditions
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"}

// Found user with `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}

// Found user with `name` = `jinzhu`
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

Inicializar estructura con más atributos si no se encuentra el registro, esos `Attrs` no se utilizarán para construir la consulta SQL

```go
// Usuario no encontrado, inicializar con condiciones y Attrs
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Usuario no encontrado, inicializar con condiciones y Attrs
db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Usuario encontrado con `name` = `jinzhu`, los atributos serán ignorados
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

`Assign` atributos al struct independientemente de que se encuentre o no, esos atributos no se utilizarán para construir una consulta SQL y los datos finales no se guardarán en la base de datos

```go
// Usuario no encontrado, inicialízalo con condiciones y Asigne atributos
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20}

// Usuario encontrado con `name` = `jinzhu`, actualízalo con Asignar atributos
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## FirstOrCreate

Obtenga el primer registro coincidente o cree uno nuevo con las condiciones dadas (solo funciona con struct, las condiciones del mapa), `RowsAfected` devuelve el conteo de registros creado/actualizado

```go
// Usuario no encontrado, crea un nuevo registro con condiciones
result := db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}
// result.RowsAffected // => 1

// Usuario encontrado con `name` = `jinzhu`
result := db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age": 18}
// result.RowsAffected // => 0
```

Inicializar struct con más atributos si no se encuentra el registro, esos `Attrs` no se utilizarán para construir la consulta SQL

```go
// Usuario no encontrado, inicializar con condiciones y Attrs
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Usuario encontrado con `name` = `jinzhu`, los atributos serán ignorados
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

`Assign` atributos al registro independientemente de que se encuentre o no y guardarlos de vuelta a la base de datos.

```go
// Usuario no encontrado, inicializar con condiones y con atributo Assign 
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Usuario encontrado con `name` = `jinzhu`, actualiza con atributos Assing
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "jinzhu", Age: 20}
```

## Optimización/Index Hints

Los hints de optimización permiten controlar el optimizador de consultas para elegir un determinado plan de ejecución, GORM lo soporta con `gorm.io/hints`, ej:

```go
import "gorm.io/hints"

db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Los hints de índices permiten pasar hints de índice a la base de datos en caso de que el planificador de consultas se confunda.

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```

Consulte [Pistas/Index/Comentario optimizador](hints.html) para más detalles

## Iteración

GORM soporta iteración a través de las filas

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Rows()
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows is a method of `gorm.DB`, it can be used to scan a row into a struct
  db.ScanRows(rows, &user)

  // do something
}
```

## Búsqueda por Lotes

Consultar y procesar registros en lote

```go
// lote de 100
result := db.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // procesamiento por lotes de registros encontrados
  }

  tx.Save(&results)

  tx.RowsAffected // numero de registros en este lote

  batch // Lote 1, 2, 3

  // retorna error y detendrá futuros lotes 
  return nil
})

result.Error // error retornado
result.RowsAffected // conteo de todos los registros en el lote
```

## Consultas Hooks

GORM permite hooks `AfterFind` para una consulta, se llamará al consultar un registro, consulte [Hooks](hooks.html) para más detalles

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.Role == "" {
    u.Role = "user"
  }
  return
}
```

## <span id="pluck">Pluck</span>

Consulta una sola columna de la base de datos y escanear en un slice, si desea consultar múltiples columnas, usa `Select` con [`Scan`](query.html#scan) en su lugar

```go
var ages []int64
db.Model(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Distinct Pluck
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Solicita más de una columna, use `Scan` or `Find` así:
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```

## Ámbitos

`Scopes` le permite especificar consultas usadas comúnmente que pueden ser referenciadas como llamadas a métodos

```go
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
  return db.Where("amount > ?", 1000)
}

func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func PaidWithCod(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func OrderStatus(status []string) func (db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    return db.Where("status IN (?)", status)
  }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Find all credit card orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Find all COD orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Find all paid, shipped orders that amount greater than 1000
```

Checkout [Scopes](scopes.html) for details

## <span id="count">Count</span>

Get matched records count

```go
var count int64
db.Model(&User{}).Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
// SELECT count(1) FROM users WHERE name = 'jinzhu'; (count)

db.Table("deleted_users").Count(&count)
// SELECT count(1) FROM deleted_users;

// Count with Distinct
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
