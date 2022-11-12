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
  // 通过配置初始化生成器
  g := gen.NewGenerator(gen.Config{
     OutPath: "../dal", // 输出目录，默认是 ./query
     Mode:    gen.WithDefaultQuery | gen.WithQueryInterface,
     FieldNullable: true,
  })

  // 初始化一个 *gorm.DB 对象
  db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

  // 用上面的`*gorm.DB` 对象初始化generator对象,
  // 通过调用generator的 `GenerateModel/GenerateModelAs`方法可以根据数据库表来生成struct结构体。
  g.UseDB(db)

  // 为指定的struct生成默认的DAO层
  g.ApplyBasic(model.Customer{}, model.CreditCard{}, model.Bank{}, model.Passport{})

  // 为从数据库生成的structs生成DAO层代码
  companyGenerator := g.GenerateModelAs("company", "MyCompany"),
  g.ApplyBasic(
    g.GenerateModel("users"),
    companyGenerator,
    g.GenerateModelAs("people", "Person",
      gen.FieldIgnore("deleted_at"),
      gen.FieldNewTag("age", `json:"-"`),
    ),
  )

  // 执行
  g.Execute()
}
```

运行上述代码会在目录`../dal`中生成相应的DAO层代码，你可以在你的程序中导入`dal`并使用他们来查询数据

## gen.Config

```go
type Config struct {
    OutPath      string // 查询类代码的输出路径
    OutFile      string // 代码输出文件名，默认: gen.go
    ModelPkgPath string // 生成的 model 包名
    WithUnitTest bool   // 是否为生成的查询类代码生成单元测试

    FieldNullable     bool // generate pointer when field is nullable
    FieldCoverable    bool // generate pointer when field has default value, to fix problem zero value cannot be assign: https://gorm.io/docs/create.html#Default-Values
    FieldSignable     bool // detect integer field's unsigned type, adjust generated data type
    FieldWithIndexTag bool // generate with gorm index tag
    FieldWithTypeTag  bool // generate with gorm column type tag

    Mode GenerateMode // generator modes
}
```

### 输出配置项

| 配置           | 说明                         |
| ------------ | -------------------------- |
| OutPath      | 生成的查询类代码的输出路径，默认`./query`  |
| OutFile      | 生成的文件名，默认`gen.go`          |
| ModelPkgPath | 生成DAO代码的包名，默认是：`model`     |
| WithUnitTest | 是否为DAO包生成单元测试代码，默认：`false` |

### 生成结构体的配置项

| 配置                | 说明                                                                                            |
| ----------------- | --------------------------------------------------------------------------------------------- |
| FieldNullable     | 数据库中的字段可为空，则生成struct字段为指针类型                                                                   |
| FieldCoverable    | 如果数据库中字段有默认值，则生成指针类型的字段，以避免零值（zero-value）问题，见：https://gorm.io/docs/create.html#Default-Values |
| FieldSignable     | Use signable type as field's type based on column's data type in database                     |
| FieldWithIndexTag | 为结构体生成`gorm index` tag，如`gorm:"index:idx_name"`，默认：`false`                                    |
| FieldWithTypeTag  | 为结构体生成`gorm type` tag，如：`gorm:"type:varchar(12)"`，默认：`false`                                  |

参考 [数据库到结构](./database_to_structs.html) 更多选项

### 生成器模式

| 标签名                    | 说明                                                                                                                                                                                                 |
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
