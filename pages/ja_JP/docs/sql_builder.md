---
title: SQL Builder
layout: page
---

## Raw SQL

`Scan` を使用して素のSQLでレコードを取得することができます。

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
db.Raw("SELECT SUM(age) FROM users WHERE role = ?", "admin").Scan(&age)

var users []User
db.Raw("UPDATE users SET name = ? WHERE age = ? RETURNING id, name", "jinzhu", 20).Scan(&users)
```

素のSQLで `Exec` を実行することも可能です。

```go
db.Exec("DROP TABLE users")
db.Exec("UPDATE orders SET shipped_at = ? WHERE id IN ?", time.Now(), []int64{1, 2, 3})

// Exec with SQL Expression
db.Exec("UPDATE users SET money = ? WHERE name = ?", gorm.Expr("money * ? + ?", 10000, 1), "jinzhu")
```

{% note warn %}
**注** GORMはパフォーマンスを向上のためにプリペアードステートメントをキャッシュすることができます。詳細は [Performance](performance.html) を参照してください。
{% endnote %}

## <span id="named_argument">名前付き引数</span>

GORMは [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) や `map[string]interface{}{}` 、構造体を使用した名前付き引数をサポートしています。例：

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu2"}).First(&result3)
// SELECT * FROM `users` WHERE name1 = "jinzhu2" OR name2 = "jinzhu2" ORDER BY `users`.`id` LIMIT 1

// Named Argument with Raw SQL
db.Raw("SELECT * FROM users WHERE name1 = @name OR name2 = @name2 OR name3 = @name",
   sql.Named("name", "jinzhu1"), sql.Named("name2", "jinzhu2")).Find(&user)
// SELECT * FROM users WHERE name1 = "jinzhu1" OR name2 = "jinzhu2" OR name3 = "jinzhu1"

db.Exec("UPDATE users SET name1 = @name, name2 = @name2, name3 = @name",
   sql.Named("name", "jinzhunew"), sql.Named("name2", "jinzhunew2"))
// UPDATE users SET name1 = "jinzhunew", name2 = "jinzhunew2", name3 = "jinzhunew"

db.Raw("SELECT * FROM users WHERE (name1 = @name AND name3 = @name) AND name2 = @name2",
   map[string]interface{}{"name": "jinzhu", "name2": "jinzhu2"}).Find(&user)
// SELECT * FROM users WHERE (name1 = "jinzhu" AND name3 = "jinzhu") AND name2 = "jinzhu2"

type NamedArgument struct {
    Name string
    Name2 string
}

db.Raw("SELECT * FROM users WHERE (name1 = @Name AND name3 = @Name) AND name2 = @Name2",
     NamedArgument{Name: "jinzhu", Name2: "jinzhu2"}).Find(&user)
// SELECT * FROM users WHERE (name1 = "jinzhu" AND name3 = "jinzhu") AND name2 = "jinzhu2"
```

## DryRun Mode

実行せずに、`SQL` とその引数の生成だけを行います。生成されたSQLの確認やテストを行えます。詳細については[Session](session.html) を確認してください。

```go
stmt := db.Session(&Session{DryRun: true}).First(&user, 1).Statement
stmt.SQL.String() //=> SELECT * FROM `users` WHERE `id` = $1 ORDER BY `id`
stmt.Vars         //=> []interface{}{1}
```

## ToSQL

実行はせずに、生成された `SQL` を返します。

GORMはSQL文を構築するために database/sql のプレースホルダ引数を使用します。これにより、引数を自動的にエスケープし、SQLインジェクションを防ぐことができます。 しかし、生成されたSQLが安全であるという保証はしていないため、デバッグにのみ使用するようにしてください。

```go
sql := DB.ToSQL(func(tx *gorm.DB) *gorm.DB {
  return tx.Model(&User{}).Where("id = ?", 100).Limit(10).Order("age desc").Find(&[]User{})
})
sql //=> SELECT * FROM "users" WHERE id = 100 AND "users"."deleted_at" IS NULL ORDER BY age desc LIMIT 10
```

## `Row` & `Rows`

結果を `*sql.Row` として取得します。

```go
// GORMのAPIを利用
row := db.Table("users").Where("name = ?", "jinzhu").Select("name", "age").Row()
row.Scan(&name, &age)

// SQL文を利用
row := db.Raw("select name, age, email from users where name = ?", "jinzhu").Row()
row.Scan(&name, &age, &email)
```

