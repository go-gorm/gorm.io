---
title: 모델 선언
layout: page
---

## 모델 선언

모델은 기본 Go 유형, 포인터/별칭 또는 [Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner)및 [Valuer](https://pkg.go.dev/database/sql/driver#Valuer)인터페이스를 구현하는 사용자 정의 유형이 있는 일반 구조체입니다.

예를 들면 다음과 같습니다:

```go
type User struct {
  ID           uint
  Name         string
  Email        *string
  Age          uint8
  Birthday     *time.Time
  MemberNumber sql.NullString
  ActivatedAt  sql.NullTime
  CreatedAt    time.Time
  UpdatedAt    time.Time
}
```

## 규칙

GORM은 구성보다 규칙을 선호합니다. 기본적으로 GORM은 `ID`를 기본 키로 사용하고, 복수형 `snake_cases`를 구조체 이름을 테이블 이름으로, `snake_case`를 열 이름으로, 생성/업데이트 시간을 추적하기 위해 `CreatedAt`, `UpdatedAt`을 사용합니다.

GORM에서 채택한 규칙을 따르는 경우 구성/코드를 거의 작성하지 않아도 됩니다. 규칙이 요구 사항과 일치하지 않는 경우 [GORM을 사용하여 규칙을 구성할 수 있습니다.](conventions.html)

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

해당 필드를 포함하도록 구조체를 만들 할 수 있습니다. [Embedded Struct](#embedded_struct)를 참조하세요.

## 고급

### <span id="field_permission">필드 수준 권한</span>

Exported fields have all permissions when doing CRUD with GORM, and GORM allows you to change the field-level permission with tag, so you can make a field to be read-only, write-only, create-only, update-only or ignored

{% note warn %}
**NOTE** ignored fields won't be created when using GORM Migrator to create table
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // allow read and create
  Name string `gorm:"<-:update"` // allow read and update
  Name string `gorm:"<-"`        // allow read and write (create and update)
  Name string `gorm:"<-:false"`  // allow read, disable write permission
  Name string `gorm:"->"`        // readonly (disable write permission unless it configured)
  Name string `gorm:"->;<-:create"` // allow read and create
  Name string `gorm:"->:false;<-:create"` // createonly (disabled read from db)
  Name string `gorm:"-"`            // ignore this field when write and read with struct
  Name string `gorm:"-:all"`        // ignore this field when write, read and migrate with struct
  Name string `gorm:"-:migration"`  // ignore this field when migrate with struct
}
```

### <name id="time_tracking">Creating/Updating Time/Unix (Milli/Nano) Seconds Tracking</span>

GORM use `CreatedAt`, `UpdatedAt` to track creating/updating time by convention, and GORM will set the  [current time](gorm_config.html#now_func) when creating/updating if the fields are defined

To use fields with a different name, you can configure those fields with tag `autoCreateTime`, `autoUpdateTime`

If you prefer to save UNIX (milli/nano) seconds instead of time, you can simply change the field's data type from `time.Time` to `int`

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updating or if it is zero on creating
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

Tags are optional to use when declaring models, GORM supports the following tags: Tags are case insensitive, however `camelCase` is preferred.

| 태그 이름                  | 설명                                                                                                                                                                                                                                                                                                               |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column                 | column 이름                                                                                                                                                                                                                                                                                                        |
| type                   | column 데이터 유형, 호환 가능한 일반 유형 (예: bool, int, uint, float, string, time, bytes)을 사용하는 것을 선호합니다. 이는 모든 데이터베이스에서 작동하며 `not null`, `size`, `autoIncrement`와 같은 태그들과 함께 사용할 수 있습니다.<br/> varbinary (8)과 같은 특정 데이터베이스의 데이터 유형도 지원됩니다. 단, 사용하게 된다면 전체 타입을 명시해주어야 합니다. 예: MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT |
| serializer             | specifies serializer for how to serialize and deserialize data into db, e.g: `serializer:json/gob/unixtime`                                                                                                                                                                                                      |
| size                   | specifies column data size/length, e.g: `size:256`                                                                                                                                                                                                                                                               |
| primaryKey             | specifies column as primary key                                                                                                                                                                                                                                                                                  |
| unique                 | specifies column as unique                                                                                                                                                                                                                                                                                       |
| default                | specifies column default value                                                                                                                                                                                                                                                                                   |
| precision              | specifies column precision                                                                                                                                                                                                                                                                                       |
| scale                  | specifies column scale                                                                                                                                                                                                                                                                                           |
| not null               | specifies column as NOT NULL                                                                                                                                                                                                                                                                                     |
| autoIncrement          | specifies column auto incrementable                                                                                                                                                                                                                                                                              |
| autoIncrementIncrement | auto increment step, controls the interval between successive column values                                                                                                                                                                                                                                      |
| embedded               | embed the field                                                                                                                                                                                                                                                                                                  |
| embeddedPrefix         | column name prefix for embedded fields                                                                                                                                                                                                                                                                           |
| autoCreateTime         | track current time when creating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoCreateTime:nano`                                                                                                                                            |
| autoUpdateTime         | track current time when creating/updating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoUpdateTime:milli`                                                                                                                                  |
| index                  | create index with options, use same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                                                                                                                                                                |
| uniqueIndex            | same as `index`, but create uniqued index                                                                                                                                                                                                                                                                        |
| check                  | creates check constraint, eg: `check:age > 13`, refer [Constraints](constraints.html)                                                                                                                                                                                                                         |
| <-                     | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no write permission, `<-` create and update permission                                                                                                                                        |
| ->                     | set field's read permission, `->:false` no read permission                                                                                                                                                                                                                                                    |
| -                      | ignore this field, `-` no read/write permission, `-:migration` no migrate permission, `-:all` no read/write/migrate permission                                                                                                                                                                                   |
| comment                | add comment for field when migration                                                                                                                                                                                                                                                                             |

### Associations Tags

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
