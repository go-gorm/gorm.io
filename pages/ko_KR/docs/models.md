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

GORM은 `CreatedAt`, `UpdatedAt` 을 사용하여 규칙에 따라 생성/업데이트 시간을 추적하고 정의 된 경우 생성/업데이트시 [현재 시간](gorm_config.html#now_func)이 필드에 입력됩니다.

다른 이름의 필드를 사용하고 싶다면 `autoCreateTime`, `autoUpdateTime` 태그를 사용하세요.

만약 UnixTime(milli/nano)를 선호한다면 `time.Time` 대신에 `int`를 사용하세요.

```go
type User struct {
  CreatedAt time.Time // 생성시간을 기록합니다.
  UpdatedAt int       // 업데이트 시간을 UnixTime으로 기록합니다. (기본값:0)
  Updated   int64 `gorm:"autoUpdateTime:nano"` // 업데이트 시간을 UnixTime(nano)로 기록합니다.
  Updated   int64 `gorm:"autoUpdateTime:milli"`//업데이트 시간을 UnixTime(milli)로 기록합니다.
  Created   int64 `gorm:"autoCreateTime"`      // 생성시간을 UnixTime으로 기록합니다.
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

태그는 모델을 선언 할 때 사용할 수 있으며 GORM은 다음 태그들을 지원합니다. 태그의 대소문자는 중요하지 않으나 `camelCase `를 권장합니다.

| 태그 이름          | 설명                                                                                                                                                                                                                                                                                                               |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column         | column 이름                                                                                                                                                                                                                                                                                                        |
| type           | column 데이터 유형, 호환 가능한 일반 유형 (예: bool, int, uint, float, string, time, bytes)을 사용하는 것을 선호합니다. 이는 모든 데이터베이스에서 작동하며 `not null`, `size`, `autoIncrement`와 같은 태그들과 함께 사용할 수 있습니다.<br/> varbinary (8)과 같은 특정 데이터베이스의 데이터 유형도 지원됩니다. 단, 사용하게 된다면 전체 타입을 명시해주어야 합니다. 예: MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT |
| size           | column 크기/길이 지정, 예: `size:256`                                                                                                                                                                                                                                                                                   |
| primaryKey     | column을 primary key로 지정                                                                                                                                                                                                                                                                                          |
| unique         | column을 unique로 지정                                                                                                                                                                                                                                                                                               |
| default        | column의 기본값 지정                                                                                                                                                                                                                                                                                                   |
| precision      | specifies column precision                                                                                                                                                                                                                                                                                       |
| scale          | specifies column scale                                                                                                                                                                                                                                                                                           |
| not null       | column을 NOT NULL로 지정                                                                                                                                                                                                                                                                                             |
| autoIncrement  | column을 auto incrementable로 지정                                                                                                                                                                                                                                                                                   |
| embedded       | embed the field                                                                                                                                                                                                                                                                                                  |
| embeddedPrefix | column name prefix for embedded fields                                                                                                                                                                                                                                                                           |
| autoCreateTime | track current time when creating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoCreateTime:nano`                                                                                                                                            |
| autoUpdateTime | track current time when creating/updating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoUpdateTime:milli`                                                                                                                                  |
| index          | 옵션과 함께 index를 생성합니다. multiple fields creates composite indexes와 같은 이름들을 사용합니다. 자세한 사항은 [Indexes](indexes.html)를 참조하세요.                                                                                                                                                                                           |
| uniqueIndex    | `index`와 같으나, unique index로 지정함                                                                                                                                                                                                                                                                                  |
| check          | check constraint를 생성합니다. 예: `check:age > 13`, [Constraints](constraints.html) 를 확인하세요                                                                                                                                                                                                                         |
| <-             | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no write permission, `<-` create and update permission                                                                                                                                        |
| ->             | set field's read permission, `->:false` no read permission                                                                                                                                                                                                                                                    |
| -              | 해당필드 무시                                                                                                                                                                                                                                                                                                          |

### Associations Tags

GORM은 설정을 통해 통해 foreign keys, constraints, many2many 테이블을 구성 할 수 있습니다. 자세한 내용은[Associations](associations.html#tags)섹션을 확인하세요.