結果を `*sql.Rows` として取得します。

```go
// SQLの組み立てにGORM APIを使用
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // do something
}

// 素のSQL
rows, err := db.Raw("select name, age, email from users where name = ?", "jinzhu").Rows()
defer rows.Close()
for rows.Next() {
  rows.Scan(&name, &age, &email)

  // do something
}
```

バッチ処理でのレコード取得やレコード処理の方法については、[FindInBatches](advanced_query.html) を参照してください。また、複雑なSQLクエリの構築方法については、[Group Conditions](advanced_query.html#group_conditions) を参照してください。

## `*sql.Rows` を構造体へ Scan

`ScanRows` を使用して、取得した行データを構造体にScanすることができます。例：

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows() // (*sql.Rows, error)
defer rows.Close()

var user User
for rows.Next() {
  // ScanRows scan a row into user
  db.ScanRows(rows, &user)

  // do something
}
```

## <span id="connection">Connection</span>

同じtcp接続で複数のSQLを実行することができます(トランザクションを意味するものではありません)

```go
db.Connection(func(tx *gorm.DB) error {
  tx.Exec("SET my.role = ?", "admin")

  tx.First(&User{})
})
```

## 高度な機能

### <span id="clauses">Clauses</span>

GORMは内部的にSQLビルダーを使用してSQLを生成します。各操作に対し、GORMは `*gorm.Statement` オブジェクトを作成し、すべてのGORM APIで `Statement`に`Clause` を追加/変更し、最終的にこれらの `Clause` にもとづいてSQLを生成します。

例えば `First` でレコードを取得する場合、`First` は内部的に、以下の `Clauses` を `Statement` に追加します。

```go
clause.Select{Columns: "*"}
clause.From{Tables: clause.CurrentTable}
clause.Limit{Limit: 1}
clause.OrderByColumn{
  Column: clause.Column{Table: clause.CurrentTable, Name: clause.PrimaryKey},
}
```

その後、GORMは `Query` コールバックで最終的に実行されるSQLクエリを組み立てます。

```go
Statement.Build("SELECT", "FROM", "WHERE", "GROUP BY", "ORDER BY", "LIMIT", "FOR")
```

生成されるSQLは以下のようになります。

```sql
SELECT * FROM `users` ORDER BY `users`.`id` LIMIT 1
```

独自の `Clause` を定義して、それを利用することも可能です。その際は [Interface](https://pkg.go.dev/gorm.io/gorm/clause?tab=doc#Interface) を実装する必要があります。

詳細については [examples](https://github.com/go-gorm/gorm/tree/master/clause) を参照してください。

### Clause Builder

データベースの種別に応じて、Clausesはそれぞれ異なるSQLを生成します。例：

```go
db.Offset(10).Limit(5).Find(&users)
// Generated for SQL Server
// SELECT * FROM "users" OFFSET 10 ROW FETCH NEXT 5 ROWS ONLY
// Generated for MySQL
// SELECT * FROM `users` LIMIT 5 OFFSET 10
```

データベースドライバがClause Builderを登録することで、デフォルトのものを置き換えることが可能になっているため、これが可能となっています。 例として [Limit](https://github.com/go-gorm/sqlserver/blob/512546241200023819d2e7f8f2f91d7fb3a52e42/sqlserver.go#L45) を参照してみるとよいでしょう。

### Clause Options

GORMは [多くのClauses](https://github.com/go-gorm/gorm/tree/master/clause) を定義しています。いくつかのClausesは高度なオプションを提供し、アプリケーションで使用することができます。

ほとんど使われることはないかもしれませんが、もしGORMのAPIがアプリケーションの要求にマッチしない場合は、それらを調べてみてもよいでしょう。例：

```go
db.Clauses(clause.Insert{Modifier: "IGNORE"}).Create(&user)
// INSERT IGNORE INTO users (name,age...) VALUES ("jinzhu",18...);
```

### StatementModifier

GORMは [StatementModifier](https://pkg.go.dev/gorm.io/gorm?tab=doc#StatementModifier) インターフェイスを提供しており、これを利用することでアプリケーションの要求に合うようにstatementを修正することが可能になります。例として [Hints](hints.html) を参照するとよいでしょう。

```go
import "gorm.io/hints"

db.Clauses(hints.New("hint")).Find(&User{})
// SELECT * /*+ hint */ FROM `users`
```
