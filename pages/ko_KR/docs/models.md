---
title: 모델 선언
layout: page
---

GORM simplifies database interactions by mapping Go structs to database tables. Understanding how to declare models in GORM is fundamental for leveraging its full capabilities.

## 모델 선언

Models are defined using normal structs. These structs can contain fields with basic Go types, pointers or aliases of these types, or even custom types, as long as they implement the [Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner) and [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) interfaces from the `database/sql` package

아래는 `User` 모델의 예시입니다:

```go
type User struct {
  ID           uint           // Standard field for the primary key
  Name         string         // A regular string field
  Email        *string        // A pointer to a string, allowing for null values
  Age          uint8          // An unsigned 8-bit integer
  Birthday     *time.Time     // A pointer to time.Time, can be null
  MemberNumber sql.NullString // Uses sql.NullString to handle nullable strings
  ActivatedAt  sql.NullTime   // Uses sql.NullTime for nullable time fields
  CreatedAt    time.Time      // Automatically managed by GORM for creation time
  UpdatedAt    time.Time      // Automatically managed by GORM for update time
  ignored      string         // fields that aren't exported are ignored
}
```

In this model:

- Basic data types like `uint`, `string`, and `uint8` are used directly.
- Pointers to types like `*string` and `*time.Time` indicate nullable fields.
- `sql.NullString` and `sql.NullTime` from the `database/sql` package are used for nullable fields with more control.
- `CreatedAt` and `UpdatedAt` are special fields that GORM automatically populates with the current time when a record is created or updated.
- Non-exported fields (starting with a small letter) are not mapped

GORM에서 모델 선언의 기본적인 기능 외에도, serializer 태그를 통한 직렬화 또한 중요한 요소입니다. This feature enhances the flexibility of how data is stored and retrieved from the database, especially for fields that require custom serialization logic, See [Serializer](serializer.html) for a detailed explanation

### 규칙

1. **Primary Key**: GORM uses a field named `ID` as the default primary key for each model.

2. **Table Names**: By default, GORM converts struct names to `snake_case` and pluralizes them for table names. For instance, a `User` struct becomes `users` in the database, and a `GormUserName` becomes `gorm_user_names`.

3. **Column Names**: GORM automatically converts struct field names to `snake_case` for column names in the database.

4. **Timestamp Fields**: GORM은 레코드의 생성과 수정 시각을 기록하기 위해 `CreatedAt`과 `UpdatedAt`을 사용합니다.

Following these conventions can greatly reduce the amount of configuration or code you need to write. However, GORM is also flexible, allowing you to customize these settings if the default conventions don't fit your requirements. You can learn more about customizing these conventions in GORM's documentation on [conventions](conventions.html).

### `gorm.Model`

GORM provides a predefined struct named `gorm.Model`, which includes commonly used fields:

```go
// gorm.Model definition
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

- **구조체에 임베딩하기**: `gorm.Model`을 구조체에 직접 임베딩하면 해당 필드들을 자동으로 포함시킬 수 있습니다. This is useful for maintaining consistency across different models and leveraging GORM's built-in conventions, refer [Embedded Struct](#embedded_struct)

- **Fields Included**:
  - `ID`: A unique identifier for each record (primary key).
  - `CreatedAt`: Automatically set to the current time when a record is created.
  - `UpdatedAt`: Automatically updated to the current time whenever a record is updated.
  - `DeletedAt`: Used for soft deletes (marking records as deleted without actually removing them from the database).

## 고급

### <span id="field_permission">필드 수준 권한</span>

내보낸 필드는 GORM으로 CRUD를 수행할 때 모든 권한을 가지며, GORM에서는 태그를 사용하여 필드 수준 권한을 읽기 전용, 쓰기 전용, 만들기 전용, 업데이트 전용 또는 무시로 설정할 수 있습니다.

{% note warn %}
**참고** GORM 마이그레이터를 사용하여 테이블을 만들 때 무시된 필드는 생성되지 않습니다.
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // 읽기/생성 허용
  Name string `gorm:"<-:update"` // 읽기/수정 허용
  Name string `gorm:"<-"`        // 읽기/쓰기 허용 (생성 및 수정)
  Name string `gorm:"<-:false"`  // 읽기전용, 쓰기 불가능
  Name string `gorm:"->"`        // 읽기허용 (설정되지 않은경우 쓰기 불가능)
  Name string `gorm:"->;<-:create"` //읽기/생성 허용
  Name string `gorm:"->:false;<-:create"` // 생성만 가능 (읽기 불가능)
  Name string `gorm:"-"`  // gorm 에서 이 필드 무시
}
```

### <name id="time_tracking">Creating/Updating Time/Unix (Milli/Nano) Seconds Tracking 생성/업데이트 시 시간/유닉스시간(밀리/나노) 기록</span>

