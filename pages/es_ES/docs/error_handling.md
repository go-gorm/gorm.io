---
title: Error Handling
layout: page
---
En Go, el manejo de errores es importante.

Se recomienda hacer una comprobación de errores después de cualquier [Métodos Inmediatos](/docs/method_chaining.html#Immediate-Methods)

## Manejo de Errores

El manejo de errores en GORM es diferente con el código Go idiomático debido a su API, pero todavía es bastante fácil hacerlo.

If there are any error happened, GORm will set it to `*gorm.DB`'s `Error` field, you could check it like this:

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

## Errors

It is common several errors happend during processing data, GORM provides an API to return all happened errors as a slice

```go
// If there are more than one error happened, `GetErrors` returns them as `[]error`
db.First(&user).Limit(10).Find(&users).GetErrors()

fmt.Println(len(errors))

for _, err := range errors {
  fmt.Println(err)
}
```

## RecordNotFound Error

GORM provides a shortcut to handle `RecordNotFound` error, if there are several errors happened, it will check each error if any of them is `RecordNotFound` error.

```go
// Check if returns RecordNotFound error
db.Where("name = ?", "hello world").First(&user).RecordNotFound()

if db.Model(&user).Related(&credit_card).RecordNotFound() {
  // record not found
}

if err := db.Where("name = ?", "jinzhu").First(&user).Error; gorm.IsRecordNotFoundError(err) {
  // record not found
}
```