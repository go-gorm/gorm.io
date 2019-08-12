---
title: 特殊数据类型方言
layout: page
---

## 完成新的方言

GORM 官方支持以下几种方言：`sqlite`, `mysql`, `postgres`, `mssql`.

你可以通过创建一个新的方言来为其它数据库提供支持。 当你创建一个新方言的时候，你必须实现 [the dialect interface](https://godoc.org/github.com/jinzhu/gorm#Dialect) 接口。

Some databases may be compatible with the `mysql` or `postgres` dialect, in which case you could just use the dialect for those databases.

## Dialect Specific Data Type

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