---
title: 高级查询
layout: page
---

## <span id="smart_select">智能选择字段</span>

在 GORM 中，您可以使用 [`Select`](query.html) 方法有效地选择特定字段。 这在Model字段较多但只需要其中部分的时候尤其有用，比如编写API响应。

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // 很多很多字段
}

type APIUser struct {
  ID   uint
  Name string
}

// 在查询时，GORM 会自动选择 `id `, `name` 字段
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SQL: SELECT `id`, `name` FROM `users` LIMIT 10
```

{% note warn %}
**注意** 在 `QueryFields` 模式中, 所有的模型字段（model fields）都会被根据他们的名字选择。
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  QueryFields: true,
})

// 当 QueryFields 被设置为 true 时，此行为默认进行
db.Find(&user)
// SQL: SELECT `users`.`name`, `users`.`age`, ... FROM `users`

// 开启 QueryFields 并使用会话模式（Session mode）
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SQL: SELECT `users`.`name`, `users`.`age`, ... FROM `users`
```

## 锁

GORM 支持多种类型的锁，例如：

```go
// 基本的 FOR UPDATE 锁
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SQL: SELECT * FROM `users` FOR UPDATE
```

上述语句将会在事务（transaction）中锁定选中行（selected rows）。 可以被用于以下场景：当你准备在事务（transaction）中更新（update）一些行（rows）时，并且想要在本事务完成前，阻止（prevent）其他的事务（other transactions）修改你准备更新的选中行。

`Strength` 也可以被设置为 `SHARE` ，这种锁只允许其他事务读取（read）被锁定的内容，而无法修改（update）或者删除（delete）。
```go
db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SQL: SELECT * FROM `users` FOR SHARE OF `users`
```

`Table`选项用于指定将要被锁定的表。 这在你想要 join 多个表，并且锁定其一时非常有用。

你也可以提供如 `NOWAIT` 的Options，这将尝试获取一个锁，如果锁不可用，导致了获取失败，函数将会立即返回一个error。 当一个事务等待其他事务释放它们的锁时，此Options（Nowait）可以阻止这种行为

```go
db.Clauses(clause.Locking{
  Strength: "UPDATE",
  Options: "NOWAIT",
}).Find(&users)
// SQL: SELECT * FROM `users` FOR UPDATE NOWAIT
```

Options也可以是`SKIP LOCKED`，设置后将跳过所有已经被其他事务锁定的行（any rows that are already locked by other transactions.）。 这次高并发情况下非常有用：那时你可能会想要对未经其他事务锁定的行进行操作（process ）。

想了解更多高级的锁策略，请参阅 [Raw SQL and SQL Builder](sql_builder.html)。

## 子查询

子查询（Subquery）是SQL中非常强大的功能，它允许嵌套查询。 当你使用 *gorm.DB 对象作为参数时，GORM 可以自动生成子查询。

```go
// 简单的子查询
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SQL: SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");

// 内嵌子查询
subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SQL: SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">From 子查询</span>

GORM 允许在 FROM 子句中使用子查询，从而支持复杂的查询和数据组织。

```go
// 在 FROM 子句中使用子查询
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18).Find(&User{})
// SQL: SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

// 在 FROM 子句中结合多个子查询
subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SQL: SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Group 条件</span>

GORM 中的Group条件（Group Conditions）提供了一种可读性更强，操作性更强的方法来写复杂的，涉及多个条件的 SQL 查询。

```go
// 使用 Group 条件的复杂 SQL 查询
db.Where(
  db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
  db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{})
// SQL: SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## 带多个列的 In

GROM 支持多列的 IN 子句（the IN clause with multiple columns），允许你在单次查询里基于多个字段值筛选数据。

```go
// 多列 IN
db.Where("(name, age, role) IN ?", [][]interface{}{{"jinzhu", 18, "admin"}, {"jinzhu2", 19, "user"}}).Find(&users)
// SQL: SELECT * FROM users WHERE (name, age, role) IN (("jinzhu", 18, "admin"), ("jinzhu 2", 19, "user"));
```

## 命名参数

GORM 支持命名的参数，提高SQL 查询的可读性和可维护性。 此功能使查询结构更加清晰、更加有条理，尤其是在有多个参数的复杂查询中。 命名参数可以使用 [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) 或 `map[string]interface{}{}}`，你可以根据你的查询结构灵活提供。

```go
// 使用 sql.NamedArg 命名参数的例子
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SQL: SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

