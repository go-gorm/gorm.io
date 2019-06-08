---
title: Error Handling
layout: page
---

En Go, el manejo de errores es importante.

Se recomienda hacer una comprobación de errores después de cualquier [Métodos Inmediatos](/docs/method_chaining.html#Immediate-Methods)

## Manejo de Errores

Error handling in GORM is different than idiomatic Go code because of its chainable API, but still easy to implement.

If any error occurs, GORM will set `*gorm.DB`'s `Error` field, which you can check like this:

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
    // error handling...
}
```

Or

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
    // error handling...
}
```

## Errores

When processing data, it is common for multiple errors to occur. GORM provides an API to return all errors as a slice:

```go
// Si hay más de un error, `GetErrors` los devuelve como `[]error`
db.First(&user).Limit(10).Find(&users).GetErrors()

fmt.Println(len(errors))

for _, err := range errors {
  fmt.Println(err)
}
```

## Error RecordNotFound

GORM provides a shortcut to handle `RecordNotFound` errors. If there are several errors, it will check if any of them is a `RecordNotFound` error.

```go
// Comprueba si retorna un error RecordNotFound
db.Where("name = ?", "hello world").First(&user).RecordNotFound()

if db.Model(&user).Related(&credit_card).RecordNotFound() {
  // registro no encontrado
}

if err := db.Where("name = ?", "jinzhu").First(&user).Error; gorm.IsRecordNotFoundError(err) {
  // registro no encontrado
}
```
