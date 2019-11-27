---
title: Logger
layout: page
---

## Logger

Gorm tiene soporte de logger incorporado, de manera predeterminada, solo imprimirá registros cuando ocurran errores.

```go
// Habilitar Logger, muestra log detallado
db.LogMode(true)

// Deshabilitar Logger, no muestra ningún log nisiquera errores
db.LogMode(false)

// Depurar una sola operación, muestra log detallado para esta operación
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## Personalizar Logger

Consulte logger predeterminado de GORM para aprender como personalizarlo <https://github.com/jinzhu/gorm/blob/master/logger.go>

Por ejemplo, usando el logger de [Revel](https://revel.github.io/) como backend para GORM

```go
db.SetLogger(gorm.Logger{revel.TRACE})
```

Usando `os.Stdout` como backend

```go
db.SetLogger(log.New(os.Stdout, "\r\n", 0))
```