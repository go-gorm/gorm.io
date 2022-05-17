---
title: 관계
layout: page
---

## 자동 생성/갱신

GORM은 레코드를 생성/갱신할 때 [Upsert(업서트)](create.html#upsert)를 사용하여 관계와 참조를 자동으로 저장합니다.

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db.Create(&user)
// BEGIN TRANSACTION;
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "languages" ("name") VALUES ('ZH'), ('EN') ON DUPLICATE KEY DO NOTHING;
// INSERT INTO "user_languages" ("user_id","language_id") VALUES (111, 1), (111, 2) ON DUPLICATE KEY DO NOTHING;
// COMMIT;

db.Save(&user)
```

어소시에이션 데이터를 갱신하려면 `FullSaveAssociations` 모드를 사용해야 합니다.

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## 자동 생성/갱신 건너뛰기

생성/갱신 시 자동 저장을 건너뛰려면 다음과 같이 `Select` 또는 `Omit`를 사용할 수 있습니다.

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
  Emails:          []Email{
    {Email: "jinzhu@example.com"},
    {Email: "jinzhu-2@example.com"},
  },
  Languages:       []Language{
    {Name: "ZH"},
    {Name: "EN"},
  },
}

db.Select("Name").Create(&user)
// INSERT INTO "users" (name) VALUES ("jinzhu", 1, 2);

db.Omit("BillingAddress").Create(&user)
// Skip create BillingAddress when creating a user

db.Omit(clause.Associations).Create(&user)
// Skip all associations when creating a user
```

{% note warn %}
**NOTE:** many2many 어소시에이션의 경우 GORM이 조인 테이블 레퍼런스를 생성하기 전에 어소시에이션을 업서트합니다. 어소시에이션 업서트를 건너뛰려면 다음과 같이 할 수 있습니다.

```go
db.Omit("Languages.*").Create(&user)
```

다음 코드는 어소시에이션과 레퍼런스 생성을 건너뜁니다.

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## Select/Omit Association fields

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// Create user and his BillingAddress, ShippingAddress
// When creating the BillingAddress only use its address1, address2 fields and omit others
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## Association Mode

어소시에이션 모드는 릴레이션십(relationship)을 처리하기 위해 일반적으로 사용되는 몇 가지 헬퍼 메소드가 있습니다.

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source model, it must contains primary key
// `user` 는 기초가 되는 모델이며, primary key 를 반드시 포함해야 한다.
// `Languages` is a relationship's field name
// `Languages` 는 name 필드로 릴레이션 되었다.
// If the above two requirements matched, the AssociationMode should be started successfully, or it should return error
// 위의 두 요구 사항이 일치하는 경우 AssociationMode를 성공적으로 시작하거나 오류를 반환해야 합니다.
db.Model(&user).Association("Languages").Error
```

### 연관된 결과(Find Association)

일치하는 연관된 결과 찾기

```go
db.Model(&user).Association("Languages").Find(&languages)
```

조건을 통한 연관된 결과 찾기

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### Append Associations

`many to many`, `has many` 로 새로운 associations 를 추가 하고, `has one`, `belongs to` 로 현재 association을 교체 합니다.

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
```

### Replace Associations

현재 associations 을 새로운 것으로 변경합니다.

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Delete Associations

원본과 인수 간의 관계가 존재 한다면 제거하고, 참조만 삭제하며, DB에서 해당 개체를 삭제하지 않습니다.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Clear Associations

원본과 association 간의 모든 참조를 제거하고, association 은 제거 하지 않습니다.

```go
db.Model(&user).Association("Languages").Clear()
```

### Count Associations

현재 연관된 수 를 반환 합니다.

```go
db.Model(&user).Association("Languages").Count()

// Count with conditions
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Batch Data

Association Mode 는 일괄 데이터를 제공 합니다.

```go
// Find all roles for all users
db.Model(&users).Association("Role").Find(&roles)

// Delete User A from all user's team
db.Model(&users).Association("Team").Delete(&userA)

// Get distinct count of all users' teams
db.Model(&users).Association("Team").Count()

// For `Append`, `Replace` with batch data, the length of the arguments needs to be equal to the data's length or else it will return an error
var users = []User{user1, user2, user3}
// e.g: we have 3 users, Append userA to user1's team, append userB to user2's team, append userA, userB and userC to user3's team
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Reset user1's team to userA，reset user2's team to userB, reset user3's team to userA, userB and userC
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_with_select">Delete with Select</span>

You are allowed to delete selected has one/has many/many2many relations with `Select` when deleting records, for example:

```go
// delete user's account when deleting user
db.Select("Account").Delete(&user)

// delete user's Orders, CreditCards relations when deleting user
db.Select("Orders", "CreditCards").Delete(&user)

// delete user's has one/many/many2many relations when deleting user
db.Select(clause.Associations).Delete(&user)

// delete each user's account when deleting users
db.Select("Account").Delete(&users)
```

{% note warn %}
**NOTE:** Associations will only be deleted if the deleting records's primary key is not zero, GORM will use those primary keys as conditions to delete selected associations

```go
// DOESN'T WORK
db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{})
// will delete all user with name `jinzhu`, but those user's account won't be deleted

db.Select("Account").Where("name = ?", "jinzhu").Delete(&User{ID: 1})
// will delete the user with name = `jinzhu` and id = `1`, and user `1`'s account will be deleted

db.Select("Account").Delete(&User{ID: 1})
// will delete the user with id = `1`, and user `1`'s account will be deleted
```
{% endnote %}

## <span id="tags">Association Tags</span>

| Tag              | Description                                                                                        |
| ---------------- | -------------------------------------------------------------------------------------------------- |
| foreignKey       | Specifies column name of the current model that is used as a foreign key to the join table         |
| references       | Specifies column name of the reference's table that is mapped to the foreign key of the join table |
| polymorphic      | Specifies polymorphic type such as model name                                                      |
| polymorphicValue | Specifies polymorphic value, default table name                                                    |
| many2many        | Specifies join table name                                                                          |
| joinForeignKey   | Specifies foreign key column name of join table that maps to the current table                     |
| joinReferences   | Specifies foreign key column name of join table that maps to the reference's table                 |
| constraint       | Relations constraint, e.g: `OnUpdate`,`OnDelete`                                                   |
