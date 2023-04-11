---
title: GORM 설정
layout: page
---

GORM은 초기화 중에 Config를 사용할 수 있습니다.

```go
type Config struct {
  SkipDefaultTransaction   bool
  NamingStrategy           schema.Namer
  Logger                   logger.Interface
  NowFunc                  func() time.Time
  DryRun                   bool
  PrepareStmt              bool
  DisableNestedTransaction bool
  AllowGlobalUpdate        bool
  DisableAutomaticPing     bool
  DisableForeignKeyConstraintWhenMigrating bool
}
```

## SkipDefaultTransaction

GORM은 데이터 일관성을 보장하기 위해 트랜잭션 내에서 실행되는 쓰기(생성/갱신/삭제) 작업을 수행하며, 필요하지 않은 경우 초기화 중에 이 작업을 비활성화할 수 있습니다.

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  SkipDefaultTransaction: true,
})
```

## <span id="naming_strategy">NamingStrategy</span>

GORM을 사용하면 사용자가 `Namer` 인터페이스를 구현해야 하는 기본 `NamingStrategy`를 재정의하여 명명 규칙을 변경할 수 있습니다.

```go
type Namer interface {
    TableName(table string) string
    SchemaName(table string) string
    ColumnName(table, column string) string
    JoinTableName(table string) string
    RelationshipFKName(Relationship) string
    CheckerName(table, column string) string
    IndexName(table, column string) string
}
```

기본 `NamingStrategy`도 다음과 같은 몇 가지 옵션을 제공합니다:

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NamingStrategy: schema.NamingStrategy{
    TablePrefix: "t_",   // table name prefix, table for `User` would be `t_users`
    SingularTable: true, // use singular table name, table for `User` would be `user` with this option enabled
    NoLowerCase: true, // skip the snake_casing of names
    NameReplacer: strings.NewReplacer("CID", "Cid"), // use name replacer to change struct/field name before convert it to db name
  },
})
```

## Logger

이 옵션을 재정의하여 GORM의 기본 logger를 변경할 수 있으며, 자세한 내용은 [Logger](logger.html)를 참조하세요.

## <span id="now_func">NowFunc</span>

새 타임스탬프를 만들 때 사용할 함수를 변경할 수 있습니다.

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  NowFunc: func() time.Time {
    return time.Now().Local()
  },
})
```

## DryRun

실행하지 않고 `SQL`을 생성하면 생성된 SQL을 준비하거나 테스트하는 데 사용할 수 있으며, 자세한 내용은 [Session](session.html)을 참조하십시오.

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DryRun: false,
})
```

## PrepareStmt

`PreparedStmt`는 SQL을 실행할 때 prepared statement를 생성하고 향후 호출 속도를 높이기 위해 캐시합니다. 자세한 내용은 [Session](session.html)을 참조하세요.

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  PrepareStmt: false,
})
```

## DisableNestedTransaction

When using `Transaction` method inside a db transaction, GORM will use `SavePoint(savedPointName)`, `RollbackTo(savedPointName)` to give you the nested transaction support, you could disable it by using the `DisableNestedTransaction` option, refer [Session](session.html) for details


## AllowGlobalUpdate

Enable global update/delete, refer [Session](session.html) for details

## DisableAutomaticPing

GORM automatically ping database after initialized to check database availability, disable it by setting it to `true`

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableAutomaticPing: true,
})
```

## DisableForeignKeyConstraintWhenMigrating

GORM creates database foreign key constraints automatically when `AutoMigrate` or `CreateTable`, disable this by setting it to `true`, refer [Migration](migration.html) for details

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```
