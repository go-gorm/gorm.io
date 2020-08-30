---
title: Context
layout: page
---

GORM provides Context support, you can use it with method `WithContext`

## Single Session Mode

Single session mode usually used when you want to perform a single operation

```go
Find(&users)

  // lots of db operations
})

r. Get("/user", func(w http. Value("DB").(*gorm.DB)

  var user User
  db.
```

## Continuous session mode

Continuous session mode usually used when you want to perform a group of operations, for example:

```go
tx := db. WithContext(ctx)
tx. First(&user, 1)
tx. Model(&user). Update("role", "admin")
```

## Chi Middleware Example

Continuous session mode which might be helpful when handling API requests, for example, you can set up `*gorm.DB` with Timeout Context in middlewares, and then use the `*gorm.DB` when processing all requests

Following is a Chi middleware example:

```go
func SetDBMiddleware(next http. Handler) http. Handler {
  return http. HandlerFunc(func(w http. Request) {
    timeoutContext, _ := context. WithTimeout(context. Background(), time. Second)
    ctx := context. WithValue(r. Context(), "DB", db. WithContext(timeoutContext))
    next. ServeHTTP(w, r. WithContext(ctx))
  })
}

r := chi. NewRouter()
r. Use(SetDBMiddleware)

r. Get("/", func(w http. Value("DB").(*gorm.DB)

  var users []User
  db. Find(&users)

  // lots of db operations
})

r. Get("/user", func(w http. Value("DB").(*gorm.DB)

  var user User
  db. First(&user)

  // lots of db operations
})
```

{% note %}
**NOTE** Set `Context` with `WithContext` is goroutine-safe, refer [Session](session.html) for details
{% endnote %}

## Logger

Logger accepts `Context` too, you can use it for log tracking, refer [Logger](logger.html) for details
