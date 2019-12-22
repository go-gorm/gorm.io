---
title: Тип данных Диалект
layout: страница
---

## Создать новый диалект

GORM предоставляет официальную поддержку `sqlite`, `mysql`, `postgres`, `mssql`.

Вы можете добавить поддержку дополнительных баз данных, создав новый диалект. При создании нового диалекта необходимо применить [интерфейс диалекта](https://godoc.org/github.com/jinzhu/gorm#Dialect).

Некоторые базы данных могут быть совместимы с `mysql` или `postgres` диалектом, в этом случае вы можете просто использовать диалект для этих баз данных.

## Тип данных Диалект

Некоторые диалекты SQL с собственными пользовательскими, нестандартными типами столбцов, такими как `jsonb` столбец в PostgreSQL. GORM поддерживает загрузку нескольких типов, как указано в следующих разделах.

### PostgreSQL

GORM поддерживает загрузку следующих типов эксклюзивных столбцов PostgreSQL: - jsonb - hstore

С учетом следующего определения модели:

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

Вы можете использовать такую модель:

```go
password := "0654857340"
metadata := json.RawMessage(`{"is_archived": 0}`)
sampleDoc := Document{
  Body: "This is a test document",
  Metadata: postgres.Jsonb{ metadata },
  Secrets: postgres.Hstore{"password": &password},
}

//добавить sampleDoc в базу данных
db.Create(&sampleDoc)

//получить поля снова для подтверждения корекности
resultDoc := Document{}
db.Where("id = ?", sampleDoc.ID).First(&resultDoc)

metadataIsEqual := reflect.DeepEqual(resultDoc.Metadata, sampleDoc.Metadata)
secretsIsEqual := reflect.DeepEqual(resultDoc.Secrets, sampleDoc.Secrets)

// должно вывести "true"
fmt.Println("Inserted fields are as expected:", metadataIsEqual && secretsIsEqual)
```