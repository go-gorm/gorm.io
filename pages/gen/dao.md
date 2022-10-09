---
title: DAO
layout: page
---

Gen can be used to generate 100% type-safe Data Access API without using `interface{}`

## Generator

```go
// generate code
func main() {
    //init db
    mysql.Init()
    db := mysql.DB(context.Background()).Debug()
    // specify the output directory (default: "./query")
    // ### if you want to query without context constrain, set mode gen.WithoutContext ###
    cfg := gen.Config{
        OutPath: "../../biz/dal",
        Mode:    gen.WithDefaultQuery | gen.WithQueryInterface,
        //Mode:          gen.WithDefaultQuery,
        FieldNullable: true,
    }

	g := gen.NewGenerator(cfg)

	// reuse the database connection in Project or create a connection here
	// if you want to use GenerateModel/GenerateModelAs, UseDB is necessary or it will panic
	g.UseDB(db)

	// apply basic crud api on structs or table models which is specified by table name with function
	// GenerateModel/GenerateModelAs. And generator will generate table models' code when calling Execute.
	// g.ApplyBasic(model.User{}, g.GenerateModel("company"), g.GenerateModelAs("people", "Person", gen.FieldIgnore("address")))
	g.ApplyBasic(
		model.Customer{},
		model.CreditCard{},
		model.Bank{},
		model.Passport{},
		g.GenerateModelAs("user", "JustUser"),
		g.GenerateModel("people"),
		g.GenerateModelAs("address", "Addr",
			gen.FieldIgnore("deleted_at"),
			gen.FieldNewTag("id", `newTag:"tag info"`),
		),
	)
	//g.ApplyBasic(g.GenerateAllTable()...)

	// apply diy interfaces on structs or table models
	g.ApplyInterface(func(method.Method) {}, &model.Company{}, model.User{}, test{}) // struct test will be ignored
	//g.ApplyInterface(func(method method.UserMethod) {}, model.User{})

	// execute the action of code generation
	g.Execute()
}

```

## Generate dao method

methods of user dao as an example

```go

type IUserDo interface {
    gen.SubQuery
    Debug() IUserDo
    WithContext(ctx context.Context) IUserDo
    WithResult(fc func(tx gen.Dao)) gen.ResultInfo
    ReplaceDB(db *gorm.DB)
    ReadDB() IUserDo
    WriteDB() IUserDo
    As(alias string) gen.Dao
    Columns(cols ...field.Expr) gen.Columns
    Clauses(conds ...clause.Expression) IUserDo
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
    Count() (count int64, err error)
    Scopes(funcs ...func(gen.Dao) gen.Dao) IUserDo
    Unscoped() IUserDo
    Create(values ...*model.User) error
    CreateInBatches(values []*model.User, batchSize int) error
    Save(values ...*model.User) error
    First() (*model.User, error)
    Take() (*model.User, error)
    Last() (*model.User, error)
    Find() ([]*model.User, error)
    FindInBatch(batchSize int, fc func(tx gen.Dao, batch int) error) (results []*model.User, err error)
    FindInBatches(result *[]*model.User, batchSize int, fc func(tx gen.Dao, batch int) error) error
    Pluck(column field.Expr, dest interface{}) error
    Delete(...*model.User) (info gen.ResultInfo, err error)
    Update(column field.Expr, value interface{}) (info gen.ResultInfo, err error)
    UpdateSimple(columns ...field.AssignExpr) (info gen.ResultInfo, err error)
    Updates(value interface{}) (info gen.ResultInfo, err error)
    UpdateColumn(column field.Expr, value interface{}) (info gen.ResultInfo, err error)
    UpdateColumnSimple(columns ...field.AssignExpr) (info gen.ResultInfo, err error)
    UpdateColumns(value interface{}) (info gen.ResultInfo, err error)
    UpdateFrom(q gen.SubQuery) gen.Dao
    Attrs(attrs ...field.AssignExpr) IUserDo
    Assign(attrs ...field.AssignExpr) IUserDo
    Joins(fields ...field.RelationField) IUserDo
    Preload(fields ...field.RelationField) IUserDo
    FirstOrInit() (*model.User, error)
    FirstOrCreate() (*model.User, error)
    FindByPage(offset int, limit int) (result []*model.User, count int64, err error)
    ScanByPage(result interface{}, offset int, limit int) (count int64, err error)
    Scan(result interface{}) (err error)
    Returning(value interface{}, columns ...string) IUserDo
    UnderlyingDB() *gorm.DB
    schema.Tabler

    FindByNameAndAge(name string, age int) (result *model.User, err error)
    FindBySimpleName() (result []*model.User, err error)
    FindByIDOrName(cond1 bool, id int, col string, name string) (result *model.User, err error)
    FindAll() (result []map[string]interface{}, err error)
    FindOne() (result map[string]interface{})
    FindAddress() (result *model.User, err error)
}

```

