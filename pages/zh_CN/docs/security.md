---
title: 安全
layout: page
---

GORM 使用 `database/sql` 的参数占位符来构造 SQL 语句，这可以自动转义参数，避免 SQL 注入数据

{% note warn %}
**注意** Logger 打印的 SQL 并不像最终执行的 SQL 那样已经转义，复制和运行这些 SQL 时应当注意。
{% endnote %}

## 查询条件

用户的输入只能作为参数，例如：

```go
userInput := "jinzhu;drop table users;"

// 安全的，会被转义
db.Where("name = ?", userInput).First(&user)

// SQL 注入
db.Where(fmt.Sprintf("name = %v", userInput)).First(&user)
```

## 内联条件

```go
// will be escaped
db.First(&user, "name = ?", userInput)

// SQL injection
db.First(&user, fmt.Sprintf("name = %v", userInput))
```

When retrieving objects with number primary key by user's input, you should check the type of variable.

```go
userInputID := "1=1;drop table users;"
// safe, return error
id,err := strconv.Atoi(userInputID)
if err != nil {
    return error
}
db.First(&user, id)

// SQL injection
db.First(&user, userInputID)
// SELECT * FROM users WHERE 1=1;drop table users;
```

## SQL 注入方法

To support some features, some inputs are not escaped, be careful when using user's input with those methods

```go
db.Select("name; drop table users;").First(&user)
db.Distinct("name; drop table users;").First(&user)

db.Model(&user).Pluck("name; drop table users;", &names)

db.Group("name; drop table users;").First(&user)

db.Group("name").Having("1 = 1;drop table users;").First(&user)

db.Raw("select name from users; drop table users;").First(&user)

db.Exec("select name from users; drop table users;")

db.Order("name; drop table users;").First(&user)
```

The general rule to avoid SQL injection is don't trust user-submitted data, you can perform whitelist validation to test user input against an existing set of known, approved, and defined input, and when using user's input, only use them as an argument.
