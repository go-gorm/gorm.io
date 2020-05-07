---
title: Associations
layout: page
---

## Auto Create/Update

GORM은 레코드를 생성/갱신할 때 연관 관계 및 참조를 자동으로 저장할 것입니다. 연관 관계에 기본키가 있는 경우, GORM은 `Update`를 호출하여 저장하고, 그렇지 않다면 기본키를 생성할 것입니다.

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
//// BEGIN TRANSACTION;
//// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1");
//// INSERT INTO "addresses" (address1) VALUES ("Shipping Address - Address 1");
//// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
//// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com");
//// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu-2@example.com");
//// INSERT INTO "languages" ("name") VALUES ('ZH');
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 1);
//// INSERT INTO "languages" ("name") VALUES ('EN');
//// INSERT INTO user_languages ("user_id","language_id") VALUES (111, 2);
//// COMMIT;

db.Save(&user)
```

## Skip AutoUpdate

연관 관계가 데이터베이스에 이미 존재하는 경우, 이것을 갱신하고 싶지 않을 것입니다.

DB 설정을 이용하여 `gorm : association_autoupdate</ code>를 <code>false</ code>로 설정할 수 있습니다.</p>

<pre><code class="go">// 기본키가 있는 연관 관계는 갱신하지 않지만, 참조는 저장합니다.
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
`</pre> 

또는 GORM 태그, ``gorm : "association_autoupdate : false"</ code>를 사용하십시오.</p>

<pre><code class="go">type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // 기본키가 있는 연관 관계는 갱신하지 않지만 참조는 저장합니다.
  Company    Company `gorm:"association_autoupdate:false"`
}
``</pre> 

## Skip AutoCreate

`AutoUpdating</ code>을 비활성화했지만 기본키가 없는 연관 관계는 계속 생성해야하며 참조가 저장됩니다.</p>

<p>이를 비활성화하기 위해 DB 설정 <code>gorm : association_autocreate</ code>를 <code>false</ code>로 설정할 수 있습니다.</p>

<pre><code class="go">// 기본키가 없는 연관 관계를 생성하지 않고, 참조도 저장하지 않습니다.
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)
`</pre> 

또는 GORM 태그, `gorm:"association_autocreate:false"`를 사용하십시오.

    type User struct {
      gorm.Model
      Name       string
      // 기본키가 없는 연관 관계를 생성하지 않고, 참조도 저장하지 않습니다.
      Company1   Company `gorm:"association_autocreate:false"`
    }
    

## Skip AutoCreate/Update

`AutoCreate`와 `AutoUpdate` 둘 모두 비활성화시키려면 아래 설정을 함께 사용할 수 있습니다.

```go
db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
```

또는 `gorm:save_associations` 를 사용하십시오.

    db.Set("gorm:save_associations", false).Create(&user)
    db.Set("gorm:save_associations", false).Save(&user)
    
    type User struct {
      gorm.Model
      Name    string
      Company Company `gorm:"save_associations:false"`
    }
    

## Skip Save Reference

데이터를 갱신/저장할 때 연관 관계의 참조를 저장하지 않으려면 아래와 같은 방법을 사용할 수 있습니다.

```go
db.Set("gorm:association_save_reference", false).Save(&user)
db.Set("gorm:association_save_reference", false).Create(&user)
```

or use tag

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  Company    Company `gorm:"association_save_reference:false"`
}
```

## Association Mode

Association Mode에는 관계 관련 사항들을 쉽게 처리 할 수 있는 헬퍼 메서드가 포함되어 있습니다.

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source, must contains primary key
// `Languages` is source's field name for a relationship
// AssociationMode can only works if above two conditions both matched, check it ok or not:
// db.Model(&user).Association("Languages").Error
```

### Find Associations

일치하는 연관 관계를 찾습니다.

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### Append Associations

`many to many</ code>, <code>has many</ code>에 대한 새로운 연관 관계를 추가하고, <code>has one</ code>, <code>belongs to</ code>에 대한 현재 연관 관계를 대체합니다.</p>

<pre><code class="go">db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
`</pre> 

### Replace Associations

현재 연관 관계를 새로운 연관 관계로 대체합니다.

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Delete Associations

Remove relationship between source & argument objects, only delete the reference, won't delete those objects from DB.

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Clear Associations

Remove reference between source & current associations, won't delete those associations

```go
db.Model(&user).Association("Languages").Clear()
```

### Count Associations

Return the count of current associations

```go
db.Model(&user).Association("Languages").Count()
```