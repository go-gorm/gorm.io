---
title: 方言的特殊类型
layout: page
---

## 创建新方言

GORM 官方支持以下几种方言：`sqlite`, `mysql`, `postgres`, `mssql`.

你可以通过创建一个新的方言来为其它数据库提供支持。 当你创建一个新方言的时候，你必须实现 [the dialect interface](https://godoc.org/github.com/jinzhu/gorm#Dialect) 接口。

某些数据库可能兼容 `mysql` 或 `postgres` 方言，此时你可以直接使用现有方言。

## 方言的特殊类型

某些 SQL 的方言包含特殊的、非标准的类型，比如 PostgreSQL 中的 `jsonb` 类型。 GORM 支持其中的几种类型，如下所示。

### PostgreSQL

GORM 支持加载以下 PostgreSQL 特有类型： - jsonb - hstore

Model 定义如下：

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

你可以这样使用 model:

```go
password := "0654857340"
metadata := json.RawMessage(`{"is_archived": 0}`)
sampleDoc := Document{
  Body: "This is a test document",
  Metadata: postgres.Jsonb{ metadata },
  Secrets: postgres.Hstore{"password": &password},
}

// 插入 sampleDoc 到数据库
db.Create(&sampleDoc)

// 取出记录，以确定记录是否正确插入
resultDoc := Document{}
db.Where("id = ?", sampleDoc.ID).First(&resultDoc)

metadataIsEqual := reflect.DeepEqual(resultDoc.Metadata, sampleDoc.Metadata)
secretsIsEqual := reflect.DeepEqual(resultDoc.Secrets, sampleDoc.Secrets)

// 应该输出 "true"
fmt.Println("Inserted fields are as expected:", metadataIsEqual && secretsIsEqual)
```