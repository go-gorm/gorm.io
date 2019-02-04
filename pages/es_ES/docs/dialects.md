---
title: Dialect Specific Data Type
layout: page
---
## Escribir Nuevo Dialecto

GORM provides official support for `sqlite`, `mysql`, `postgres`, `mssql`.

You can add support for additional databases by creating a new dialect. When creating a new dialect, you must implement [the dialect interface](https://godoc.org/github.com/jinzhu/gorm#Dialect).

Some databases may be compatible with the `mysql` or `postgres` dialect, in which case you could just use the dialect for those databases.

## Tipo de Dato Específico de Dialecto

Ciertos dialectos de SQL se envían con sus propios tipos de columna personalizados, no estándar, como la columna `jsonb` en PostgreSQL. GORM supports loading several of these types, as listed in the following sections.

### PostgreSQL

GORM admite la carga de los siguientes tipos de columnas exclusivas de PostgreSQL: -jsonb -hstore

Dada la siguiente definición de modelo:

```go
import (
    "encoding/json"
    "github.com/jinzhu/gorm/dialects/postgres"
)

type Document struct {
    Metadata postgres.Jsonb
    Secrets  postgres.Hstore
    Body     string
    ID       int
}
```

Puede utilizar el modelo de la siguiente forma:

```go
password := "0654857340" metadata := json.RawMessage(`{"is_archived": 0}`) sampleDoc := Document{   Body: "This is a test document",   Metadata: postgres.Jsonb{ metadata },   Secrets: postgres.Hstore{"password": &password}, } //inserta sampleDoc en la base de datos db.Create(&sampleDoc) //recuperar los datos nuevamente para confirmar si se insertaron correctamente resultDoc := Document{} db.Where("id = ?", sampleDoc.ID).First(&resultDoc) metadataIsEqual := reflect.DeepEqual(resultDoc.Metadata, sampleDoc.Metadata) secretsIsEqual := reflect.DeepEqual(resultDoc.Secrets, resultDoc.Secrets) // esto debería imprimir "verdadero" fmt.Println("Inserted fields are as expected:", metadataIsEqual && secretsIsEqual)
```