---
title: Logger
layout: page
---

## Logger

Gorm ha un logger incorporato, che per impostazioni predefinite, stamperà i registri solo quando si verificherà un errore.

```go
// Abilità il Logger, mostra i registri dettagliati
db.LogMode(true)

// Disabilita il Logger, non mostrare nessun registro di errore
db.LogMode(false)

// Fai il debug su una singola operazione, 
// mostra un registro dettagliato per quella operazione
db.Debug().Where("name = ?", "jinzhu").First(&User{})
```

## Personalizza il Logger

Consulta <https://github.com/jinzhu/gorm/blob/master/logger.go> per scoprire come personalizzare il logger predefinito di GORM

Per esempio, usa [Revel](https://revel.github.io/) come Logger per il backend di GORM

```go
db.SetLogger(gorm.Logger{revel.TRACE})
```

Usando invece `os.Stdout` come backend

```go
db.SetLogger(log.New(os.Stdout, "\r\n", 0))
```