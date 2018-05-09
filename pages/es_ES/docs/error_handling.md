---
title: Error Handling
layout: page
---
En Go, el manejo de errores es importante.

Se recomienda hacer una comprobación de errores después de cualquier [Métodos Inmediatos](/docs/method_chaining.html#Immediate-Methods)

## Manejo de Errores

El manejo de errores en GORM es diferente con el código Go idiomático debido a su API, pero todavía es bastante fácil hacerlo.

If there are any error happened, GORM will set it to `*gorm.DB`'s `Error` field, you could check it like this:

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

Es común que se hayan producido varios errores durante el procesamiento de datos, GORM proporciona una API para devolver todos los errores pasados como un segmento

```go
// Si hay más de un error, `GetErrors` los devuelve como `[]error` db.First(&user).Limit(10).Find(&users).GetErrors() fmt.Println(len(errors)) for _, err := range errors {   fmt.Println(err) }
```

## Error RecordNotFound

GORM proporciona un acceso directo para manejar el error `RecordNotFound`, si se producen varios errores, comprobará cada error por si alguno de ellos es el error `RecordNotFound`.

```go
// Comprueba si retorna un error RecordNotFound db.Where("name = ?", "hello world").First(&user).RecordNotFound() if db.Model(&user).Related(&credit_card).RecordNotFound() {   // registro no encontrado } if err := db.Where("name = ?", "jinzhu").First(&user).Error; gorm.IsRecordNotFoundError(err) {   // registro no encontrado }
```