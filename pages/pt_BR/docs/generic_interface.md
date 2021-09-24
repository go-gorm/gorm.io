---
title: Interface genérica de banco de dados sql.DB
layout: page
---

O GORM fornece o método `DB` que retorna uma interface genérica do [\*sql.DB](https://pkg.go.dev/database/sql#DB) do banco de dados `*gorm.DB`

```go
// Obter objeto genérico de banco de dados sql.DB para ser usado nas funções
db.DB()

// Ping
db.DB().Ping()
```

{% note warn %}
**NOTA** Se a conexão do banco de dados em questão não for um `*sql.DB`, como em uma transação, será retornado um erro
{% endnote %}

## Pool de conexões

```go
// Obter objeto genérico banco de dados objeto sql.DB para usar nas suas funções
sqlDB, err := db.DB()

// SetMaxIdleConns define o número máximo de conexões ociosas no pool de conexão.
sqlDB.SetMaxIdleConns(10)

// SetMaxOpenConns define o número máximo de conexões abertas para o banco de dados.
sqlDB.SetMaxOpenConns(100)

// SetConnMaxLifetime define o tempo máximo que uma conexão pode estar ativa para pode ser reutilizada.
sqlDB.SetConnMaxLifetime(time.Hour)
```