// 使用 map 命名参数的例子
db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SQL: SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

欲了解更多示例和详细信息，请参阅 [Raw SQL 和 SQL Builder](sql_builder.html#named_argument)

## Find 至 map

GORM 提供了灵活的数据查询，允许将结果扫描进（scanned into）`map[string]interface{}` or `[]map[string]interface{}`，这对动态数据结构非常有用。

当使用 `Find To Map`时，一定要在你的查询中包含 `Model` 或者 `Table` ，以此来显式地指定表名。 这能确保 GORM 正确的理解哪个表要被查询。

```go
// 扫描第一个结果到 map with Model 中
result := map[string]interface{}{}
db.Model(&User{}).First(&result, "id = ?", 1)
// SQL: SELECT * FROM `users` WHERE id = 1 LIMIT 1

// 扫描多个结果到部分 maps with Table 中
var results []map[string]interface{}
db.Table("users").Find(&results)
// SQL: SELECT * FROM `users`
```

## FirstOrInit

GORM 的 `FirstOrInit` 方法用于获取与特定条件匹配的第一条记录，如果没有成功获取，就初始化一个新实例。 这个方法与结构和map条件兼容，并且在使用 `Attrs` 和 `Assign` 方法时有着更多的灵活性。

```go
// 如果没找到 name 为 "non_existing" 的 User，就初始化一个新的 User
var user User
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"} if not found

// 检索名为 “jinzhu” 的 User
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18} if found

// 使用 map 来指定搜索条件
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18} if found
```

### 使用 `Attrs` 进行初始化

当记录未找到，你可以使用 `Attrs` 来初始化一个有着额外属性的结构体。 这些属性包含在新结构中，但不在 SQL 查询中使用。

```go
// 如果没找到 User，根据所给条件和额外属性初始化 User
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SQL: SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20} if not found

// 如果名为 “Jinzhu” 的 User 被找到，`Attrs` 会被忽略
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SQL: SELECT * FROM USERS WHERE name = 'Jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 18} if found
```

### 为属性使用 `Assign`

`Assign` 方法允许您在结构上设置属性，不管是否找到记录。 这些属性设定在结构上，但不用于生成 SQL 查询，最终数据不会被保存到数据库。

```go
// 根据所给条件和分配的属性初始化，不管记录是否存在
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20} if not found

// 如果找到了名为“Jinzhu”的用户，使用分配的属性更新结构体
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SQL: SELECT * FROM USERS WHERE name = 'Jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20} if found
```

`FirstOrInit`, 以及 `Attrs` 和 `Assign`, 提供了一种强大和灵活的方法来确保记录的存在，并且在一个步骤中以特定的属性初始化或更新。

## FirstOrCreate

`FirstOrCreate` 用于获取与特定条件匹配的第一条记录，或者如果没有找到匹配的记录，创建一个新的记录。 这个方法在结构和map条件下都是有效的。 `受RowsAffected的` 属性有助于确定创建或更新记录的数量。

```go
// 如果没找到，就创建一个新纪录
result := db.FirstOrCreate(&user, User{Name: "non_existing"})
// SQL: INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}
// result.RowsAffected // => 1 (record created)

// 如果用户已经被找到，不会创建新纪录
result = db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
// result.RowsAffected // => 0 (no record created)
```

### 配合 `Attrs` 使用 FirstOrCreate

`Attrs` 可以用于指定新记录的附加属性。 这些属性用于创建，但不在初始搜索查询中。

```go
// 如果没找到，根据额外属性创建新的记录
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SQL: SELECT * FROM users WHERE name = 'non_existing';
// SQL: INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// 如果user被找到了，`Attrs` 会被忽略
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SQL: SELECT * FROM users WHERE name = 'jinzhu';
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

### 配合 `Assign` 使用 FirstOrCreate

不管记录是否被找到，`Assign` 方法都会设置记录中的属性。 并且这些属性被保存到数据库。

```go
// 如果没找到记录，通过 `Assign` 属性 初始化并且保存新的记录
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SQL: SELECT * FROM users WHERE name = 'non_existing';
// SQL: INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// 通过 `Assign` 属性 更新记录
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SQL: SELECT * FROM users WHERE name = 'jinzhu';
// SQL: UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## 优化器、索引提示

GORM 包括对优化器和索引提示的支持, 允许您影响查询优化器的执行计划。 这对于优化查询性能或处理复杂查询尤其有用。

优化器提示是说明数据库查询优化器应如何执行查询的指令。 GORM 通过 gorm.io/hints 包简化了优化器提示的使用。

```go
import "gorm.io/hints"

// 使用优化器提示来设置最大执行时长
db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SQL: SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

### 索引提示

索引提示为数据库提供关于使用哪些索引的指导。 如果查询规划者没有为查询选择最有效的索引，它们（索引提示）将是有好处的。

```go
import "gorm.io/hints"

// 对指定索引提供建议
db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SQL: SELECT * FROM `users` USE INDEX (`idx_user_name`)

// 强制对JOIN操作使用某些索引
db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SQL: SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)
```

这些提示会对查询性能和行为产生显著影响（significantly impact），特别是在大型数据库或复杂的数据模型中。 欲了解更详细的信息和其他示例，请参阅GORM 文档中的 [Optimizer Hints/Index/Comment](hints.html)。

## 迭代

GORM 支持使用 `Rows` 方法对查询结果进行迭代。 当您需要处理大型数据集或在每个记录上单独执行操作时，此功能特别有用。

您可以通过对查询返回的行进行迭代，扫描每行到一个结构体中。 该方法提供了对如何处理每条记录的粒度控制。（granular control）。

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Rows()
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows 扫描每一行进结构体
  db.ScanRows(rows, &user)

  // 对每一个 User 进行操作
}
```

