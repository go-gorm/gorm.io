---
title: Безопасность
layout: страница
---

GORM использует плейсхолдеры аргументов `database/sql`для построения запросов SQL, которые автоматически экранирует аргументы во избежание инъекции SQL

**ПРИМЕЧАНИЕ** SQL в Logger экранируется не полностью, как тот, который выполняется, будьте осторожны при копировании и выполнении SQL запросов из Logger

## Условие запроса

Переданные пользователем значения должны использоваться только в качестве аргумента, например:

```go
userInput := "jinzhu;drop table users;"

// безопасно, будет экранировано
db.Where("name = ?", userInput).First(&user)

// SQL инъекция
db.Where(fmt.Sprintf("name = %v", userInput)).First(&user)
```

## Строчные условия

```go
// будет экранировано
db.First(&user, "name = ?", userInput)

// SQL инъекция
db..First(&user, fmt.Sprintf("name = %v", userInput))
```

## Методы SQL инъекции

Для поддержки некоторых функций, некоторые входные параметры не экранируются, будьте осторожны при использовании пользовательского ввода этими методами

```go
db.Select("name; drop table users;").First(&user)
db.Distinct("name; drop table users;").First(&user)

db.Model(&user).Pluck("name; drop table users;", &names)

db.Group("name; drop table users;").First(&user)

db.Group("name").Having("1 = 1;drop table users;").First(&user)

db.Raw("select name from users; drop table users;").First(&user)

db.Exec("select name from users; drop table users;")
```

Общее правило, чтобы избежать инъекции SQL, не доверяйте пользовательским данным, вы можете выполнить проверку по белому списку для проверки входных данных пользователя в существующем наборе известных утверждений, при использовании пользовательских данных ввода, используйте их только в качестве аргумента.
