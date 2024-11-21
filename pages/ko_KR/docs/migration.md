---
title: 마이그레이션
layout: 페이지
---

## 자동 마이그레이션

스키마를 자동으로 마이그레이션하여 스키마를 최신 상태로 유지하세요.

{% note warn %}
**참고:** 자동 마이그레이션은 테이블, 누락된 외래 키, 제약 조건, 열 및 인덱스를 생성합니다. 기존 열의 크기, 정밀도가 변경되거나 null이 아닌 열에서 null로 변경되는 경우 기존 열의 유형을 변경합니다. 데이터를 보호하기 위해 사용하지 않는 열을  **삭제하지 않습니다.**
{% endnote %}

```go
db.AutoMigrate(&User{})

db.AutoMigrate(&User{}, &Product{}, &Order{})

// 테이블 생성 시 테이블 접미사(Suffix) 추가
db.Set("gorm:table_options", "ENGINE=InnoDB").AutoMigrate(&User{})

```

{% note warn %}
**참고:** 데이터베이스의 외래 키 제약 조건을 자동으로 생성합니다. 이 기능은 초기화 시 비활성화할 수 있습니다. 예를 들어
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  DisableForeignKeyConstraintWhenMigrating: true,
})
```

## 마이그레이션 인터페이스

GORM은 각 데이터베이스에 대해 통합된 API 인터페이스를 포함하는 마이그레이터 인터페이스를 제공하며, 이를 사용해 데이터베이스에 종속되지 않는 마이그레이션을 구축할 수 있습니다. 예를 들어:

SQLite는 ALTER COLUMN, DROP COLUMN을 지원하지 않으므로, GORM은 변경하려는 테이블과 동일한 새 테이블을 생성한 다음 모든 데이터를 복사하고, 기존 테이블을 삭제한 후 새 테이블의 이름을 변경합니다.

MySQL은 일부 버전에서 컬럼이나 인덱스 이름 변경을 지원하지 않으므로, GORM은 사용하는 MySQL 버전에 따라 다른 SQL을 수행합니다.

```go
type Migrator interface {
  // AutoMigrate
  AutoMigrate(dst ...interface{}) error

  // Database
  CurrentDatabase() string
  FullDataTypeOf(*schema.Field) clause.Expr

  // Tables
  CreateTable(dst ...interface{}) error
  DropTable(dst ...interface{}) error
  HasTable(dst interface{}) bool
  RenameTable(oldName, newName interface{}) error
  GetTables() (tableList []string, err error)

  // Columns
  AddColumn(dst interface{}, field string) error
  DropColumn(dst interface{}, field string) error
  AlterColumn(dst interface{}, field string) error
  MigrateColumn(dst interface{}, field *schema.Field, columnType ColumnType) error
  HasColumn(dst interface{}, field string) bool
  RenameColumn(dst interface{}, oldName, field string) error
  ColumnTypes(dst interface{}) ([]ColumnType, error)

  // Views
  CreateView(name string, option ViewOption) error
  DropView(name string) error

  // Constraints
  CreateConstraint(dst interface{}, name string) error
  DropConstraint(dst interface{}, name string) error
  HasConstraint(dst interface{}, name string) bool

  // Indexes
  CreateIndex(dst interface{}, name string) error
  DropIndex(dst interface{}, name string) error
  HasIndex(dst interface{}, name string) bool
  RenameIndex(dst interface{}, oldName, newName string) error
}
```

### 현재 데이터베이스

데이터베이스 이름을 사용하여 현재를 반환합니다.

```go
db.Migrator().CurrentDatabase()
```

### 테이블들

```go
// Create table for `User`
db.Migrator().CreateTable(&User{})

// Append "ENGINE=InnoDB" to the creating table SQL for `User`
db.Set("gorm:table_options", "ENGINE=InnoDB").Migrator().CreateTable(&User{})

