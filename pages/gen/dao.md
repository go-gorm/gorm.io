---
title: DAO Overview
layout: page
---

Gen follows the `Configuration As Code` practice to generate the DAO interface, here is the introduction to the configuration.

## Configuration

You need to write the configuration as a runnable golang program, usually, the program will be organized in a sub-directory of your application.

```go
// configuration.go — skeleton: adjust the model import and DSN for your project
package main

import (
  "gorm.io/driver/sqlite"
  "gorm.io/gen"
  "gorm.io/gorm"

  "your_project/model" // your existing model package
)

func main() {
  // Initialize the generator with configuration
  g := gen.NewGenerator(gen.Config{
     OutPath: "../dal", // output directory for the query code (see Output Options below)
     // Mode:    gen.WithDefaultQuery | gen.WithQueryInterface,
     Mode:    gen.WithDefaultQuery | gen.WithGeneric,
     FieldNullable: true,
  })

  // Initialize a *gorm.DB instance
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic(err)
  }

  // Use the above `*gorm.DB` instance to initialize the generator,
  // which is required to generate structs from db when using `GenerateModel/GenerateModelAs`
  g.UseDB(db)

  // Generate default DAO interface for those specified structs
  g.ApplyBasic(model.Customer{}, model.CreditCard{}, model.Bank{}, model.Passport{})

  // Generate default DAO interface for those generated structs from database
  companyGenerator := g.GenerateModelAs("company", "MyCompany")
  g.ApplyBasic(
    g.GenerateModel("users"),
    companyGenerator,
    g.GenerateModelAs("people", "Person",
      gen.FieldIgnore("deleted_at"),
      gen.FieldNewTag("age", `json:"-"`),
    ),
  )

  // Execute the generator
  g.Execute()
}
```

Run the above program, it will generate codes into directory `../dal`, you can import the `dal` package in your application and use its interface to query data

## gen.Config

```go
type Config struct {
	OutPath      string // query code path
	OutFile      string // query code file name, default: gen.go
	ModelPkgPath string // generated model code's package name
	WithUnitTest bool   // generate unit test for query code

	FieldNullable     bool // generate pointer when field is nullable
	FieldCoverable    bool // generate pointer when field has default value, to fix problem zero value cannot be assign: https://gorm.io/docs/create.html#Default-Values
	FieldSignable     bool // detect integer field's unsigned type, adjust generated data type
	FieldWithIndexTag bool // generate with gorm index tag
	FieldWithTypeTag  bool // generate with gorm column type tag

	Mode GenerateMode // generator modes

	// If true, keep the unchanged generated files between runs (v0.3.28+):
	// the generator records a hash manifest (.genmanifest.json) and skips
	// rewriting files whose content did not change.
	Incremental bool
	// If true, generate a subset of tables while keeping previously generated
	// query files (v0.3.28+); errors when the Mode differs between runs.
	MergeQuery bool
	// If true, rewrite `interface{}` to `any` in generated code (v0.3.29+);
	// requires the target module to build with Go >= 1.18.
	UseAny bool
	// If true, generate `default` gorm tag for fields with a database default (v0.3.28+).
	FieldWithDefaultTag bool
	// Custom unit-test template file used when WithUnitTest is on (v0.3.28+).
	UnitTestTemplate string
}
```

### Output Options

| Option Name  | Description                                                           |
| ---          | ---                                                                   |
| OutPath      | Output destination folder for the generated query code. There is no useful default: if left empty, output goes to the current working directory of the generator process, so set it explicitly |
| OutFile      | Query code file name, default value: `gen.go`                         |
| ModelPkgPath | Where generated **model** code goes: a package name (placed next to `OutPath`, default `model`) or a directory path (when it contains a path separator, it is used as the model output dir) |
| WithUnitTest | Generate unit tests for the DAO package, default value: `false`       |

> **NOTE**: `g.Execute()` (i.e. `(*gen.Generator).Execute`) runs the generator
> and **panics** on failure (after printing the error). Use `g.SetLogger(logger)`
> to install a custom logger.

### Generate Struct Options

| Option Name       | Description                                                                                                                                               |
| ---               | ---                                                                                                                                                       |
| FieldNullable     | Generate pointer as field's type if column is nullable in database                                                                                        |
| FieldCoverable    | Generate pointer as field's type if column has default value in database, to avoid zero-value issue, e.g: https://gorm.io/docs/create.html#Default-Values |
| FieldSignable     | Use signable type as field's type based on column's data type in database                                                                                 |
| FieldWithIndexTag | Generate with `gorm index` tag, for example: `gorm:"index:idx_name"`, default value: `false`                                                            |
| FieldWithTypeTag  | Generate with `gorm type` tag, for example: `gorm:"type:varchar(12)"`, default value: `false`                                                             |

