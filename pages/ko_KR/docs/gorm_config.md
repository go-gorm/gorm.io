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
    TablePrefix: "t_",   // 테이블명의 접두사를 지정합니다. 예시로, User를 테이블명으로 변환할 때 t_users로 변환합니다. 
    SingularTable: true, // 단수형 테이블명을 사용합니다. 기본적으로 GORM은 복수형 테이블명 규칙이 적용되는데 true로 설정하면 구조체 이름 그대로 테이블명을 생성합니다.
    NoLowerCase: true, // 소문자와 언더스코어를 사용한 스네이크 표기를 사용하지 않고, 구조체의 필드명을 그대로 사용합니다.
    NameReplacer: strings.NewReplacer("CID", "Cid"), // 구조체의 필드 이름을 DB에 넣기 전에 변환하여 테이블/열 이름으로 매핑합니다. 예시로 문자열 CID를 Cid로 변경하여 넣는다는 예시입니다.
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

Db 트랜잭션 내부에서 또 다른 트랜잭션을 시작할 때, GORM은 중첩 트랜잭션을 지원하기 위해서 SavePoint와 RollbackTo 메서드를 사용합니다. DisableNestedTransaction 옵션을 이용하여 비활성화할 수 있으며, 자세한 내용은 Session을 참고하세요.


## AllowGlobalUpdate

Enable global update/delete, refer [Session](session.html) for details

## DisableAutomaticPing

GORM은 초기화 후에 데이터베이스와의 연결 상태를 확인하기 위해 기본적으로 Ping을 요청합니다. 그러나 자주 변경하지 않아 기본적인 Ping 요청을 제거하거나, 자원 소모나 부하를 줄이기 위해 이 기능을 비활성화할 수 있습니다. 또한 개발자가 직접 데이터베이스 연결 상태를 통제하고자 할 때, 필요한 시점에만 Ping을 보내도록 이 옵션을 활용할 수 있습니다.

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
