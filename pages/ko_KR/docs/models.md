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

Tags are optional to use when declaring models. GORM supports the following tags:

### Supported Struct tags

| Tag             | Description                                                            |
| --------------- | ---------------------------------------------------------------------- |
| Column          | Specifies column name                                                  |
| Type            | Specifies column data type                                             |
| Size            | Specifies column size, default 255                                     |
| PRIMARY_KEY     | Specifies column as primary key                                        |
| UNIQUE          | Specifies column as unique                                             |
| DEFAULT         | Specifies column default value                                         |
| PRECISION       | Specifies column precision                                             |
| NOT NULL        | Specifies column as NOT NULL                                           |
| AUTO_INCREMENT  | Specifies column auto incrementable or not                             |
| INDEX           | Create index with or without name, same name creates composite indexes |
| UNIQUE_INDEX    | Like `INDEX`, create unique index                                      |
| EMBEDDED        | Set struct as embedded                                                 |
| EMBEDDED_PREFIX | Set embedded struct's prefix name                                      |
| -               | Ignore this fields                                                     |

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