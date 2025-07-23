---
title: エラーハンドリング
layout: page
---

効果的なエラー処理は、特にGORMを使用してデータベースとやりとりする場合において、堅牢なGoアプリケーション開発の礎石です。 GORM's approach to error handling requires a nuanced understanding based on the API style you're using.

## 基本的なエラー処理

### Generics API

With the Generics API, errors are returned directly from the operation methods, following Go's standard error handling pattern:

```go
ctx := context.Background()

// Error handling with direct return values
user, err := gorm.G[User](db).Where("name = ?", "jinzhu").First(ctx)
if err != nil {
  // Handle error...
}

// For operations that don't return a result
err := gorm.G[User](db).Where("id = ?", 1).Delete(ctx)
if err != nil {
  // Handle error...
}
```

### Traditional API

With the Traditional API, GORM integrates error handling into its chainable method syntax. `*gorm.DB` インスタンスには `Error` フィールドが含まれており、エラーが発生したときに値が設定されます。 データベース操作の実行後、特に [Finisher Methods](method_chaining.html#finisher_method) の後に、このフィールドをチェックするのが一般的な手法です。

メソッドをチェーンしたあとに `Error` フィールドを確認することが重要です。

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
  // Handle error...
}
```

もしくは、

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
  // Handle error...
}
```

## `ErrRecordNotFound`

`First`, `Last`, `Take` などのメソッドを使用したときにレコードが見つからなかった場合、GORM は `ErrRecordNotFound` を返します。

### Generics API

```go
ctx := context.Background()

user, err := gorm.G[User](db).First(ctx)
if errors.Is(err, gorm.ErrRecordNotFound) {
  // Handle record not found error...
}
```

### Traditional API

```go
err := db.First(&user, 100).Error
if errors.Is(err, gorm.ErrRecordNotFound) {
  // Handle record not found error...
}
```

## エラーコードの対処

多くのデータベースでは、制約違反、接続の問題、構文エラーなどの問題を示すコードでエラーを返します。 Handling these error codes in GORM requires parsing the error returned by the database and extracting the relevant code.


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

## 方言を翻訳したエラー

GORMは使用されているSQL方言に関する特定のエラーを返すことができます。`TranslateError` が有効な場合、GORMはデータベース固有のエラーを独自に一般化したエラーに変換します。

```go
db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{TranslateError: true})
```

- **ErrDuplicatedKey**

このエラーは、レコード挿入操作がUNIQUE制約に違反した場合に発生します。

```go
result := db.Create(&newRecord)
if errors.Is(result.Error, gorm.ErrDuplicatedKey) {
    // Handle duplicated key error...
}
```

- **ErrForeignKeyViolated**

このエラーは外部キー制約に違反している場合に発生します。

```go
result := db.Create(&newRecord)
if errors.Is(result.Error, gorm.ErrForeignKeyViolated) {
    // Handle foreign key violation error...
}
```

`TranslateError` を有効にすることで、GORMはデータベース固有のエラーを一般的なGORMエラータイプに翻訳し、異なるデータベース間でより統一されたエラー処理方法を提供します。

## エラーの一覧

GORMが返すエラーの一覧については、GORMのドキュメントの [エラーリスト](https://github.com/go-gorm/gorm/blob/master/errors.go) を参照してください。