Refer [Database To Structs](./database_to_structs.html) for more options

### Generator Modes

| Tag Name               | Description                                                                                                                                                                       |
| ---                    | ---                                                                                                                                                                               |
| gen.WithDefaultQuery   | Generate global variable `Q` as DAO interface, then you can query data like: `dal.Q.User.WithContext(ctx).First()`                                                                                 |
| gen.WithQueryInterface | Generate query api interface instead of struct, usually used for mock testing                                                                                                     |
| gen.WithGeneric | Generate code with generic and interface                                                                                                     |
| gen.WithoutContext     | Generate code without context constrain, then you can query data without passing context like: `dal.User.First()`; without this mode the DAO chain must start with `WithContext`, e.g: `dal.User.WithContext(ctx).First()` |


### DAO Interface

Sample of the generated DAO query interface

```go
type IUserDo interface {
  // Create
  Create(values ...*model.User) error
  CreateInBatches(values []*model.User, batchSize int) error
  Save(values ...*model.User) error

  // Query
  Clauses(conds ...clause.Expression) IUserDo
  As(alias string) gen.Dao
  Columns(cols ...field.Expr) gen.Columns
  Not(conds ...gen.Condition) IUserDo
  Or(conds ...gen.Condition) IUserDo
  Select(conds ...field.Expr) IUserDo
  Where(conds ...gen.Condition) IUserDo
  Order(conds ...field.Expr) IUserDo
  Distinct(cols ...field.Expr) IUserDo
  Omit(cols ...field.Expr) IUserDo
  Join(table schema.Tabler, on ...field.Expr) IUserDo
  LeftJoin(table schema.Tabler, on ...field.Expr) IUserDo
  RightJoin(table schema.Tabler, on ...field.Expr) IUserDo
  Group(cols ...field.Expr) IUserDo
  Having(conds ...gen.Condition) IUserDo
  Limit(limit int) IUserDo
  Offset(offset int) IUserDo
  Scopes(funcs ...func(gen.Dao) gen.Dao) IUserDo
  Unscoped() IUserDo
  Pluck(column field.Expr, dest interface{}) error
  Attrs(attrs ...field.AssignExpr) IUserDo
  Assign(attrs ...field.AssignExpr) IUserDo
  Joins(fields ...field.RelationField) IUserDo
  Preload(fields ...field.RelationField) IUserDo

  Count() (count int64, err error)
  FirstOrInit() (*model.User, error)
  FirstOrCreate() (*model.User, error)
  Returning(value interface{}, columns ...string) IUserDo

  First() (*model.User, error)
  Take() (*model.User, error)
  Last() (*model.User, error)
  Find() ([]*model.User, error)
  FindInBatch(batchSize int, fc func(tx gen.Dao, batch int) error) (results []*model.User, err error)
  FindInBatches(result *[]*model.User, batchSize int, fc func(tx gen.Dao, batch int) error) error
  FindByPage(offset int, limit int) (result []*model.User, count int64, err error)
  ScanByPage(result interface{}, offset int, limit int) (count int64, err error)
  Scan(result interface{}) (err error)

  // Update
  Update(column field.Expr, value interface{}) (info gen.ResultInfo, err error)
  UpdateSimple(columns ...field.AssignExpr) (info gen.ResultInfo, err error)
  Updates(value interface{}) (info gen.ResultInfo, err error)
  UpdateColumn(column field.Expr, value interface{}) (info gen.ResultInfo, err error)
  UpdateColumnSimple(columns ...field.AssignExpr) (info gen.ResultInfo, err error)
  UpdateColumns(value interface{}) (info gen.ResultInfo, err error)
  UpdateFrom(q gen.SubQuery) gen.Dao

  // Delete
  Delete(...*model.User) (info gen.ResultInfo, err error)

  // Common
  Debug() IUserDo
  WithContext(ctx context.Context) IUserDo
  WithResult(fc func(tx gen.Dao)) gen.ResultInfo
  Session(config *gorm.Session) IUserDo
  Rows() (*sql.Rows, error)
  Row() *sql.Row
  UnderlyingDB() *gorm.DB
  ReplaceDB(db *gorm.DB)

  ReadDB() IUserDo
  WriteDB() IUserDo
}
```

