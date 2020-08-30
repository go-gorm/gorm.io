---
title: Declaring Models
layout: page
---

## Declaring Models

모델은 기본 Go 유형, 포인터 / 별칭 또는 [Scanner](https://pkg.go.dev/database/sql/sql#Scanner) 및 [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) 인터페이스를 구현하는 사용자 정의 유형이있는 일반 구조체입니다.

예를 들면 다음과 같습니다:

```go
type User struct {
  ID           uint
  Name         string
  Email        *string
  Age          uint8
  Birthday     *time.Time
  MemberNumber sql.NullString
  ActivedAt    sql.NullTime
  CreatedAt    time.Time
  UpdatedAt    time.Time
}
```

## Conventions

GORM은 구성보다 규칙을 선호합니다. 기본적으로 GORM은 `ID`를 기본 키로 사용하고, 구조체/변수 이름을 `snake_cases`화 한것을 테이블/열 이름으로 사용하고, `CreatedAt`, `UpdatedAt`을 사용하여 생성 / 업데이트 시간을 추적합니다.

GORM에서 사용하는 규칙을 따르는 경우 구성/코드를 거의 작성하지 않아도됩니다. 규칙이 마음에 들지 않으면 [원하는 데로 구성할 수도 있습니다 ](conventions.html).

## gorm.Model

GORM은 `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt` 필드를 포함하는 `gorm.Model` 구조체를 정의합니다.

```go
// gorm.Model definition
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

해당 필드를 포함하도록 구조체를 만들 할 수 있습니다. [Embedded Struct를 참조하세요.](#embedded_struct)

## Advanced

### Field-Level Permission

일반적인 필드는 모든 권한을 가지지만 태그를 사용하여 필드의 권한을 read-only, write-only, create-only, update-only 또는 무시하도록 설정할 수 있습니다.

**NOTE** 무시한 필드는 GORM Migrator가 테이블에 추가하지 않습니다

```go
type User struct {
  Name string `gorm:"<-:create"` // 읽기/생성 허용
  Name string `gorm:"<-:update"` // 읽기/수정 허용
  Name string `gorm:"<-"`        // 읽기/쓰기 허용 생성 및 수정)
  Name string `gorm:"<-:false"`  // 읽기전용, 쓰기 불가능
  Name string `gorm:"->"`        // 읽기허용 (설정되지 않은경우 쓰기 불가능)
  Name string `gorm:"->;<-:create"` //읽기/생성 허용
  Name string `gorm:"->:false;<-:create"` // 생성만 가능 (읽기 불가능)
  Name string `gorm:"-"`  // gorm 에서 이 필드 무시
}
```

### <name id="time_tracking">Creating/Updating Time/Unix (Milli/Nano) Seconds Tracking</span>

GORM use `CreatedAt`, `UpdatedAt` to track creating/updating time by convention, and GORM will fill [current time](gorm_config.html#now_func) into it when creating/updating if they are defined

To use fields with a different name, you can configure those fields with tag `autoCreateTime`, `autoUpdateTime`

If you prefer to save UNIX (milli/nano) seconds instead of time, you can simply change the field's data type from `time.Time` to `int`

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updaing or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix nano seconds as updating time
  Updated   int64 `gorm:"autoUpdateTime:milli"`// Use unix milli seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

### <span id="embedded_struct">Embedded Struct</span>

For anonymous fields, GORM will include its fields into its parent struct, for example:

```go
type User struct {
  gorm.Model
  Name string
}
// equals
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
}
```

For a normal struct field, you can embed it with the tag `embedded`, for example:

```go
type Author struct {
    Name  string
    Email string
}

type Blog struct {
  ID      int
  Author  Author `gorm:"embedded"`
  Upvotes int32
}
// equals
type Blog struct {
  ID    int64
    Name  string
    Email string
  Upvotes  int32
}
```

And you can use tag `embeddedPrefix` to add prefix to embedded fields' db name, for example:

```go
type Blog struct {
  ID      int
  Author  Author `gorm:"embedded;embeddedPrefix:author_"`
  Upvotes int32
}
// equals
type Blog struct {
  ID          int64
    AuthorName  string
    AuthorEmail string
  Upvotes     int32
}
```


### <span id="tags">Fields Tags</span>

Tags are optional to use when declaring models, GORM supports the following tags: Tag name case doesn't matter, `camelCase` is preferred to use.

| Tag Name       | Description                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column         | column db name                                                                                                                                                                                                                                                                                                                                                                                                                                |
| type           | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, which works for all databases, and can be used with other tags together, like `not null`, `size`, `autoIncrement`... specified database data type like `varbinary(8)` also supported, when using specified database data type, it needs to be a full database data type, for example: `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| size           | specifies column data size/length, e.g: `size:256`                                                                                                                                                                                                                                                                                                                                                                                            |
| primaryKey     | specifies column as primary key                                                                                                                                                                                                                                                                                                                                                                                                               |
| unique         | specifies column as unique                                                                                                                                                                                                                                                                                                                                                                                                                    |
| default        | specifies column default value                                                                                                                                                                                                                                                                                                                                                                                                                |
| precision      | specifies column precision                                                                                                                                                                                                                                                                                                                                                                                                                    |
| scale          | specifies column scale                                                                                                                                                                                                                                                                                                                                                                                                                        |
| not null       | specifies column as NOT NULL                                                                                                                                                                                                                                                                                                                                                                                                                  |
| autoIncrement  | specifies column auto incrementable                                                                                                                                                                                                                                                                                                                                                                                                           |
| embedded       | embed the field                                                                                                                                                                                                                                                                                                                                                                                                                               |
| embeddedPrefix | column name prefix for embedded fields                                                                                                                                                                                                                                                                                                                                                                                                        |
| autoCreateTime | track current time when creating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoCreateTime:nano`                                                                                                                                                                                                                                                                         |
| autoUpdateTime | track current time when creating/updating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoUpdateTime:milli`                                                                                                                                                                                                                                                               |
| index          | create index with options, use same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                                                                                                                                                                                                                                                                                             |
| uniqueIndex    | same as `index`, but create uniqued index                                                                                                                                                                                                                                                                                                                                                                                                     |
| check          | creates check constraint, eg: `check:age > 13`, refer [Constraints](constraints.html)                                                                                                                                                                                                                                                                                                                                                      |
| <-             | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no write permission, `<-` create and update permission                                                                                                                                                                                                                                                                     |
| ->             | set field's read permission, `->:false` no read permission                                                                                                                                                                                                                                                                                                                                                                                 |
| -              | ignore this fields, `-` no read/write permission                                                                                                                                                                                                                                                                                                                                                                                              |

### Associations Tags

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
