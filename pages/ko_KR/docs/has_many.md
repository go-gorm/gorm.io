---
title: Has Many
layout: page
---

## Has Many

`has many` 연관관계는 다른 모델과의 일 대 다 연결을 맺습니다. `has one`과는 달리, 소유자는 0개, 혹은 다수의 모델 인스턴스를 가질 수 있습니다.

For example, if your application includes users and credit card, and each user can have many credit cards.

### 선언
```go
// User has many CreditCards, UserID is the foreign key
type User struct {
  gorm.Model
  CreditCards []CreditCard
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```

### 조회
```go
// Retrieve user list with eager loading credit cards
func GetAll(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("CreditCards").Find(&users).Error
    return users, err
}
```

## 외부키 오버라이딩

`has many` 관계를 정의하기위해서는 외부키가 반드시 존재해야합니다. 별도의 설정이 없다면, 외부 키의 이름은 소유자의 타입 이름과 primary key 이름의 조합이 됩니다.

예를들어, `User` 에 속한 모델을 정의하기위해서는 외부키의 이름이 `UserID`가 되어야합니다.

다른 필드를 외부 키로 사용하고자 한다면, `foreignKey` 태그를 활용해 변경할 수 있습니다. 아래는 그 예시입니다.

```go
type User struct {
  gorm.Model
  CreditCards []CreditCard `gorm:"foreignKey:UserRefer"`
}

type CreditCard struct {
  gorm.Model
  Number    string
  UserRefer uint
}
```

## 참조 오버라이딩

GORM은 주로 소유자의 primary key를 외부키로 사용합니다. 위 예시에서는 `User`의 `ID`입니다.

유저에게 크레딧 카드를 할당하고자 한다면, GORM은 유저의 `ID`를 크레딧 카드의 `UserID` 필드에 저장합니다.

`references` 태그를 활용해 참조될 이름을 바꿀 수 있습니다. 아래는 그 예시입니다.

```go
type User struct {
  gorm.Model
  MemberNumber string
  CreditCards  []CreditCard `gorm:"foreignKey:UserNumber;references:MemberNumber"`
}

type CreditCard struct {
  gorm.Model
  Number     string
  UserNumber string
}
```

## 다형성 연관관계

GORM은 `has one`과 `has many`에서 다형성 연관관계를 지원합니다. 소속된 엔티티의 테이블 명은 다형성 타입 필드에 저장되며, primary key 값은 다형성 필드에 저장됩니다.

```go
type Dog struct {
  ID   int
  Name string
  Toys []Toy `gorm:"polymorphic:Owner;"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  OwnerType string
}

db.Create(&Dog{Name: "dog1", Toys: []Toy{{Name: "toy1"}, {Name: "toy2"}}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","dogs"), ("toy2","1","dogs")
```

다형성 타입의 값을 `polymorphicValue` 태그를 활용해 변경할 수 있습니다. 아래는 그 예시입니다.

```go
type Dog struct {
  ID   int
  Name string
  Toys []Toy `gorm:"polymorphic:Owner;polymorphicValue:master"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  OwnerType string
}

db.Create(&Dog{Name: "dog1", Toy: []Toy{{Name: "toy1"}, {Name: "toy2"}}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","master"), ("toy2","1","master")
```

## Has Many 연관관계를 활용한 CRUD

has many 관계를 활용하려면 [연관관계 모드](associations.html#Association-Mode)를 참고해주세요.

## 즉시 로딩

GORM은 `Preload`를 활용하여 has many 연관관계의 즉시로딩을 지원합니다. 자세한 내용은 [미리 로딩 (즉시 로딩)](preload.html)을 참고해주세요.

## 자기 참조 Has Many

```go
type User struct {
  gorm.Model
  Name      string
  ManagerID *uint
  Team      []User `gorm:"foreignkey:ManagerID"`
}
```

## 외부 키 제약

`constraint` 태그를 활용해, `OnUpdate`, `OnDelete`와 같은 제약을 설정할 수 있습니다. 이런 제약들은 GORM 마이그레이션을 할 때 생성됩니다. 아래는 그 예시입니다.

```go
type User struct {
  gorm.Model
  CreditCards []CreditCard `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```

또한 Has many 연관관계는 `Select`를 활용해 선택적으로 삭제될 수 있습니다. 삭제에 관한 자세한 정보는 [Select로 삭제하기](associations.html#delete_with_select)를 참고해주세요.
