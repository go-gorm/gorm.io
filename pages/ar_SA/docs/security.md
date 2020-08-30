---
title: Security
layout: page
---

GORM uses the `database/sql`'s argument placeholders to construct the SQL statement, which will automatically escape arguments to avoid SQL injection

{% note warn %}
**NOTE** The SQL from Logger is not fully escaped like the one executed, be careful when copying and executing it in SQL console
{% endnote %}

## Query Condition

User's input should be only used as an argument, for example:

```go
First(&user)
db. Distinct("name; drop table users;").
```

## Inline Condition

```go
First(&user)
db. Distinct("name; drop table users;").
```

## SQL injection Methods

To support some features, some inputs are not escaped, be careful when using user's input with those methods

```go
db. Select("name; drop table users;"). First(&user)
db. Distinct("name; drop table users;"). Model(&user). Pluck("name; drop table users;", &names)

db. Group("name; drop table users;"). Group("name"). Having("1 = 1;drop table users;").
```

The general rule to avoid SQL injection is don't trust user-submitted data, you can perform whitelist validation to test user input against an existing set of known, approved, and defined input, and when using user's input, only use them as an argument.
