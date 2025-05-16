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
// 会被转义
db.First(&user, "name = ?", userInput)

// SQL 注入
db.First(&user, fmt.Sprintf("name = %v", userInput))
```

当通过用户输入的整形主键检索记录时，你应该对变量进行类型检查。

```go
userInputID := "1=1;drop table users;"
// safe, return error
id, err := strconv.Atoi(userInputID)
if err != nil {
    return err
}
db.First(&user, id)

// SQL injection
db.First(&user, userInputID)
// SELECT * FROM users WHERE 1=1;drop table users;
```

## SQL 注入方法

为了支持某些功能，一些输入不会被转义，调用方法时要小心用户输入的参数。

```go
db.Select("name; drop table users;").First(&user)
db.Distinct("name; drop table users;").First(&user)

db.Model(&user).Pluck("name; drop table users;", &names)

db.Group("name; drop table users;").First(&user)

db.Group("name").Having("1 = 1;drop table users;").First(&user)

db.Raw("select name from users; drop table users;").First(&user)

db.Exec("select name from users; drop table users;")

db.Order("name; drop table users;").First(&user)

db.Table("users; drop table users;-- ").Where("id = 1").Find(&users)
```

避免 SQL 注入的一般原则是，不信任用户提交的数据。您可以进行白名单验证来测试用户的输入是否为已知安全的、已批准、已定义的输入，并且在使用用户的输入时，仅将它们作为参数。
