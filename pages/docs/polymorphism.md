---
title: Polymorphism
layout: Page
---

## Polymorphism Association

GORM supports polymorphism association for `has one` and `has many`, it will save owned entity's table name into polymorphic type's field, primary key value into the polymorphic field

By default `polymorphic:<value>` will prefix the column type and column id with `<value>`. 
The value will be the table name pluralized. 

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


But you can specify them separately :
- the column type with `polymorphicType`
- the column id with `polymorphicId`
- the value of the type with `polymorphicValue`

```go
type Dog struct {
  ID   int
  Name string
  Toys []Toy `gorm:"polymorphicType:Kind;polymorphicId:OwnerID;polymorphicValue:master"`
}

type Toy struct {
  ID        int
  Name      string
  OwnerID   int
  Kind string
}

db.Create(&Dog{Name: "dog1", Toys: []Toy{{Name: "toy1"}, {Name: "toy2"}}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`kind`) VALUES ("toy1","1","master"), ("toy2","1","master")
```
