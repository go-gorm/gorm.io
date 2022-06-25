---
title: Has One
layout: page
---

## Has One

`has one` 연관성은 다른 모델과 1대 1 연결을 맺지만 결과적, 의미론적으로 조금 다르다고 말할 수 있습니다. 이 연관성은 각 모델의 인스턴스가 다른 모델의 인스턴스를 포함하거나 소유하고 있음을 의미합니다.

예를들어, 만약 어떤 어플리케이션이 users 와 credit cards를 가지고 있고, 각 유저는 오직 하나의 credit card만을 가질 수 있을 때, 연관성은 다음과 같이 설명됩니다.

### Declare
```go
// 유저는 한개의 신용카드를 가지고 있고, CreditCardID는 foreign key 입니다.
type User struct {
  gorm.Model
  CreditCard CreditCard
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```

### Retrieve
```go
// Retrieve user list with edger loading credit card
func GetAll(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("CreditCard").Find(&users).Error
    return users, err
}
```

## Foreign Key 오버라이드

`has one` 관계에서, foreign key 필드는 필수입니다. 또한, 소유자는 피소유 필드의 primary key를 해당 필드에 저장합니다.

필드의 이름은 보통 `has one`  모델의 타입과  해당 모델의  `primary key`를 붙여서 생성됩니다. 위 예의 경우 필드의 이름은`UserID`입니다.

만약 Credit card를 어떤 유저에게 넘겨준다면 Credit card 모델은 수령자의 `ID`를  `UserID` 필드에 저장합니다.

만약 해당 관계를 저장하기위해 다른 필드를 사용하고자 한다면,  `foreignKey` 태그를 사용해 바꿀 수 있습니다. 아래 코드는 foreignKey 태그를 사용한 예시입니다.

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"foreignKey:UserName"`
  // use UserName as foreign key
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## 참조 오버라이드

기본적으로, 소유된 엔터티는 `has one` 모델의 primary key를 foreign key에 저장하며, 아래 예시에서 `Name`을 사용하는 것 처럼다른 필드의 값을 저장하기위해 변경할 수 있습니다.

`references` 태그를 활용해 변경할 수 있는 예시입니다.

```go
type User struct {
  gorm.Model
  Name       string     `gorm:"index"`
  CreditCard CreditCard `gorm:"foreignkey:UserName;references:name"`
}

type CreditCard struct {
  gorm.Model
  Number   string
  UserName string
}
```

## 다형성 관계

GORM은  `has one` 과 `has many`관계에서 다형성 을 지원합니다. 다형성 관계는, 소유된 엔티티의 테이블 이름을 다형성 타입 필드에 저장하며, primary key는 다형성 필드에 저장합니다.

```go
type Cat struct {
  ID    int
  Name  string
  Toy   Toy `gorm:"polymorphic:Owner;"`
}

type Dog struct {
  ID   int
  Name string
  Toy  Toy `gorm:"polymorphic:Owner;"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  OwnerType string
}

db.Create(&Dog{Name: "dog1", Toy: Toy{Name: "toy1"}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","dogs")
```

`polymorphicValue` 태그를 활용하여 다형성 타입 벨류를 변경할 수 있습니다. 아래 예시를 살펴보세요.

```go
type Dog struct {
  ID   int
  Name string
  Toy  Toy `gorm:"polymorphic:Owner;polymorphicValue:master"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  OwnerType string
}

db.Create(&Dog{Name: "dog1", Toy: Toy{Name: "toy1"}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1","1","master")
```

## CRUD with Has One

`has one` 관계를 활용하는 방법에 대한 내용은 [연관 모드](associations.html#Association-Mode)를 참고해주세요.

## 즉시 로딩

GORM은 `Preload` 또는 `Joins`과 함께 `has one` 연관성을 즉시 로딩할 수 있습니다. 자세한 내용은  [미리 로딩 (즉시 로딩)](preload.html)을 참고해주세요.

## 자기 참조 Has One

```go
type User struct {
  gorm.Model
  Name      string
  ManagerID *uint
  Manager   *User
}
```

## 외부 키 제약

`constraint`태그를 활용하여 `OnUpdate`, `OnDelete` 제약을 설정할 수 있습니다. 이 설정은 GORM으로 마이그레이션을 진행할 때 생성됩니다.

```go
type User struct {
  gorm.Model
  CreditCard CreditCard `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type CreditCard struct {
  gorm.Model
  Number string
  UserID uint
}
```

`Select()`메서드를 사용해 선택적으로 has one 연관성을 제거할 수 있습니다. 자세한 내용은 [Select 메서드로 삭제하기](associations.html#delete_with_select)를 참고해주세요.