GORM use `CreatedAt`, `UpdatedAt` to track creating/updating time by convention, and GORM will set the  [current time](gorm_config.html#now_func) when creating/updating if the fields are defined

To use fields with a different name, you can configure those fields with tag `autoCreateTime`, `autoUpdateTime`

If you prefer to save UNIX (milli/nano) seconds instead of time, you can simply change the field's data type from `time.Time` to `int`

```go
type User struct {
  CreatedAt time.Time // 생성 시 값이 0이면 현재 시각으로 설정됨
  UpdatedAt int       // 수정 시 현재 Unix 초로 설정되며, 생성 시 값이 0이어도 현재 시각으로 설정됨
  Updated   int64 `gorm:"autoUpdateTime:nano"`  // 수정 시각을 Unix 나노초로 저장
  Updated   int64 `gorm:"autoUpdateTime:milli"` // 수정 시각을 Unix 밀리초로 저장
  Created   int64 `gorm:"autoCreateTime"`       // 생성 시각을 Unix 초로 저장
}
```

### <span id="embedded_struct">Embedded Struct</span>

익명 필드의 경우, GORM은 그 필드의 멤버들을 상위 구조체의 필드처럼 포함해 처리한다. 예를 들면:

```go
type Author struct {
  Name  string
  Email string
}

type Blog struct {
  Author
  ID      int
  Upvotes int32
}
// 동일
type Blog struct {
  ID      int64
  Name    string
  Email   string
  Upvotes int32
}
```

일반 구조체 필드에 대해, `embedded` 태그를 통해 임베딩할 수 있다. 예를 들면:

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

모델을 선언할 때 태그 사용은 선택 사항이며, GORM은 다음과 같은 태그를 지원한다. 태그는 대소문자를 구분하지 않지만, `camelCase`가 권장된다. 여러 태그를 함께 사용할 경우에는 세미콜론(`;`)으로 구분해야 한다. Characters that have special meaning to the parser can be escaped with a backslash (`\`) allowing them to be used as parameter values.

| 태그 이름                  | 설명                                                                                                                                                                                                                                                                                                               |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column                 | column 이름                                                                                                                                                                                                                                                                                                        |
| type                   | column 데이터 유형, 호환 가능한 일반 유형 (예: bool, int, uint, float, string, time, bytes)을 사용하는 것을 선호합니다. 이는 모든 데이터베이스에서 작동하며 `not null`, `size`, `autoIncrement`와 같은 태그들과 함께 사용할 수 있습니다.<br/> varbinary (8)과 같은 특정 데이터베이스의 데이터 유형도 지원됩니다. 단, 사용하게 된다면 전체 타입을 명시해주어야 합니다. 예: MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT |
| serializer             | 데이터를 데이터베이스에 어떻게 직렬화하고 역직렬화할지 지정하는 serializer이다. e.g: `serializer:json/gob/unixtime`                                                                                                                                                                                                                             |
| size                   | specifies column data size/length, e.g: `size:256`                                                                                                                                                                                                                                                               |
| primaryKey             | 컬럼을 기본 키로 지정한다                                                                                                                                                                                                                                                                                                   |
| unique                 | specifies column as unique                                                                                                                                                                                                                                                                                       |
| default                | specifies column default value                                                                                                                                                                                                                                                                                   |
| precision              | specifies column precision                                                                                                                                                                                                                                                                                       |
| scale                  | specifies column scale                                                                                                                                                                                                                                                                                           |
| not null               | specifies column as NOT NULL                                                                                                                                                                                                                                                                                     |
| autoIncrement          | specifies column auto incrementable                                                                                                                                                                                                                                                                              |
| autoIncrementIncrement | 자동 증가 단계(step)를 지정하며, 연속된 컬럼 값 사이의 증가 간격을 제어합니다                                                                                                                                                                                                                                                                  |
| embedded               | embed the field                                                                                                                                                                                                                                                                                                  |
| embeddedPrefix         | column name prefix for embedded fields                                                                                                                                                                                                                                                                           |
| autoCreateTime         | track current time when creating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoCreateTime:nano`                                                                                                                                            |
| autoUpdateTime         | track current time when creating/updating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoUpdateTime:milli`                                                                                                                                  |
| index                  | 옵션을 지정해 인덱스를 생성합니다. 여러 필드에 같은 이름을 사용하면 복합 인덱스가 생성됩니다. 자세한 내용은 [Indexes](indexes.html)를 참고하세요                                                                                                                                                                                                                     |
| uniqueIndex            | same as `index`, but create uniqued index                                                                                                                                                                                                                                                                        |
| check                  | check 제약 조건을 생성합니다. eg: `check:age > 13`, 자세한 내용은 [Constraints](constraints.html)를 참고하세요                                                                                                                                                                                                                      |
| <-                     | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no write permission, `<-` create and update permission                                                                                                                                        |
| ->                     | set field's read permission, `->:false` no read permission                                                                                                                                                                                                                                                    |
| -                      | ignore this field, `-` no read/write permission, `-:migration` no migrate permission, `-:all` no read/write/migrate permission                                                                                                                                                                                   |
| comment                | add comment for field when migration                                                                                                                                                                                                                                                                             |

### Associations Tags

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
