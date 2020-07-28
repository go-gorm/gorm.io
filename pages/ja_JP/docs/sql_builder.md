---
title: SQL Builder
layout: page
---

## Raw SQL

SQL文でQuery

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

SQL文でEXEC

```go
db.Exec("DROP TABLE users")
db.Exec("UPDATE orders SET shipped_at=? WHERE id IN ?", time.Now(), []int64{1,2,3})

// SQL Expression
DB.Exec("update users set money=? where name = ?", gorm.Expr("money * ? + ?", 10000, 1), "jinzhu")
```

**注** GORMはパフォーマンスを向上のためにプリペアードステイトメントをキャッシュできます。詳細は[Performance](performance.html)を参照してください。

## `Row` & `Rows`

`*sql.Row` として結果を取得します

```go
// GORMのAPIを利用
row := db.Table("users").Where("name = ?", "jinzhu").Select("name", "age").Row()
row.Scan(&name, &age)

// SQL文を利用
row := db.Raw("select name, age, email from users where name = ?", "jinzhu").Row()
row.Scan(&name, &age, &email)
```

`*sql.Rows` として結果を取得します

```go
// Use GORM API build SQL
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // do something
}

// Raw SQL
rows, err := db.Raw("select name, age, email from users where name = ?", "jinzhu").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // do something
}
```

バッチでレコードをクエリしたり処理したいなら、[FindInBatches](advanced_query.html)をチェックしてください。 複雑なSQLクエリを構築する方法については[Group Conditions](advanced_query.html#group_conditions) をチェックしてください。

## <span id="named_argument">Named Argument</span>

GORMは [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) または `map[string]interface{}{}`を使用した名前付き引数をサポートしています。例えば:

```go
DB.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

DB.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu2"}).First(&result3)
// SELECT * FROM `users` WHERE name1 = "jinzhu2" OR name2 = "jinzhu2" ORDER BY `users`.`id` LIMIT 1

DB.Raw("SELECT * FROM users WHERE name1 = @name OR name2 = @name2 OR name3 = @name", sql.Named("name", "jinzhu1"), sql.Named("name2", "jinzhu2")).Find(&user)
// SELECT * FROM users WHERE name1 = "jinzhu1" OR name2 = "jinzhu2" OR name3 = "jinzhu1"

DB.Exec("UPDATE users SET name1 = @name, name2 = @name2, name3 = @name", sql.Named("name", "jinzhunew"), sql.Named("name2", "jinzhunew2"))
// UPDATE users SET name1 = "jinzhunew", name2 = "jinzhunew2", name3 = "jinzhunew"

DB.Raw("SELECT * FROM users WHERE (name1 = @name AND name3 = @name) AND name2 = @name2", map[string]interface{}{"name": "jinzhu", "name2": "jinzhu2"}).Find(&user)
// SELECT * FROM users WHERE (name1 = "jinzhu" AND name3 = "jinzhu") AND name2 = "jinzhu2"
```

## Scan `*sql.Rows` into struct

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows() // (*sql.Rows, error)
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows scan a row into user
  db.ScanRows(rows, &user)

  // do something
}
```

## DryRun Mode

実行せずに、`SQL`の生成だけを行います。生成されたSQLを確認したりテストしたりできます。詳細については[Session](session.html) を確認してください。

```go
stmt := DB.Session(&Session{DryRun: true}).First(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 ORDER BY `id`
stmt.Vars         //=> []interface{}{1}
```

## Advanced

### Clauses

GORMはSQLビルダーを使用して内部的にSQLを生成します。各操作に対し、GORMは`*gorm.Statement`オブジェクトを作成し、すべてのGORM APIで`Statement`に`Clause`を追加/変更し、最後にこれらの`Clause`にもとづいてSQLを生成します。

たとえば、 `First`でクエリを行う場合、`First`は内部的に、次の`Clauses`を`Statement`に追加します。

```go
clause.Select{Columns: "*"}
clause.From{Tables: clause.CurrentTable}
clause.Limit{Limit: 1}
clause.OrderByColumn{
  Column: clause.Column{Table: clause.CurrentTable, Name: clause.PrimaryKey},
}
```

それから、Gormは最終的にコールバックでSQLをクエリするように作成します。以下のように：

```go
Statement.Build("SELECT", "FROM", "WHERE", "GROUP BY", "ORDER BY", "LIMIT", "FOR")
```

作成されるSQL：

```sql
SELECT * FROM `users` ORDER BY `users`.`id` LIMIT 1
```

独自の`Clause`を定義し、GORMで利用できます。[Interface](https://pkg.go.dev/gorm.io/gorm/clause?tab=doc#Interface)を実装する必要があります。

[examples](https://github.com/go-gorm/gorm/tree/master/clause) を参照してください。

### Clause Builder

データベースの種類によって、Clausesは違うSQLを生成します。例：

```go
db.Offset(10).Limit(5).Find(&users)
// Generated for SQL Server
// SELECT * FROM "users" OFFSET 10 ROW FETCH NEXT 5 ROWS ONLY
// Generated for MySQL
// SELECT * FROM `users` LIMIT 5 OFFSET 10
```

GORMは、データベースドライバがデフォルトのものを置き換えることによってClauseビルダーを登録できるようにしているので、この機能がサポートされています。 [Limit](https://github.com/go-gorm/sqlserver/blob/512546241200023819d2e7f8f2f91d7fb3a52e42/sqlserver.go#L45)を例に取りました。

### Clause Options

GORMは[さまざまなClauses](https://github.com/go-gorm/gorm/tree/master/clause)を定義しています。いくつかのClausesは、高度なオプションを提供し、アプリケーションに使用することができます。

ほとんど使われることはありませんが、もし、GORMの公開APIがあなたの要求にマッチしない場合は、調べてみるのもいいかもしれません。例：

```go
DB.Clauses(clause.Insert{Modifier: "IGNORE"}).Create(&user)
// INSERT IGNORE INTO users (name,age...) VALUES ("jinzhu",18...);
```

### StatementModifier

GORMはあなたの要求に合うようにstatementを修正することを許可する[StatementModifier](https://pkg.go.dev/gorm.io/gorm?tab=doc#StatementModifier)。 [Hints](hints.html)を例にとります。

```go
import "gorm.io/hints"

DB.Clauses(hints.New("hint")).Find(&User{})
// SELECT * /*+ hint */ FROM `users`
```
