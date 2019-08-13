---
title: SQL 生成器
layout: page
---

## 执行原生SQL

执行原生 SQL 时，不支持与其它方法的链式操作

```go
db.Exec("DROP TABLE users;")
db.Exec("UPDATE orders SET shipped_at=? WHERE id IN (?)", time.Now(), []int64{11,22,33})

// Scan
type Result struct {
    Name string
    Age  int
}

var result Result
db.Raw("SELECT name, age FROM users WHERE name = ?", 3).Scan(&result)
```

## `sql.Row` 和 `sql.Rows`

通过 `*sql.Row` 或 `*sql.Rows` 获取查询结果

```go
row := db.Table("users").Where("name = ?", "jinzhu").Select("name, age").Row() // (*sql.Row)
row.Scan(&name, &age)

rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows() // (*sql.Rows, error)
defer rows.Close()
for rows.Next() {
    ...
    rows.Scan(&name, &age, &email)
    ...
}

// 原生 SQL
rows, err := db.Raw("select name, age, email from users where name = ?", "jinzhu").Rows() // (*sql.Rows, error)
defer rows.Close()
for rows.Next() {
    ...
    rows.Scan(&name, &age, &email)
    ...
}
```

## 将 `sql.Rows` 扫描至 model

```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Select("name, age, email").Rows() // (*sql.Rows, error)
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows 扫描一行记录到 user
  db.ScanRows(rows, &user)

  // do something
}
}
```