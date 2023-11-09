---
title: Tratamento de Erro
layout: page
---

O tratamento de erros em Go é importante.

Você é encorajado a fazer uma verificação de erro após qualquer [Método Finalizador](method_chaining.html#finisher_method)

## Tratamento de Erro

O tratamento de erro no GORM é diferente do código Go mais idiomático, porque usa a API de encadeamento (chainable) de métodos.

Se ocorrer algum erro, o GORM definirá o campo `Error` do `*gorm.DB`, que deve ser verificado da seguinte forma:

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
  // tratamento de erros...
}
```

}

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
  // erro ao lidar...
}
```

{% note warn %}
## Dialect Translated Errors

If you would like to be able to use the dialect translated errors(like ErrDuplicatedKey), then enable the `TranslateError` flag when opening a db connection.

```go
db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{TranslateError: true})
```
{% endnote %}


## ErrRecordNotFound

GORM returns `ErrRecordNotFound` when failed to find data with `First`, `Last`, `Take` (only when dialect translated errors are enabled). If there are several errors happened, you can check the `ErrRecordNotFound` error with `errors.Is`. For example,

```go
// Check if returns RecordNotFound error
err := db.First(&user, 100).Error
errors.Is(err, gorm.ErrRecordNotFound)
```
## Errors

[Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go)
