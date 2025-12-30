---
title: 데이터베이스 인덱스
layout: page
---

GORM은 데이터베이스 인덱스를 생성을 지원합니다. `uniqueIndex`, `index` 태그를 활용할 수 있습니다. 이렇게 정의된 인덱스들은 [GORM 자동 마이그레이션 및 테이블 생성](migration.html)이 수행될 때 적용됩니다.

## 인덱스 태그

GORM은 `class`, `type`, `where`, `comment`, `expression`, `sort`, `collate`, `option`과 같은 많은 인덱스 설정을 허용합니다.

사용 방법은 아래 예시를 참고해주세요.

```go
type User struct {
    Name  string `gorm:"index"`
    Name2 string `gorm:"index:idx_name,unique"`
    Name3 string `gorm:"index:,sort:desc,collate:utf8,type:btree,length:10,where:name3 != 'jinzhu'"`
    Name4 string `gorm:"uniqueIndex"`
    Age   int64  `gorm:"index:,class:FULLTEXT,comment:hello \\, world,where:age > 10"`
    Age2  int64  `gorm:"index:,expression:ABS(age)"`
}

// MySQL option
type User struct {
    Name string `gorm:"index:,class:FULLTEXT,option:WITH PARSER ngram INVISIBLE"`
}

// PostgreSQL option
type User struct {
    Name string `gorm:"index:,option:CONCURRENTLY"`
}
```

### 유니크 인덱스

`uniqueIndex` 태그는 `index` 태그와 거의 비슷하게 동작하며, `index:,unique`와 같은 의미로 사용됩니다.

```go
type User struct {
    Name1 string `gorm:"uniqueIndex"`
    Name2 string `gorm:"uniqueIndex:idx_name,sort:desc"`
}
```
Note that this will not work for unique composite indexes.

## 복합 인덱스

두개의 필드에 같은 인덱스 이름을 사용하면 복합 인덱스가 생성됩니다. 아래는 그 예시입니다.

```go
// create composite index `idx_member` with columns `name`, `number`
type User struct {
    Name   string `gorm:"index:idx_member"`
    Number string `gorm:"index:idx_member"`
}
```

For a unique composite index:

```go
// create unique composite index `idx_member` with columns `name`, and `number`
type User struct {
    Name   string `gorm:"index:idx_member,unique"`
    Number string `gorm:"index:idx_member,unique"`
}
```

### 필드 우선순위

복합 인덱스의 컬럼 순서는 성능에 영향을 끼치므로 조심스럽게 정의되어야합니다.

`priority` 옵션의 순서를 정의할 수 있습니다. 디폴트 우선순위 값은 `10`이며, 우선순위의 값이 같다면, 순서는 모델 구조의 필드 인덱스를 기준으로 결정됩니다.

```go
type User struct {
    Name   string `gorm:"index:idx_member"`
    Number string `gorm:"index:idx_member"`
}
// column order: name, number

type User struct {
    Name   string `gorm:"index:idx_member,priority:2"`
    Number string `gorm:"index:idx_member,priority:1"`
}
// column order: number, name

type User struct {
    Name   string `gorm:"index:idx_member,priority:12"`
    Number string `gorm:"index:idx_member"`
}
// column order: number, name
```

### 공유 복합 인덱스

구조체 임베딩을 여러번 수행한다면 데이터베이스 상에서 인덱스 이름의 중복이 발생할 수 있기 때문에, 구조체 임베딩을 통한 공유 복합키를 생성할 때는 인덱스 이름을 할당할 수 없습니다.

이러한 상황에는, 복합 인덱스의 id를 의미하는 `composite` 인덱스 태그를 활용할 수 있습니다. All fields which have the same composite id of the struct are put together to the same index, just like the original rule. But the improvement is it lets the most derived/embedding struct generates the name of index by NamingStrategy. For example:

```go
type Foo struct {
  IndexA int `gorm:"index:,unique,composite:myname"`
  IndexB int `gorm:"index:,unique,composite:myname"`
}
```

If the table Foo is created, the name of composite index will be `idx_foo_myname`.

```go
type Bar0 struct {
  Foo
}

type Bar1 struct {
  Foo
}
```

Respectively, the name of composite index is `idx_bar0_myname` and `idx_bar1_myname`.

`composite` only works if not specify the name of index.

## Multiple indexes

A field accepts multiple `index`, `uniqueIndex` tags that will create multiple indexes on a field

```go
type UserIndex struct {
    OID          int64  `gorm:"index:idx_id;index:idx_oid,unique"`
    MemberNumber string `gorm:"index:idx_id"`
}
```
