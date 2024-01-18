---
title: Tratamento de Erro
layout: page
---

Effective error handling is a cornerstone of robust application development in Go, particularly when interacting with databases using GORM. GORM's approach to error handling, influenced by its chainable API, requires a nuanced understanding.

## Basic Error Handling

GORM integrates error handling into its chainable method syntax. The `*gorm.DB` instance contains an `Error` field, which is set when an error occurs. The common practice is to check this field after executing database operations, especially after [Finisher Methods](method_chaining.html#finisher_method).

After a chain of methods, it's crucial to check the `Error` field:

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
  // Handle error...
}
```

Or alternatively:

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
  // Handle error...
}
```

## `ErrRecordNotFound`

GORM returns `ErrRecordNotFound` when no record is found using methods like `First`, `Last`, `Take`.

```go
err := db.First(&user, 100).Error
if errors.Is(err, gorm.ErrRecordNotFound) {
  // Handle record not found error...
}
```

## Handling Error Codes

Many databases return errors with specific codes, which can be indicative of various issues like constraint violations, connection problems, or syntax errors. Handling these error codes in GORM requires parsing the error returned by the database and extracting the relevant code

- **Example: Handling MySQL Error Codes**

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

GORM can return specific errors related to the database dialect being used, when `TranslateError` is enabled, GORM converts database-specific errors into its own generalized errors.

```go
db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{TranslateError: true})
```

- **ErrDuplicatedKey**

This error occurs when an insert operation violates a unique constraint:

```go
result := db.Create(&newRecord)
if errors.Is(result.Error, gorm.ErrDuplicatedKey) {
    // Handle duplicated key error...
}
```

- **ErrForeignKeyViolated**

This error is encountered when a foreign key constraint is violated:

```go
result := db.Create(&newRecord)
if errors.Is(result.Error, gorm.ErrForeignKeyViolated) {
    // Handle foreign key violation error...
}
```

By enabling `TranslateError`, GORM provides a more unified way of handling errors across different databases, translating database-specific errors into common GORM error types.

## Errors

For a complete list of errors that GORM can return, refer to the [Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go) in GORM's documentation.
