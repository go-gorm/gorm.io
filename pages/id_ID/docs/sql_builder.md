---
title: Pembangun SQL
layout: page
---
## Jalankan SQL Mentah

Jalankan Raw SQL, yang tidak berantai dengan metode lain

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

## `sql.Row` & `sql.Rows`

Dapatkan permintaan hasil sebagai `*sql.Row` atau `*sql.Rows`

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

// Raw SQL
rows, err := db.Raw("select name, age, email from users where name = ?", "jinzhu").Rows() // (*sql.Rows, error)
defer rows.Close()
for rows.Next() {
    ...
    rows.Scan(&name, &age, &email)
    ...
}
```

## Pindai `sql.Rows` ke dalam model

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