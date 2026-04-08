---
title: 모델 선언
layout: page
---

GORM은 Go 구조체와 데이터베이스 테이블을 매핑해 데이터베이스와의 상호작용을 쉽게 만들어줍니다. GORM의 기능을 제대로 활용하기 위해서는 모델 선언을 이해하는 것이 핵심입니다.

## 모델 선언

모델은 일반적인 구조체를 사용해 정의합니다. 이 구조체들은 기본 Go 타입의 필드, 그 타입들에 대한 포인터나 별칭(alias) 타입의 필드, 또는 `database/sql` 패키지의  [Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner)와  [Valuer](https://pkg.go.dev/database/sql/driver#Valuer)  인터페이스를 구현한 커스텀 타입의 필드를 포함할 수 있습니다.

아래는 `User` 모델의 예시입니다:

```go
type User struct {
  ID           uint           // 기본 키로 사용하는 표준 필드
  Name         string         // 일반적인 문자열 필드
  Email        *string        // null 값을 허용하는 문자열 포인터 필드
  Age          uint8          // 부호 없는 8비트 정수 필드
  Birthday     *time.Time     // null이 될 수 있는 time.Time 포인터 필드
  MemberNumber sql.NullString // nullable 문자열 처리를 위해 sql.NullString 사용
  ActivatedAt  sql.NullTime   // nullable 시간 필드를 위해 sql.NullTime 사용
  CreatedAt    time.Time      // 생성 시각을 위해 GORM이 자동으로 관리하는 필드
  UpdatedAt    time.Time      // 수정 시각을 위해 GORM이 자동으로 관리하는 필드
  ignored      string         // export되지 않은 필드는 무시됨
}
```

이 모델에서:

- `uint`, `string`,  `uint8` 과 같은 기본 타입들은 그대로 직접 사용됩니다.
- `*string`, `*time.Time` 과 같은 포인터 타입은 nullable 필드를 나타냅니다.
- `database/sql` 패키지의 `sql.NullString`, `sql.NullTime` 는 nullable 필드를 보다 세밀하게 다루기 위해 사용됩니다.
- `CreatedAt`과 `UpdatedAt`은 GORM이 레코드가 생성될 때 자동으로 현재 시각을 기입하는 특수한 필드입니다.
- (소문자로 시작하는) export 되지 않은 필드들은 매핑되지 않습니다

GORM에서 모델 선언의 기본적인 기능 외에도, serializer 태그를 통한 직렬화 또한 중요한 요소입니다. 특히 커스텀 직렬화가 필요한 필드들에서, 이 기능은 데이터베이스에서 데이터를 가져오고 저장하는 방식의 유연성을 증가시킵니다. 자세한 설명은 [Serializer](serializer.html)를 참고하세요

### 규칙

1. **Primary Key**: 각각의 모델들에 대해 GORM은 `ID`라는 이름의 필드를 기본 키로 사용합니다.

2. **Table Names**: 기본적으로, GORM은 구조체 이름을 `snake_case`로 변환하고 복수형으로 변환해 테이블명으로 사용합니다. 예를 들어, `User` 구조체는 데이터베이스에 `users` 테이블로 변환되고, `GormUserName`은 `gorm_user_names` 테이블이 됩니다.

3. **Column Names**: GORM은 구조체의 필드 이름을 `snake_case`로 변환하여 데이터베이스의 컬럼명으로 사용합니다.

4. **Timestamp Fields**: GORM은 레코드의 생성과 수정 시각을 기록하기 위해 `CreatedAt`과 `UpdatedAt`을 사용합니다.

이러한 관례를 따르면 직접 작성해야 하는 설정이나 코드의 양을 크게 줄일 수 있습니다. 그럼에도 불구하고, GORM은 이 기본 관례가 당신의 요구 사항과 맞지 않을 때 설정을 수정할 수 있도록 유연함을 제공합니다. GORM 문서의 [conventions](conventions.html)에서 이 관례들을 수정하는 방법에 대해 알 수 있습니다.

### `gorm.Model`

GORM은 자주 사용되는 필드를 포함한 미리 정의된 `gorm.Model` 구조체를 제공합니다:

```go
// gorm.Model definition
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

- **구조체에 임베딩하기**: `gorm.Model`을 구조체에 직접 임베딩하면 해당 필드들을 자동으로 포함시킬 수 있습니다. 이는 여러 모델 간의 일관성을 유지하고 GORM에 내장된 관례들을 활용하는데 유용합니다. 자세한 내용은 [Embedded Struct](#embedded_struct)를 참고하세요

- **포함된 필드**:
  - `ID`: 각각의 레코드에 대한 고유 식별자 (기본 키).
  - `CreatedAt`: 레코드 생성 시 자동으로 설정되는 현재 시각.
  - `UpdatedAt`: 레코드 수정 시 자동으로 설정되는 현재 시각.
  - `DeletedAt`: soft deletes에 사용 (레코드를 실제로 데이터베이스에서 삭제하는 대신 레코드에 삭제를 기록).

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

GORM은 관례적으로 `CreatedAt`, `UpdatedAt`을 생성/수정을 추적하는데 사용합니다. 이 필드들이 정의되어 있으면 GORM은 [current time](gorm_config.html#now_func)을 설정합니다

필드명을 다르게 하려면, 해당 필드들에 대해 `autoCreateTime`, `autoUpdateTime` 태그를 사용해 설정할 수 있습니다

만약 당신이 시각 대신에 UNIX 초(또는 밀리초, 나노초)를 선호한다면, 단순히 `time.Time` 대신에 `int`를 필드의 자료형으로 사용할 수 있습니다

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

익명 필드의 경우, GORM은 그 필드의 멤버들을 상위 구조체의 필드처럼 포함해 처리합니다. 예를 들면:

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

일반 구조체 필드에 대해, `embedded` 태그를 통해 임베딩할 수 있습니다. 예를 들면:

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

그리고 `embeddedPrefix` 태그를 사용하면 임베딩된 필드의 데이터베이스 컬럼명 앞에 접두사를 붙일 수 있습니다. 예를 들면:

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

모델을 선언할 때 태그 사용은 선택 사항이며, GORM은 다음과 같은 태그를 지원합니다. 태그는 대소문자를 구분하지 않지만, `camelCase`가 권장됩니다. 여러 태그를 함께 사용할 경우에는 세미콜론(`;`)으로 구분해야 합니다. 파서에서 특별한 의미를 가지는 문자는 백슬래시(`\`)로 이스케이프해서 파라미터 값으로 사용할 수 있습니다.

| 태그 이름                  | 설명                                                                                                                                                                                                                                                                                                               |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column                 | column 이름                                                                                                                                                                                                                                                                                                        |
| type                   | column 데이터 유형, 호환 가능한 일반 유형 (예: bool, int, uint, float, string, time, bytes)을 사용하는 것을 선호합니다. 이는 모든 데이터베이스에서 작동하며 `not null`, `size`, `autoIncrement`와 같은 태그들과 함께 사용할 수 있습니다.<br/> varbinary (8)과 같은 특정 데이터베이스의 데이터 유형도 지원됩니다. 단, 사용하게 된다면 전체 타입을 명시해주어야 합니다. 예: MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT |
| serializer             | 데이터를 데이터베이스에 어떻게 직렬화하고 역직렬화할지 지정하는 serializer입니다. e.g: `serializer:json/gob/unixtime`                                                                                                                                                                                                                            |
| size                   | 컬럼의 데이터 크기나 길이를 지정합니다. e.g: `size:256`                                                                                                                                                                                                                                                                           |
| primaryKey             | 컬럼을 기본 키로 지정합니다                                                                                                                                                                                                                                                                                                  |
| unique                 | 컬럼을 고유 값으로 지정합니다                                                                                                                                                                                                                                                                                                 |
| default                | 컬럼에 기본 값을 지정합니다                                                                                                                                                                                                                                                                                                  |
| precision              | 컬럼의 정밀도를 지정합니다                                                                                                                                                                                                                                                                                                   |
| scale                  | 컬럼의 스케일을 지정합니다                                                                                                                                                                                                                                                                                                   |
| not null               | 컬럼을 NOT NULL로 지정합니다                                                                                                                                                                                                                                                                                              |
| autoIncrement          | 컬럼을 auto increment(자동 증가)로 지정합니다                                                                                                                                                                                                                                                                                 |
| autoIncrementIncrement | 자동 증가 단계(step)를 지정하며, 연속된 컬럼 값 사이의 증가 간격을 제어합니다                                                                                                                                                                                                                                                                  |
| embedded               | 필드를 임베딩합니다                                                                                                                                                                                                                                                                                                       |
| embeddedPrefix         | 임베딩된 필드의 컬럼명 앞에 붙일 접두사를 지정합니다                                                                                                                                                                                                                                                                                    |
| autoCreateTime         | 생성 시 현재 시각을 기록합니다. `int` 필드에서는 Unix 초를, `nano`/`milli` 필드에서는 Unix 나노/밀리 초를 사용합니다. e.g: `autoCreateTime:nano`                                                                                                                                                                                                     |
| autoUpdateTime         | 생성/수정 시 현재 시각을 기록합니다. `int` 필드에서는 Unix 초를, `nano`/`milli` 필드에서는 Unix 나노/밀리 초를 사용합니다. e.g: `autoUpdateTime:milli`                                                                                                                                                                                                 |
| index                  | 옵션을 지정해 인덱스를 생성합니다. 여러 필드에 같은 이름을 사용하면 복합 인덱스가 생성됩니다. 자세한 내용은 [Indexes](indexes.html)를 참고하세요                                                                                                                                                                                                                     |
| uniqueIndex            | `index`와 같지만, unique 인덱스를 생성합니다                                                                                                                                                                                                                                                                                  |
| check                  | check 제약 조건을 생성합니다. eg: `check:age > 13`, 자세한 내용은 [Constraints](constraints.html)를 참고하세요                                                                                                                                                                                                                      |
| <-                     | 필드의 쓰기 권한을 설정합니다. `<-:create`는 생성만 가능, `<-:update`는 수정만 가능, `<-:false`는 쓰기 권한 없음, `<-` 는 생성과 수정 가능입니다                                                                                                                                                                                                |
| ->                     | 필드의 읽기 권한을 설정합니다. `->:false`는 읽기 권한 없음입니다                                                                                                                                                                                                                                                                     |
| -                      | 이 필드를 무시합니다. `-`는 읽기/쓰기 권한 없음, `-:migration`는 마이그레이션 권한 없음, `-:all`는 읽기/쓰기/마이그레이션 권한 없음입니다                                                                                                                                                                                                                       |
| comment                | 마이그레이션 시 필드에 설명을 추가합니다                                                                                                                                                                                                                                                                                           |

### Associations Tags

GORM은 연관 관계에 대한 태그를 통해 외래 키, 제약 조건, N:N 테이블을 지원합니다. 자세한 내용은 [Associations section](associations.html#tags)를 확인하세요
