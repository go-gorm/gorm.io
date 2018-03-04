---
title: Dialect Specific Data Type
layout: page
---
## Escribir Nuevo Dialecto

Gorm proporciona soporte para sqlite, mysql, postgres, mssql oficialmente.

Puede agregar otro soporte de base de datos creando un nuevo dialecto, necesita implementar [la interfaz del dialecto](https://godoc.org/github.com/jinzhu/gorm#Dialect).

Algunas bases de datos pueden ser compatibles con el dialecto mysql o postgres, entonces usted podría usar el dialecto para esas bases de datos.

## Tipo de Dato Específico de Dialecto

Ciertos dialectos de SQL se envían con sus propios tipos de columna personalizados, no estándar, como la columna `jsonb` en PostgreSQL. GORM admite la carga de varios de estos tipos, como se detalla en las siguientes secciones.

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