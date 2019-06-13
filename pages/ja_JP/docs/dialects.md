---
title: Dialect Specific Data Type
layout: page
---

## 新しい方言を書く

GORM provides official support for `sqlite`, `mysql`, `postgres`, `mssql`.

You can add support for additional databases by creating a new dialect. When creating a new dialect, you must implement [the dialect interface](https://godoc.org/github.com/jinzhu/gorm#Dialect).

Some databases may be compatible with the `mysql` or `postgres` dialect, in which case you could just use the dialect for those databases.

## 方言に特化したデータ型

Certain dialects of SQL ship with their own custom, non-standard column types, such as the `jsonb` column in PostgreSQL. GORM supports loading several of these types, as listed in the following sections.

### PostgreSQL

GORM supports loading the following PostgreSQL exclusive column types: - jsonb - hstore

Given the following Model definition:

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

You may use the model like so:

```go
password := "0654857340"
metadata := json.RawMessage(`{"is_archived": 0}`)
sampleDoc := Document{
  Body: "This is a test document",
  Metadata: postgres.Jsonb{ metadata },
  Secrets: postgres.Hstore{"password": &password},
}

//insert sampleDoc into the database
db.Create(&sampleDoc)

//retrieve the fields again to confirm if they were inserted correctly
resultDoc := Document{}
db.Where("id = ?", sampleDoc.ID).First(&resultDoc)

metadataIsEqual := reflect.DeepEqual(resultDoc.Metadata, sampleDoc.Metadata)
secretsIsEqual := reflect.DeepEqual(resultDoc.Secrets, sampleDoc.Secrets)

// this should print "true"
fmt.Println("Inserted fields are as expected:", metadataIsEqual && secretsIsEqual)
```