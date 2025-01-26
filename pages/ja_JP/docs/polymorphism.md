---
title: ポリモーフィズム
layout: Page
---

## ポリモーフィズムでの関連付け

GORMは `has one` と `has many` のポリモーフィズムでの関連付けをサポートします。自身のエンティティのテーブル名はポリモーフィック型のフィールドに、主キーの値はポリモーフィックフィールドにそれぞれ保存されます。

`polymorphic:<value>`のように指定すると、デフォルトでは型とIDのカラムの名前の先頭に`<value>`が付与されます。
値は、複数形に変換されたテーブル名になります。

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
// INSERT INTO `toys` (`name`,`owner_id`,`owner_type`) VALUES ("toy1",1,"dogs"), ("toy2",1,"dogs")
```

以下のGORMタグを使用して、ポリモーフィズムに関するプロパティを個別に指定できます。

- `polymorphicType`: カラムの型を指定します。
- `polymorphicId`:カラムのIDになるフィールドを指定します。
- `polymorphicValue`: 指定した型の値を指定します。

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
  Kind      string
}

db.Create(&Dog{Name: "dog1", Toys: []Toy{{Name: "toy1"}, {Name: "toy2"}}})
// INSERT INTO `dogs` (`name`) VALUES ("dog1")
// INSERT INTO `toys` (`name`,`owner_id`,`kind`) VALUES ("toy1",1,"master"), ("toy2",1,"master")
```

以上は一対多のリレーションの例ですが、一対一のリレーションの場合にも同様の原則が適用されます。
