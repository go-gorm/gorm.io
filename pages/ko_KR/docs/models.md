---
title: 모델 선언
layout: page
---

## 모델 선언

모델은 보통 일반적인 Go언어 구조체, 기본 Go 타입 또는 포인터입니다. [`sql.Scanner`](https://golang.org/pkg/database/sql/#Scanner) 과 [`driver.Valuer`](https://golang.org/pkg/database/sql/driver/#Valuer) 인터페이스도 지원합니다.

모델 예제:

```go
type User struct {
  gorm.Model
  Name         string
  Age          sql.NullInt64
  Birthday     *time.Time
  Email        string  `gorm:"type:varchar(100);unique_index"`
  Role         string  `gorm:"size:255"` // 필드 사이즈를 255로 설정합니다.
  MemberNumber *string `gorm:"unique;not null"` // MemberNumber를 유니크, not null로 설정합니다.
  Num          int     `gorm:"AUTO_INCREMENT"` // Num을 자동증가 번호로 설정합니다.
  Address      string  `gorm:"index:addr"` // 이름이 `addr`인 인덱스를 작성합니다.
  IgnoreMe     int     `gorm:"-"` // 이 항목은 무시합니다.
}
```

## 구조체 태그

태그는 모델을 선언 시 선택사항입니다. GORM은 아래의 태그들을 지원합니다:

### 지원하는 구조체 태그

| 태그              | 설명                                               |
| --------------- | ------------------------------------------------ |
| Column          | 컬럼명을 지정합니다.                                      |
| Type            | 데이터 타입을 지정합니다.                                   |
| Size            | 컬럼 사이즈를 지정합니다. 기본값은 255 입니다.                     |
| PRIMARY_KEY     | 기본키로 지정합니다.                                      |
| UNIQUE          | 유니크 제약을 지정합니다.                                   |
| DEFAULT         | 기본값을 지정합니다.                                      |
| PRECISION       | 자릿수를 지정합니다.                                      |
| NOT NULL        | NOT NULL 제약을 지정합니다.                              |
| AUTO_INCREMENT  | 자동증가번호 유무를 지정합니다.                                |
| INDEX           | 이름이 있거나, 없는 인덱스를 생성합니다. 이름이 같을 경우 복합 인덱스가 작성됩니다. |
| UNIQUE_INDEX    | `INDEX`와 같이 유니크 인덱스를 작성합니다.                      |
| EMBEDDED        | 임베디드 구조체로 설정합니다.                                 |
| EMBEDDED_PREFIX | 임베디드 구조체의 접두사 이름을 지정합니다.                         |
| -               | 이 항목은 무시됩니다.                                     |

### Struct tags for Associations

Check out the Associations section for details

| Tag                                | Description                                    |
| ---------------------------------- | ---------------------------------------------- |
| MANY2MANY                          | Specifies join table name                      |
| FOREIGNKEY                         | Specifies foreign key                          |
| ASSOCIATION_FOREIGNKEY             | Specifies association foreign key              |
| POLYMORPHIC                        | Specifies polymorphic type                     |
| POLYMORPHIC_VALUE                  | Specifies polymorphic value                    |
| JOINTABLE_FOREIGNKEY               | Specifies foreign key of jointable             |
| ASSOCIATION_JOINTABLE_FOREIGNKEY | Specifies association foreign key of jointable |
| SAVE_ASSOCIATIONS                  | AutoSave associations or not                   |
| ASSOCIATION_AUTOUPDATE             | AutoUpdate associations or not                 |
| ASSOCIATION_AUTOCREATE             | AutoCreate associations or not                 |
| ASSOCIATION_SAVE_REFERENCE       | AutoSave associations reference or not         |
| PRELOAD                            | Auto Preload associations or not               |