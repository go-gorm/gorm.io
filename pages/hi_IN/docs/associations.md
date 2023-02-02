---
title: Associations //संघों
layout: page //पृष्ठ
---

## Auto Create/Update //ऑटो बनाएं/अपडेट करें

रिकॉर्ड बनाते/अपडेट(creating/updating) करते समय GORM [Upsert](create.html#upsert) का उपयोग करके एसोसिएशन(associations) और उसके संदर्भ को अपने आप सहेज लेगा।

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

अगर आप एसोसिएशन के डेटा को अपडेट करना चाहते हैं, तो आपको `FullSaveAssociations` मोड का इस्तेमाल करना चाहिए:

```go
db.Session(&gorm.Session{FullSaveAssociations: true}).Updates(&user)
// ...
// INSERT INTO "addresses" (address1) VALUES ("Billing Address - Address 1"), ("Shipping Address - Address 1") ON DUPLICATE KEY SET address1=VALUES(address1);
// INSERT INTO "users" (name,billing_address_id,shipping_address_id) VALUES ("jinzhu", 1, 2);
// INSERT INTO "emails" (user_id,email) VALUES (111, "jinzhu@example.com"), (111, "jinzhu-2@example.com") ON DUPLICATE KEY SET email=VALUES(email);
// ...
```

## Skip Auto Create/Update // ऑटो क्रिएट/अपडेट छोड़ें

बनाते/अपडेट(creating/updating) करते समय ऑटो सेव को छोड़ने के लिए, आप `Select` या `Omit` का उपयोग कर सकते हैं, उदाहरण के लिए:

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
// उपयोगकर्ता बनाते समय बिलिंग एड्रेस बनाना छोड़ें

db.Omit(clause.Associations).Create(&user)
// Skip all associations when creating a user
// उपयोगकर्ता बनाते समय सभी संघों को छोड़ दें
```

{% note warn %}
**नोट:**कई से कई associations के लिए, GORM सम्मिलित तालिका संदर्भ बनाने से पहले associations को अपसेट करेगा, यदि आप associations के अप्सर्टिंग को छोड़ना चाहते हैं, तो आप इसे इस तरह छोड़ सकते हैं:

```go
db.Omit("Languages.*").Create(&user)
```

निम्नलिखित कोड एसोसिएशन (association) और उसके संदर्भों(references) के निर्माण को छोड़ देगा

```go
db.Omit("Languages").Create(&user)
```
{% endnote %}

## Select/Omit Association fields // एसोसिएशन फ़ील्ड का चयन करें/छोड़ दें

```go
user := User{
  Name:            "jinzhu",
  BillingAddress:  Address{Address1: "Billing Address - Address 1", Address2: "addr2"},
  ShippingAddress: Address{Address1: "Shipping Address - Address 1", Address2: "addr2"},
}

// Create user and his BillingAddress, ShippingAddress
// When creating the BillingAddress only use its address1, address2 fields and omit others
// उपयोगकर्ता और उसका बिलिंग पता, शिपिंग पता बनाएँ
// बिलिंग पता बनाते समय केवल इसके पते1, पते2 फ़ील्ड का उपयोग करें और अन्य को छोड़ दें
db.Select("BillingAddress.Address1", "BillingAddress.Address2").Create(&user)

db.Omit("BillingAddress.Address2", "BillingAddress.CreatedAt").Create(&user)
```

## Association Mode

Association मोड में रिश्तों को संभालने के लिए आमतौर पर इस्तेमाल की जाने वाली कुछ सहायक विधियाँ(helper methods) होती हैं

```go
// Start Association Mode
var user User
db.Model(&user).Association("Languages")
// `user` is the source model, it must contains primary key
// `Languages` is a relationship's field name
// If the above two requirements matched, the AssociationMode should be started successfully, or it should return error
// `उपयोगकर्ता` स्रोत मॉडल है, इसमें प्राथमिक कुंजी होनी चाहिए
// `Languages` एक रिश्ते का फील्ड नाम है
// यदि उपरोक्त दो आवश्यकताएं मेल खाती हैं, तो एसोसिएशनमोड को सफलतापूर्वक शुरू किया जाना चाहिए, या त्रुटि वापस आनी चाहिए
db.Model(&user).Association("Languages").Error
```

### Find Associations

(Find matched associations) मिलान किए गए संघों को खोजें

```go
db.Model(&user).Association("Languages").Find(&languages)
```

Find associations with conditions // शर्तों के साथ जुड़ाव खोजें

```go
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Find(&languages)

db.Model(&user).Where("code IN ?", codes).Order("code desc").Association("Languages").Find(&languages)
```

### Append Associations //संघों को जोड़ें

`अनेक से अनेक(many to many)` के लिए नए संबंध जोड़ें, `has many<code>`, `has one` के लिए वर्तमान संबंध बदलें, `belongs to`

```go
db.Model(&user).Association("Languages").Append([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Append(&Language{Name: "DE"})

db.Model(&user).Association("CreditCard").Append(&CreditCard{Number: "411111111111"})
```

### Replace Associations // संघों को बदलें

मौजूदा associations को नए के साथ बदलें

```go
db.Model(&user).Association("Languages").Replace([]Language{languageZH, languageEN})

db.Model(&user).Association("Languages").Replace(Language{Name: "DE"}, languageEN)
```

### Delete Associations // संघों को हटाएं

स्रोत(source) और तर्क (मौजूद हैं, तो केवल reference हटाएं, उन objects को DB से नहीं हटाएंगे।

```go
db.Model(&user).Association("Languages").Delete([]Language{languageZH, languageEN})
db.Model(&user).Association("Languages").Delete(languageZH, languageEN)
```

### Clear Associations // स्पष्ट संघ

Source और association के बीच सभी reference निकालें, उन associations को नहीं हटाएंगे

```go
db.Model(&user).Association("Languages").Clear()
```

### Count Associations //संघों की गणना करें

वर्तमान associations की गिनती लौटाएँ

```go
db.Model(&user).Association("Languages").Count()

// Count with conditions
codes := []string{"zh-CN", "en-US", "ja-JP"}
db.Model(&user).Where("code IN ?", codes).Association("Languages").Count()
```

### Batch Data // बैच डेटा

एसोसिएशन मोड बैच डेटा का समर्थन करता है, जैसे:

```go
// Find all roles for all users //सभी उपयोगकर्ताओं के लिए सभी भूमिकाएँ खोजें
db.Model(&users).Association("Role").Find(&roles)

// Delete User A from all user's team
//उपयोगकर्ता ए को सभी उपयोगकर्ता की टीम से हटाएं
db.Model(&users).Association("Team").Delete(&userA)

// Get distinct count of all users' teams
// सभी उपयोगकर्ताओं की टीमों की अलग-अलग गिनती प्राप्त करें
db.Model(&users).Association("Team").Count()

// For `Append`, `Replace` with batch data, the length of the arguments needs to be equal to the data's length or else it will return an error
// बैच डेटा के साथ `संलग्न`, `बदलें` के लिए, तर्कों की लंबाई डेटा की लंबाई के बराबर होनी चाहिए अन्यथा यह एक त्रुटि लौटाएगा
var users = []User{user1, user2, user3}
// e.g: we have 3 users, Append userA to user1's team, append userB to user2's team, append userA, userB and userC to user3's team
// उदाहरण: हमारे पास 3 उपयोगकर्ता हैं, userA को user1 की टीम में जोड़ें, userB को user2 की टीम में जोड़ें, userA, userB और userC को user3 की टीम में जोड़ें
db.Model(&users).Association("Team").Append(&userA, &userB, &[]User{userA, userB, userC})
// Reset user1's team to userA，reset user2's team to userB, reset user3's team to userA, userB and userC
// user1 की टीम को userA पर रीसेट करें, user2 की टीम को userB पर रीसेट करें, user3 की टीम को userA, userB और userC पर रीसेट करें
db.Model(&users).Association("Team").Replace(&userA, &userB, &[]User{userA, userB, userC})
```

## <span id="delete_with_select">सेलेक्ट के साथ डिलीट करें</span>

रिकॉर्ड हटाते समय आपको `Select` के साथ Selected has one/ many2many संबंध हटाने की अनुमति है, उदाहरण के लिए:

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
