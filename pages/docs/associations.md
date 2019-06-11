---
title: Associations
layout: page
---

## Auto Create/Update

GORM will auto save associations and its reference when creating/updating a record. if association has a primary key, GORM will call `Update` to save it, otherwise it will be created.

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

If your association is already existing in database, you might not want to update it.

You could use DB setting, set `gorm:association_autoupdate` to `false`

```go
// Don't update associations having primary key, but will save reference
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)
```

or use GORM tags, `gorm:"association_autoupdate:false"`

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // Don't update associations having primary key, but will save reference
  Company    Company `gorm:"association_autoupdate:false"`
}
```

## Skip AutoCreate

Even though you disabled `AutoUpdating`, associations w/o primary key still have to be created and its reference will be saved.

To disable this, you could set DB setting `gorm:association_autocreate` to `false`

```go
// Don't create associations w/o primary key, WON'T save its reference
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)
```

or use GORM tags, `gorm:"association_autocreate:false"`

```
type User struct {
  gorm.Model
  Name       string
  // Don't create associations w/o primary key, WON'T save its reference
  Company1   Company `gorm:"association_autocreate:false"`
}
```

## Skip AutoCreate/Update

To disable both `AutoCreate` and `AutoUpdate`, you could use those two settings together

```go
db.Set("gorm:association_autoupdate", false).Set("gorm:association_autocreate", false).Create(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}
```

Or use `gorm:save_associations`

```
db.Set("gorm:save_associations", false).Create(&user)
db.Set("gorm:save_associations", false).Save(&user)

type User struct {
  gorm.Model
  Name    string
  Company Company `gorm:"save_associations:false"`
}
```

## Skip Save Reference

If you don't even want to save association's reference when updating/saving data, you could use below tricks

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

Association Mode contains some helper methods to handle relationship related things easily.

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

Find matched associations

```go
db.Model(&user).Association("Languages").Find(&languages)
```

### Append Associations

Append new associations for `many to many`, `has many`, replace current associations for `has one`, `belongs to`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Append(Language{Name: "DE"})
```

### Replace Associations

Replace current associations with new ones

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