这种方法非常适合于使用标准查询方法无法轻松实现的复杂数据处理。

## FindInBatches

`FindInBatches` 允许分批查询和处理记录。 这对于有效地处理大型数据集、减少内存使用和提高性能尤其有用。

使用`FindInBatches`, GORM 处理指定批大小的记录。 在批处理功能中，您可以对每批记录应用操作。

```go
// 处理记录，批处理大小为100
result := db.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // 对批中的每条记录进行操作
  }

  // 保存对当前批记录的修改
  tx.Save(&results)

  // tx.RowsAffected 提供当前批处理中记录的计数（the count of records in the current batch）
  // 'batch' 变量表示当前批号（the current batch number）

  // 返回 error 将阻止更多的批处理
  return nil
})

// result.Error 包含批处理过程中遇到的任何错误
// result.RowsAffected 提供跨批处理的所有记录的计数（the count of all processed records across batches）
```

`FindInBatches` 是处理大量可管理数据的有效工具，可以优化资源使用和性能。

## 查询钩子

GORM 提供了使用钩子的能力，例如 `AfterFind`，这些钩子是在查询的生命周期中触发的。 这些钩子允许在特定点执行自定义逻辑，例如在从数据库检索记录之后。

此钩子对后查询数据操纵或默认值设置非常有用。 欲了解更详细的信息和额外的钩子，请参阅GORM文档中的 [Hooks](hooks.html)。

```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  // 在找到 user 后自定义逻辑
  if u.Role == "" {
    u.Role = "user" // 如果没有指定，将设置默认 role
  }
  return
}

// 当用户被查询时，会自动使用AfterFind钩子
```