// Check table for `User` exists or not
db.Migrator().HasTable(&User{})
db.Migrator().HasTable("users")

// Drop table if exists (will ignore or delete foreign key constraints when dropping)
db.Migrator().DropTable(&User{})
db.Migrator().DropTable("users")

// Rename old table to new table
db.Migrator().RenameTable(&User{}, &UserInfo{})
db.Migrator().RenameTable("users", "user_infos")
```

### 열들 (Columns)

```go
type User struct {
  Name string
}

// Add name field
db.Migrator().AddColumn(&User{}, "Name")
// Drop name field
db.Migrator().DropColumn(&User{}, "Name")
// Alter name field
db.Migrator().AlterColumn(&User{}, "Name")
// Check column exists
db.Migrator().HasColumn(&User{}, "Name")

type User struct {
  Name    string
  NewName string
}

// Rename column to new name
db.Migrator().RenameColumn(&User{}, "Name", "NewName")
db.Migrator().RenameColumn(&User{}, "name", "new_name")

// ColumnTypes
db.Migrator().ColumnTypes(&User{}) ([]gorm.ColumnType, error)

type ColumnType interface {
    Name() string
    DatabaseTypeName() string                 // varchar
    ColumnType() (columnType string, ok bool) // varchar(64)
    PrimaryKey() (isPrimaryKey bool, ok bool)
    AutoIncrement() (isAutoIncrement bool, ok bool)
    Length() (length int64, ok bool)
    DecimalSize() (precision int64, scale int64, ok bool)
    Nullable() (nullable bool, ok bool)
    Unique() (unique bool, ok bool)
    ScanType() reflect.Type
    Comment() (value string, ok bool)
    DefaultValue() (value string, ok bool)
}
```

### 뷰 (Views)

`ViewOption`을 사용하여 뷰를 생성합니다. `View Option`에 대한 설명은 다음과 같습니다.

- `쿼리(Query)`는 필수적인  [서브쿼리(subquery)입니다.](https://gorm.io/docs/advanced_query.html#SubQuery)
- 만약 `리플레이스(Replace)`가 true이면 `CREATE OR REPLACE`를 실행하고, 그렇지 않으면 `CREATE`를 실행합니다.
- 만약 `CheckOption`이 비어 있지 않다면 SQL을 추가하게 됩니다. 예를 들어  `WITH LOCAL CHECK OPTION`과 같이 사용됩니다.

{% note warn %}
**참고:** SQLite는 현재 `ViewOption`에서 리플레이스(Replace)</code>를 지원하지 않습니다.
{% endnote %}

```go
query := db.Model(&User{}).Where("age > ?", 20)

// Create View
db.Migrator().CreateView("users_pets", gorm.ViewOption{Query: query})
// CREATE VIEW `users_view` AS SELECT * FROM `users` WHERE age > 20

// Create or Replace View
db.Migrator().CreateView("users_pets", gorm.ViewOption{Query: query, Replace: true})
// CREATE OR REPLACE VIEW `users_pets` AS SELECT * FROM `users` WHERE age > 20

// Create View With Check Option
db.Migrator().CreateView("users_pets", gorm.ViewOption{Query: query, CheckOption: "WITH CHECK OPTION"})
// CREATE VIEW `users_pets` AS SELECT * FROM `users` WHERE age > 20 WITH CHECK OPTION

// Drop View
db.Migrator().DropView("users_pets")
// DROP VIEW IF EXISTS "users_pets"
```

### 제약 조건(Constraints)

```go
type UserIndex struct {
  Name  string `gorm:"check:name_checker,name <> 'jinzhu'"`
}

// 제약 조건을 생성합니다.
db.Migrator().CreateConstraint(&User{}, "name_checker")

// 제약 조건을 삭제합니다.
db.Migrator().DropConstraint(&User{}, "name_checker")

