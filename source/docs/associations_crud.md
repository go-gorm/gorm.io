title: Associations
---

By default when creating/updating a record, GORM will save its associations and its reference.
If the association has a primary key already, GORM will call `Update` to save it, otherwise it will be created.

```go
user := User{
	Name:            "jinzhu",
	BillingAddress:  Address{Address1: "Billing Address - Address 1"},
	ShippingAddress: Address{Address1: "Shipping Address - Address 1"},
	Emails:          []Email{
										{Email: "jinzhu@example.com"},
										{Email: "jinzhu-2@example@example.com"},
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

Refer [Associations](associations.html) for more details

## Skip Auto Save Associations when creating/updating

By default when saving an record, GORM will save its associations also, you could skip it by set `gorm:save_associations` to `false`

```go
// Disable update associations with primary key, will update reference
db.Set("gorm:association_autoupdate", false).Create(&user)
db.Set("gorm:association_autoupdate", false).Save(&user)

// Disable create associations w/o primary key, will update reference for records have primary key
db.Set("gorm:association_autocreate", false).Create(&user)
db.Set("gorm:association_autocreate", false).Save(&user)

// Disable auto update/create associations, will update reference for records have primary key
db.Set("gorm:save_associations", false).Create(&user)
db.Set("gorm:save_associations", false).Save(&user)
```

## Skip Save Associations by Tag

You could use Tag to config your struct to never save an association when creating/updating

```go
type User struct {
  gorm.Model
  Name       string
  CompanyID  uint
  // Disable auto upate/create associations, will update reference for records have primary key
  Company    Company `gorm:"save_associations:false"`
  // Disable create associations w/0 primary key, will update reference for records have primary key
  Company1   Company `gorm:"association_autocreate:false"`
  // Disable auto creating associations w/o primary key, will update reference for records have primary key
  Company2   Company `gorm:"association_autoupdate:false"`
  // Disable autoupdate and autocreate associations, will update reference for records have primary key
  Company3   Company `gorm:"association_autoupdate:false;association_autocreate:false"`
}

type Company struct {
  gorm.Model
  Name string
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