### The Generated Query Struct

For each model, the generator emits a query struct with an **unexported** type
(the variable's type is inferred; you never spell it out). You reach it through
the `User` field of the object returned by `query.Use(db)` — or through the
package-level `query.User` variable in `gen.WithDefaultQuery` mode. It carries
one typed field per column, plus a few helpers:

```go
q := query.Use(db)
u := q.User // field of the query struct (type is the unexported query type for User)
// in gen.WithDefaultQuery mode you can also write: u := query.User
// (query.User is a generated package-level *variable*, not a type)

u.ID, u.Name, u.Age // typed fields: field.Int64, field.String, ...
u.ALL               // field.Asterisk — the `users.*` expression

u.TableName()            // "users"
u.Alias()                // current alias, empty unless As() was used
u.Table("users_archive") // re-point this DAO at another table (returns a copy)
u.As("u")                // table alias for joins/self-joins (returns a copy)
u.GetFieldByName("age")  // (field.OrderExpr, bool) — dynamic field lookup for ordering
u.Columns(u.ID, u.Name)  // gen.Columns — tuple expressions, see Tuple Query
```

`Table`/`As` return a **copy** bound to the new name/alias; the original `u` is
unaffected. The query type itself is unexported (constructed by the unexported
`newUser`), so always obtain it from `query.Use(db)` / `query.SetDefault(db)` /
the generated default variables and let Go infer the type. Note that the typed
fields live on the query struct itself — after `u.WithContext(ctx)` you are
holding the `userDo` chain, so keep referencing fields through `u`.

## The Query Object

`query.Use(db)` returns a `*query.Query` that groups one DAO per model and adds
connection-level helpers; `query.SetDefault(db)` initializes the same object
package-globally (it has no return value) and is what backs the generated
package-level variables:

```go
q := query.Use(db, gen.WithClauseChecker(myChecker)) // ...gen.DOOption since v0.3.28

q.Available()      // reports whether the Query currently holds a non-nil *gorm.DB
q.UnderlyingDB()   // the underlying *gorm.DB
q.ReadDB()         // route reads to replicas (gorm.io/plugin/dbresolver)
q.WriteDB()        // force writes to the primary
q.WithContext(ctx) // a context-bound variant of every DAO in q

// ReplaceDB does not modify q — it returns a NEW Query bound to db2:
q2 := q.ReplaceDB(db2)
// the original q and any previously bound package-level aliases
// (query.Q, query.User, ...) still point at the old *gorm.DB
```

Transactions are also started from the query object — see [Transaction](./transaction.html).

With `gen.WithDefaultQuery` the same helpers exist on the package-level `query.Q`
(and the generated package variables `query.User`, `query.Bank`, … are aliases into it).

## Usage Example

The two examples below are application skeletons: add `package main`, replace
`your_project/dal` with the import path of your generated DAO package, and use
your application's DSN. The discarded result (`_ = user`) is illustrative;
consume it in your application after checking the query error.

* Use the global variable `Q` if `gen.WithDefaultQuery` is enabled

```go
import (
  "context"

  "gorm.io/driver/sqlite"
  "gorm.io/gorm"

  "your_project/dal"
)

var ctx = context.Background()

func main() {
  // Initialize a *gorm.DB instance
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic(err)
  }

  dal.SetDefault(db)

  // query the first user
  user, err := dal.Q.User.WithContext(ctx).First()
  if err != nil {
    return
  }
  _ = user
}
```

* Initialize DAO query interface

```go
import (
  "context"

  "gorm.io/driver/sqlite"
  "gorm.io/gorm"

  "your_project/dal"
)

var ctx = context.Background()

var Q *dal.Query

func main() {
  // Initialize a *gorm.DB instance
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
  if err != nil {
    panic(err)
  }

  Q = dal.Use(db)

  // query the first user
  user, err := Q.User.WithContext(ctx).First()
  if err != nil {
    return
  }
  _ = user
}
```

Without `gen.WithDefaultQuery`, `query.User`-style package variables are not
generated — obtain DAOs from `query.Use(db)` instead.

For more usage details, please checkout

* [Create](./create.html)
* [Update](./update.html)
* [Query](./query.html)
* [Delete](./delete.html)
* [Associations](./associations.html)
* [Transaction](./transaction.html)
