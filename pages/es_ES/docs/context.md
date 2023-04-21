---
title: Context
layout: page
---

GORM proporciona soporte para `Context`, se puede utilizar con el método `WithContext`

## Modo de sesión única

El modo de sesión única se utiliza generalmente cuando se desea realizar una sola operación.

```go
db.WithContext(ctx).Find(&users)
```

## Modo de sesión continua

El modo de sesión continua se utiliza generalmente cuando se desea realizar un grupo de operaciones, por ejemplo:

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

## Tiempo de espera del Contexto

Puede pasar un contexto con un tiempo de espera a `db.WithContext` para establecer un tiempo de espera en las consultas de larga duración, por ejemplo:

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

db.WithContext(ctx).Find(&users)
```

## Contexto en Hooks/Callbacks

Puede acceder al objeto `Context` desde el `Statement` actual, por ejemplo:

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  ctx := tx.Statement.Context
  // ...
  return
}
```

## Ejemplo de Middleware Chi

El modo de sesión continua que puede ser útil al manejar solicitudes de API, por ejemplo, se puede configurar `*gorm.DB` con Contexto de Tiempo de espera en middlewares, y luego usar `*gorm.DB` en el procesamiento de todas las solicitudes.

El siguiente es un ejemplo de middleware Chi:

```go
func SetDBMiddleware(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    timeoutContext, _ := context.WithTimeout(context.Background(), time.Second)
    ctx := context.WithValue(r.Context(), "DB", db.WithContext(timeoutContext))
    next.ServeHTTP(w, r.WithContext(ctx))
  })
}

r := chi.NewRouter()
r.Use(SetDBMiddleware)

r.Get("/", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var users []User
  db.Find(&users)

  // lots of db operations
})

r.Get("/user", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var user User
  db.First(&user)

  // lots of db operations
})
```

{% note %}
**NOTA** Establecer `Context` con `WithContext` es seguro para gorutinas, consulte [Session](session.html) para obtener detalles.
{% endnote %}

## Logger

Logger acepta `Contexto` también, puedes usarlo para el seguimiento de registros, consulta [Logger](logger.html) para más detalles
