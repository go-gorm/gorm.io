---
title: DAO层概览
layout: 页面
---

Gen遵循`配置即代码`的实践原则来生成DAO层代码，下面是「配置」讲解

## 配置

你的配置文件需要被撰写成一个可运行的golang程序，通常来说，配置文件应该放在你程序中的一个子目录中。

```go
// configuration.go
package main

import (
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
)

func main() {
  // Initialize the generator with configuration
  g := gen.NewGenerator(gen.Config{
     OutPath: "../dal", // output directory, default value is ./query
     Mode:    gen.WithDefaultQuery | gen.WithQueryInterface,
     FieldNullable: true,
  })

  // Initialize a *gorm.DB instance
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

  // Use the above `*gorm.DB` instance to initialize the generator,
  // which is required to generate structs from db when using `GenerateModel/GenerateModelAs`
  g.UseDB(db)

  // Generate default DAO interface for those specified structs
  g.ApplyBasic(model.Customer{}, model.CreditCard{}, model.Bank{}, model.Passport{})

  // Generate default DAO interface for those generated structs from database
  companyGenerator := g.GenerateModelAs("company", "MyCompany"),
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
}
```

### Output Options

| Option Name  | Description                                                           |
| ------------ | --------------------------------------------------------------------- |
| OutPath      | Output destination folder for the generator, default value: `./query` |
| OutFile      | Query code file name, default value: `gen.go`                         |
| ModelPkgPath | Generated DAO package's package name, default value: `model`          |
| WithUnitTest | Generate unit tests for the DAO package, default value: `false`       |

### Generate Struct Options

| Option Name       | Description                                                                                                                                                                                                                |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| FieldNullable     | Generate pointer as field's type if column is nullable in database                                                                                                                                                         |
| FieldCoverable    | Generate pointer as field's type if column has default value in database, to avoid zero-value issue, e.g: https://gorm.io/docs/create.html#Default-Values                                                                  |
| FieldSignable     | Use signable type as field's type based on column's data type in database                                                                                                                                                  |
| FieldWithIndexTag | Generate with `gorm index` tag                                                                                                                            | , for example: `gorm:"index:idx_name"`, default value: `false` |
| FieldWithTypeTag  | Generate with `gorm type` tag, for example: `gorm:"type:varchar(12)"`, default value: `false`                                                                                                                              |

Refer [Database To Structs](./database_to_structs.html) for more options

### Generator Modes

| Tag Name               | Description                                                                                                                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| gen.WithDefaultQuery   | Generate global variable `Q` as DAO interface, then you can query data like: `dal.Q.User.First()`                                                                                                  |
| gen.WithQueryInterface | Generate query api interface instead of struct, usually used for mock testing                                                                                                                      |
| gen.WithoutContext     | Generate code without context constrain, then you can query data without passing context like: `dal.User.First()`, or you have to query with the context, e.g: `dal.User.WithContext(ctx).First()` |


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

  ReadDB() IUserDo
  WriteDB() IUserDo
}
```

## Usage Example

* Use the global variable `Q` if `gen.WithDefaultQuery` is enabled

```go
import "your_project/dal"

func main() {
  // Initialize a *gorm.DB instance
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

  dal.SetDefault(db)

  // query the first user
  user, err := dal.Q.User.First()
}
```

* Initialize DAO query interface

```go
import "your_project/dal"

var Q dal.Query

func main() {
  // Initialize a *gorm.DB instance
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

  Q = dal.Use(db)

  // query the first user
  user, err := Q.User.First()
}
```

For more usage details, please checkout

* [Create](./create.html)
* [Update](./update.html)
* [Query](./query.html)
* [Delete](./delete.html)
* [Associations](./associations.html)
* [Transaction](./transaction.html)
