---
title: Jenis Data Spesifik Dialek
layout: page
---
## Tulis Dialek baru

GORM menyediakan dukungan untuk sqlite, mysql, postgres, mssql secara resmi.

Anda bisa menambahkan dukungan database lainnya dengan membuat dialek baru, perlu diimplementasikan [antarmuka dialek](https://godoc.org/github.com/jinzhu/gorm#Dialect).

Beberapa database mungkin kompatibel dengan dialek mysql atau postgres, maka anda bisa menggunakan dialek untuk database tersebut.

## Dialect Specific Data Type

Dialek tertentu dari mengirimkan SQL dengan kebiasaan mereka sendiri, jenis kolom bukan-standar, seperti kolom `jsonb` dalam PostgreSQL. GORM mendukung pemuatan beberapa tipe seperti itu, seperti yang tercantum di bagian berikut.

### PostgreSQL

GORM mendukung pemuatan jenis kolom khusus PostgreSQL berikut: - jsonb - hstore

Diberikan definisi Model berikut:

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

Kamu bisa menggunakan model seperti:

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
secretsIsEqual := reflect.DeepEqual(resultDoc.Secrets, resultDoc.Secrets)

// this should print "true"
fmt.Println("Inserted fields are as expected:", metadataIsEqual && secretsIsEqual)
```