// 제약 조건이 있는지 확인합니다.
db.Migrator().HasConstraint(&User{}, "name_checker")
```

관계에 대한 외래 키 만들기

```go
type User struct {
  gorm.Model
  CreditCards []CreditCard
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}

// 사용자 및 신용카드에 대한 외래 키 생성
db.Migrator().CreateConstraint(&User{}, "CreditCards")
db.Migrator().CreateConstraint(&User{}, "fk_users_credit_cards")
// credit_cards 테이블에 fk_users_credit_cards 외래 키 제약 조건 추가
// ALTER TABLE `credit_cards` ADD CONSTRAINT `fk_users_credit_cards` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)

// 사용자 및 신용카드에 대한 외래 키가 존재하는지 확인
db.Migrator().HasConstraint(&User{}, "CreditCards")
db.Migrator().HasConstraint(&User{}, "fk_users_credit_cards")

// 사용자 및 신용카드에 대한 외래 키 삭제
db.Migrator().DropConstraint(&User{}, "CreditCards")
db.Migrator().DropConstraint(&User{}, "fk_users_credit_cards")
```

### 인덱스 (Indexes)

```go
type User struct {
  gorm.Model
  Name string `gorm:"size:255;index:idx_name,unique"`
}

// Name 필드에 대한 인덱스 생성
db.Migrator().CreateIndex(&User{}, "Name")
db.Migrator().CreateIndex(&User{}, "idx_name")

// Name 필드에 대한 인덱스 삭제
db.Migrator().DropIndex(&User{}, "Name")
db.Migrator().DropIndex(&User{}, "idx_name")

// 인덱스 존재 여부 확인
db.Migrator().HasIndex(&User{}, "Name")
db.Migrator().HasIndex(&User{}, "idx_name")

type User struct {
  gorm.Model
  Name  string `gorm:"size:255;index:idx_name,unique"`
  Name2 string `gorm:"size:255;index:idx_name_2,unique"`
}

// 인덱스 이름 변경
db.Migrator().RenameIndex(&User{}, "Name", "Name2")
db.Migrator().RenameIndex(&User{}, "idx_name", "idx_name_2")

```

## 제약 조건

GORM은 자동 마이그레이션이나 테이블 생성 시 제약 조건을 생성합니다. 자세한 내용은 [제약 조건](constraints.html) 또는 [데이터베이스 인덱스](indexes.html)를 참조하세요."

## 아틀라스 통합 (Atlas Integration)

[Atlas](https://atlasgo.io)는 GORM과 공식적으로 통합된 오픈 소스 데이터베이스 마이그레이션 도구입니다.

GORM의 `AutoMigrate` 기능은 대부분의 경우에 작동하지만, 언젠가는 [버전 관리 마이그레이션](https://atlasgo.io/concepts/declarative-vs-versioned#versioned-migrations) 전략으로 전환해야 할 수도 있습니다.

이럴 경우, 마이그레이션 스크립트를 계획하고 GORM이 런타임에 기대하는 것과 일치하도록 하는 책임은 개발자에게 넘어갑니다.

Atlas는 공식 [GORM Provider](https://github.com/ariga/atlas-provider-gorm)를 사용하여 개발자를 위한 데이터베이스 스키마 마이그레이션을 자동으로 계획할 수 있습니다.  공급자(Provider)를 구성한 후에는 실행하여 마이그레이션을 자동으로 계획할 수 있습니다:
```bash
atlas migrate diff --env gorm
```

GORM과 함께 Atlas를 사용하는 방법을 배우려면 [공식 문서](https://atlasgo.io/guides/orms/gorm)를 확인하세요.



## 기타 마이그레이션 도구

GORM을 다른 Go 기반 마이그레이션 도구와 함께 사용하려면, GORM은 여러분에게 유용할 수 있는 일반 DB 인터페이스를 제공합니다.

```go
// returns `*sql.DB`
db.DB()
```

자세한 내용은 [일반 인터페이스](generic_interface.html)를 참조하세요.
