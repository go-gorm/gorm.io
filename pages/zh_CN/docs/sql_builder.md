---
title: SQL 构造器
layout: page
---

## 原生 SQL

原生 SQL 查询

```go
type Result struct {
  ID   int
  Name string
  Age  int
}

var result Result
db.Raw("SELECT id, name, age FROM users WHERE name = ?", 3).Scan(&result)

db.Raw("SELECT id, name, age FROM users WHERE name = ?", 3).Scan(&result)

var age int
DB.Raw("select sum(age) from users where role = ?", "admin").Scan(&age)
```

执行原生 SQL

```go
db.Exec("DROP TABLE users")
db.Exec("UPDATE orders SET shipped_at=? WHERE id IN ?", time.Now(), []int64{1,2,3})

// SQL 表达式
DB.Exec("update users set money=? where name = ?", gorm.Expr("money * ? + ?", 10000, 1), "jinzhu")
```

**注意** GORM 允许缓存准备好的语句来提高性能，详情请参考 [性能](performance.html)

## `Row` & `Rows`

获取 `*sql.Row` 结果

```go
// 使用 GORM API 构建 SQL
row := db.Table("users").Where("name = ?", "jinzhu").Select("name", "age").Row()
row.Scan(&name, &age)

// 使用原生 SQL
row := db.Raw("select name, age, email from users where name = ?", "jinzhu").Row()
row.Scan(&name, &age, &email)
```

获取 `*sql.Rows` 结果

```go
// 使用 GORM API 构建 SQL
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // 业务逻辑...
}

// 原生 SQL
rows, err := db.Raw("select name, age, email from users where name = ?", "jinzhu").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // 业务逻辑...
}
```

转到 [FindInBatches](advanced_query.html) 获取如何在批量中查询和处理记录的信息， 转到 [Group 条件](advanced_query.html#group_conditions) 获取如何构建复杂 SQL 查询的信息

## <span id="named_argument">命名参数</span>

GORM 支持 [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) 或 `map[string]interface{}{}` 命名参数，例如：

```go
DB.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `named_users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

DB.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu2"}).First(&result3)
// SELECT * FROM `named_users` WHERE name1 = "jinzhu2" OR name2 = "jinzhu2" ORDER BY `named_users`.`id` LIMIT 1

DB.Raw("SELECT * FROM named_users WHERE name1 = @name OR name2 = @name2 OR name3 = @name", sql.Named("name", "jinzhu1"), sql.Named("name2", "jinzhu2")).Find(&user)
// SELECT * FROM named_users WHERE name1 = "jinzhu1" OR name2 = "jinzhu2" OR name3 = "jinzhu1"

DB.Exec("UPDATE named_users SET name1 = @name, name2 = @name2, name3 = @name", sql.Named("name", "jinzhunew"), sql.Named("name2", "jinzhunew2"))
// UPDATE named_users SET name1 = "jinzhunew", name2 = "jinzhunew2", name3 = "jinzhunew"

DB.Raw("SELECT * FROM named_users WHERE (name1 = @name AND name3 = @name) AND name2 = @name2", map[string]interface{}{"name": "jinzhu", "name2": "jinzhu2"}).Find(&user)
// SELECT * FROM named_users WHERE (name1 = "jinzhu" AND name3 = "jinzhu") AND name2 = "jinzhu2"
```

## 将 `sql.Rows` 扫描至 struct

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows() // (*sql.Rows, error)
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows 将一行扫描至 user
  db.ScanRows(rows, &user)

  // 业务逻辑...
}
```

## DryRun 模式

在不执行的情况下生成 `SQL` ，可以用于准备或测试生成的 SQL，详情请参考 [Session](session.html)

```go
stmt := DB.Session(&Session{DryRun: true}).First(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 ORDER BY `id`
stmt.Vars         //=> []interface{}{1}
```

## 高级

### Clauses

GORM 内部使用 SQL builder 生成 SQL。对于每个操作，GORM 都会创建一个 `*gorm.Statement` 对象，所有的 GORM API 都是在为 `statement` 添加/修改 `Clause`，最后，GORM 会根据这些 Clause 生成 SQL

例如，当通过 `First` 进行查询时，它会在 `Statement` 中添加以下 Clause

```go
clause.Select{Columns: "*"}
clause.From{Tables: clause.CurrentTable}
clause.Limit{Limit: 1}
clause.OrderByColumn{
  Column: clause.Column{Table: clause.CurrentTable, Name: clause.PrimaryKey},
}
```

然后 GORM 在回调中构建最终的查询 SQL，比如：

```go
Statement.Build("SELECT", "FROM", "WHERE", "GROUP BY", "ORDER BY", "LIMIT", "FOR")
```

Which generate SQL:

```sql
SELECT * FROM `users` ORDER BY `users`.`id` LIMIT 1
```

You can define your own `Clause` and use it with GORM, it needs to implements [Interface](https://pkg.go.dev/gorm.io/gorm/clause?tab=doc#Interface)

Check out [examples](https://github.com/go-gorm/gorm/tree/master/clause) for reference

### Clause Builder

For different databases, Clauses may generate different SQL, for example:

```go
db.Offset(10).Limit(5).Find(&users)
// Generated for SQL Server
// SELECT * FROM "users" OFFSET 10 ROW FETCH NEXT 5 ROWS ONLY
// Generated for MySQL
// SELECT * FROM `users` LIMIT 5 OFFSET 10
```

Which is supported because GORM allows database driver register Clause Builder to replace the default one, take the [Limit](https://github.com/go-gorm/sqlserver/blob/512546241200023819d2e7f8f2f91d7fb3a52e42/sqlserver.go#L45) as example

### Clause Options

GORM defined [Many Clauses](https://github.com/go-gorm/gorm/tree/master/clause), and some clauses provide advanced options can be used for your application

Although most of them are rarely used, if you find GORM public API can't match your requirements, may be good to check them out, for example:

```go
DB.Clauses(clause.Insert{Modifier: "IGNORE"}).Create(&user)
// INSERT IGNORE INTO users (name,age...) VALUES ("jinzhu",18...);
```

### StatementModifier

GORM provides interface [StatementModifier](https://pkg.go.dev/gorm.io/gorm?tab=doc#StatementModifier) allows you modify statement to match your requirements, take [Hints](hints.html) as example

```go
import "gorm.io/hints"

DB.Clauses(hints.New("hint")).Find(&User{})
// SELECT * /*+ hint */ FROM `users`
```