## Init Dao

Initialize global singleton mode.

```go
func init() {
    mysql.Init()
    dal.SetDefault(mysql.DB(context.Background()))
}
```

If `gen.WithDefaultQuery` mode is not used, you can initialize dao like this.

```go
var Q dal.Query

func init() {
    mysql.Init()
    Q = dal.Use(mysql.DB(context.Background()))
}
```

## Use Dao

```go
func Query(ctx context.Context) {
    var err error
    var user *model.User
    var users []*model.User

    u, ud := dal.User, dal.User.WithContext(ctx)

    /*--------------Basic query-------------*/
    user, err = ud.Take()
    //query by write db
    user, err = ud.WriteDB().Take()
    // SELECT * FROM `users` WHERE `users`.`deleted_at` IS NULL LIMIT 1
    util.CatchErr("take 1 item fail", err)
    log.Printf("query 1 item: %+v", user)

    user, err = ud.Where(u.ID.Gt(100), u.Name.Like("%T%")).Take()
    // SELECT * FROM `users` WHERE `users`.`id` > 100 AND `users`.`name` LIKE '%T%' AND `users`.`deleted_at` IS NULL LIMIT 1
    util.CatchErr("query with conditions fail", err)
    log.Printf("query conditions got: %+v", user)

    user, err = ud.Where(ud.Columns(u.ID).In(ud.Select(u.ID.Min()))).First()
    // SELECT * FROM `users` WHERE `users`.`id` IN (SELECT MIN(`users`.`id`) FROM `users` WHERE `users`.`deleted_at` IS NULL) AND `users`.`deleted_at` IS NULL
    // ORDER BY `users`.`id` LIMIT 1
    util.CatchErr("subquery 1 fail", err)
    log.Printf("subquery 1 got item: %+v", user)

    user, err = ud.Where(ud.Columns(u.ID).Eq(ud.Select(u.ID.Max()))).First()
    // SELECT * FROM `users` WHERE `users`.`id` = (SELECT MAX(`users`.`id`) FROM `users` WHERE `users`.`deleted_at` IS NULL) AND `users`.`deleted_at` IS NULL
    // ORDER BY `users`.`id` LIMIT 1
    util.CatchErr("subquery 2 fail", err)
    log.Printf("subquery 2 got item: %+v", user)

    users, err = ud.Distinct(u.Name).Find()
    // SELECT DISTINCT `users`.`name` FROM `users` WHERE `users`.`deleted_at` IS NULL
    // users, err = u.Select(u.Name).Distinct().Find()
    // users, err = u.Distinct(u.ID, u.Name).Find()
    // users, err = u.Distinct(u.ID, u.Name.As("n")).Find()
    util.CatchErr("select distinct fail", err)
    log.Printf("select distinct got: %d", len(users))

    /*--------------Diy query-------------*/
    user, err = ud.FindByNameAndAge("tom", 29)
    // SELECT * FROM `users` WHERE name='tom' and age=29 AND `users`.`deleted_at` IS NULL
    util.CatchErr("FindByNameAndAge fail", err)
    log.Printf("FindByNameAndAge: %+v", user)

    users, err = ud.FindBySimpleName()
    // select id,name,age from users where age>18
    util.CatchErr("FindBySimpleName fail", err)
    log.Printf("FindBySimpleName: (%d)%+v", len(users), users)

    user, err = ud.Select(u.ID, u.Name).Where(u.ID.Eq(1)).Attrs(u.Name.Value("modi")).Assign(u.Age.Value(17)).FirstOrCreate()
    // UPDATE `users` SET `age`=17 WHERE `users`.`id` = 1 AND `users`.`deleted_at` IS NULL
    util.CatchErr("FirstOrCreate fail", err)
    log.Printf("FirstOrCreate got: %+v", user)
}
```