## <span id="pluck">Pluck</span>

GORM 中的 `Pluck` 方法用于从数据库中查询单列并扫描结果到片段（slice）。 当您需要从模型中检索特定字段时，此方法非常理想。

如果需要查询多个列，可以使用 `Select` 配合 [Scan](query.html) 或者 [Find](query.html) 来代替。

```go
// 检索所有用户的 age
var ages []int64
db.Model(&User{}).Pluck("age", &ages)

// 检索所有用户的 name
var names []string
db.Model(&User{}).Pluck("name", &names)

// 从不同的表中检索 name
db.Table("deleted_users").Pluck("name", &names)

// 使用Distinct和Pluck
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SQL: SELECT DISTINCT `name` FROM `users`

// 多列查询
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```

## Scope

GORM中的 `Scopes` 是一个强大的特性，它允许您将常用的查询条件定义为可重用的方法。 这些作用域可以很容易地在查询中引用，从而使代码更加模块化和可读。

### 定义 Scopes

`Scopes` 被定义为被修改后返回一个 `gorm.DB` 实例的函数。 您可以根据您的应用程序的需要定义各种条件作为范围。

```go
// Scope for filtering records where amount is greater than 1000
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
  return db.Where("amount > ?", 1000)
}

// Scope for orders paid with a credit card
func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

// Scope for orders paid with cash on delivery (COD)
func PaidWithCod(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "COD")
}

// Scope for filtering orders by status
func OrderStatus(status []string) func(db *gorm.DB) *gorm.DB {
  return func(db *gorm.DB) *gorm.DB {
    return db.Where("status IN (?)", status)
  }
}
```

### 在查询中使用 Scopes

你可以通过 `Scopes` 方法使用一个或者多个 Scope 来查询。 这允许您动态地连接多个条件。

```go
// 使用 scopes 来寻找所有的 金额大于1000的信用卡订单
db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)

// 使用 scopes 来寻找所有的 金额大于1000的货到付款（COD）订单
db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)

//使用 scopes 来寻找所有的 具有特定状态且金额大于1000的订单
db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
```

`Scopes` 是封装普通查询逻辑的一种干净而有效的方式，增强了代码的可维护性和可读性。 更详细的示例和用法，请参阅GORM 文档中的 [范围](scopes.html)。

## <span id="count">Count</span>

GORM中的 `Count` 方法用于检索匹配给定查询的记录数。 这是了解数据集大小的一个有用的功能，特别是在涉及有条件查询或数据分析的情况下。

### 得到匹配记录的 Count

您可以使用 `Count` 来确定符合您的查询中符合特定标准的记录的数量。

```go
var count int64

// 计数 有着特定名字的 users
db.Model(&User{}).Where("name = ?", "jinzhu").Or("name = ?", "jinzhu 2").Count(&count)
// SQL: SELECT count(1) FROM users WHERE name = 'jinzhu' OR name = 'jinzhu 2'

// 计数 有着单一名字条件（single name condition）的 users
db.Model(&User{}).Where("name = ?", "jinzhu").Count(&count)
// SQL: SELECT count(1) FROM users WHERE name = 'jinzhu'

// 在不同的表中对记录计数
db.Table("deleted_users").Count(&count)
// SQL: SELECT count(1) FROM deleted_users
```

### 配合 Distinct 和 Group 使用 Count

GORM还允许对不同的值进行计数并对结果进行分组。

```go
// 为不同 name 计数
db.Model(&User{}).Distinct("name").Count(&count)
// SQL: SELECT COUNT(DISTINCT(`name`)) FROM `users`

// 使用自定义选择（custom select）计数不同的值
db.Table("deleted_users").Select("count(distinct(name))").Count(&count)
// SQL: SELECT count(distinct(name)) FROM deleted_users

// 分组记录计数
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

db.Model(&User{}).Group("name").Count(&count)
// 按名称分组后计数
// count => 3
```
