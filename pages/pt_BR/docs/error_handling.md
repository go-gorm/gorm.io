---
title: Tratamento de Erro
layout: page
---

Manipular os erros corretamente é um pilar no desenvolvimento de aplicações robustas em GO, particularmente quando estamos interagindo com banco de dados usando GORM. A abordagem de como manipular erros em GORM, influenciado pela sua chamada encadeada da API, necessita uma abordagem diferenciada.

## Manipulação básica de erros

GORM integrates error handling into its chainable method syntax. The `*gorm.DB` instance contains an `Error` field, which is set when an error occurs. The common practice is to check this field after executing database operations, especially after [Finisher Methods](method_chaining.html#finisher_method).

Depois de uma cadeia de métodos, é crucial verificar o campo `Error`:

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
  // Handle error...
}
```

Ou alternativamente:

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
  // Handle error...
}
```

## `ErrRecordNotFound`

GORM retorna `ErrRecordNotFound` quando nenhum registro é encontrado quando métodos como `First`, `Last`, `Take` são utilizados.

```go
err := db.First(&user, 100).Error
if errors.Is(err, gorm.ErrRecordNotFound) {
  // Handle record not found error...
}
```

## Handling Error Codes

Muitos bancos de dados retornam erros com códigos específicos, que podem indicar várias categorias de problemas como violação de constraints, problemas de conexão, ou erros de sintaxe. Manipular esses códigos de erro no GORM requer análise do erro retornado pelo banco de dados e extrair o código relevante

- **Exemplo: Manipulando Códigos de Erro do MySQL**

```go
import (
    "github.com/go-sql-driver/mysql"
    "gorm.io/gorm"
)

// ...

result := db.Create(&newRecord)
if result.Error != nil {
    if mysqlErr, ok := result.Error.(*mysql.MySQLError); ok {
        switch mysqlErr.Number {
        case 1062: // MySQL code for duplicate entry
            // Handle duplicate entry
        // Add cases for other specific error codes
        default:
            // Handle other errors
        }
    } else {
        // Handle non-MySQL errors or unknown errors
    }
}
```

## Dialect Translated Errors

GORM pode retornar erros específicos relacionados ao dialeto do banco de dados, quando `TranslateError` está ativo, GORM converto os erros específicos do banco de dados para seu próprio tipo generalizado de erro.

```go
db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{TranslateError: true})
```

- **ErrDuplicatedKey**

Esse erro acontece quando uma operação de insert viola uma unique constraint:

```go
result := db.Create(&newRecord)
if errors.Is(result.Error, gorm.ErrDuplicatedKey) {
    // Handle duplicated key error...
}
```

- **ErrForeignKeyViolated**

Esse erro é encontrado quando uma chave estrangeira é violada:

```go
result := db.Create(&newRecord)
if errors.Is(result.Error, gorm.ErrForeignKeyViolated) {
    // Handle foreign key violation error...
}
```

Habilitando `TranslateError`, GORM fornece uma maneira mais unificada de manipular os erros em diversos tipos de bancos de dados, traduzindo erros específicos de banco de dados para erros que pertencem ao GORM.

## Errors

Para uma lista completa de erros que o GORM pode retornar, verifique a documentação GORM em [Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go).
