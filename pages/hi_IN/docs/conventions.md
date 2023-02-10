---
title: Conventions
layout: पृष्ठ
---

## `ID` as Primary Key

GORM डिफ़ॉल्ट रूप से table की primary key के रूप में `ID` नाम के फ़ील्ड का उपयोग करता है।

```go
type User struct {
 ID string // field named `ID` will be used as a primary field by default
 Name string
}
```

`primaryKey` टैग के साथ आप अन्य फ़ील्ड को primary key के रूप में सेट कर सकते हैं

```go
// Set field `UUID` as primary field
type Animal struct {
 ID int64
 UUID string `gorm:"primaryKey"`
 Name string
 Age int64
}
```

[Composite Primary Key](composite_primary_key.html) भी देखें

## Pluralized Table Name

GORM table के नाम के रूप में `snake_cases` के रूप में संरचना नाम का pluralizes करता है, संरचना `User` के लिए, परंपरा के अनुसार इसका table नाम `users` है

### TableName

आप `Tabler` इंटरफ़ेस लागू करके डिफ़ॉल्ट table नाम बदल सकते हैं, उदाहरण के लिए:

```go
type Tabler interface {
    TableName() string
}

// TableName overrides the table name used by User to `profiles`
func (User) TableName() string {
  return "profiles"
}
```

{% note warn %}
**ध्यान दें** `TableName` dynamic नाम की अनुमति नहीं देता है, इसका परिणाम भविष्य के लिए कैश(cached) किया जाएगा, dynamic नाम का उपयोग करने के लिए, आप `Scopes </कोड>, उदाहरण के लिए:
</p>

<p spaces-before="0">{% endnote %}</p>

<pre><code class="go">func UserTable(user User) func (tx *gorm.DB) *gorm.DB {
  return func (tx *gorm.DB) *gorm.DB {
    if user.Admin {
      return tx.Table("admin_users")
    }

    return tx.Table("users")
  }
}

db.Scopes(UserTable(user)).Create(&user)
`</pre>

### Temporarily specify a name

`Table` विधि के साथ table का नाम Temporarily रूप से specify करें, उदाहरण के लिए:

```go
// Create table `deleted_users` with struct User's fields
db.Table("deleted_users").AutoMigrate(&User{})

// Query data from another table
var deletedUsers []User
db.Table("deleted_users").Find(&deletedUsers)
// SELECT * FROM deleted_users;

db.Table("deleted_users").Where("name = ?", "jinzhu").Delete(&User{})
// DELETE FROM deleted_users WHERE name = 'jinzhu';
```

FROM clause में SubQuery का उपयोग कैसे करें, इसके लिए [SubQuery से](advanced_query.html#from_subquery) देखें

### <span id="naming_strategy">NamingStrategy</span>

GORM users को डिफॉल्ट `NamingStrategy` को ओवरराइड करके डिफॉल्ट नेमिंग कन्वेंशन को बदलने की अनुमति देता है, जिसका उपयोग `TableName`, `ColumnName`, `JoinTableName` बनाने के लिए किया जाता है। code>, `RelationshipFKName`, `CheckerName`, `IndexName`, [GORM Config](gorm_config.html#naming_strategy) देखें जानकारी के लिए

## Column Name

कॉलम db name convention द्वारा फ़ील्ड के नाम `snake_case` का उपयोग करता है।

```go
type User struct {
 ID uint // column name is `id`
 Name string // column name is `name`
 Birthday time.Time // column name is `birthday`
 CreatedAt time.Time // column name is `created_at`
}
```

आप `column` टैग के साथ कॉलम नाम को ओवरराइड कर सकते हैं या [`NamingStrategy`](#naming_strategy) का उपयोग कर सकते हैं

```go
type Animal struct {
 AnimalID int64 `gorm:"column:beast_id"` // set name to `beast_id`
 Birthday time.Time `gorm:"column:day_of_the_beast"` // set name to `day_of_the_beast`
 Age int64 `gorm:"column:age_of_the_beast"` // set name to `age_of_the_beast`
}
```

## Timestamp Tracking

### CreatedAt

`CreatedAt` फ़ील्ड वाले मॉडल के लिए, फ़ील्ड को वर्तमान समय पर सेट किया जाएगा जब रिकॉर्ड पहली बार बनाया जाता है यदि इसका मान शून्य है

```go
db.Create(&user) // set `CreatedAt` to current time

user2 := User{Name: "jinzhu", CreatedAt: time.Now()}
db.Create(&user2) // user2's `CreatedAt` won't be changed

// To change its value, you could use `Update`
db.Model(&user).Update("CreatedAt", time.Now())
```

आप `autoCreateTime` टैग को `false` पर सेट करके टाइमस्टैम्प ट्रैकिंग disable कर सकते हैं, उदाहरण के लिए:

```go
type User struct {
  CreatedAt time.Time `gorm:"autoCreateTime:false"`
}
```

### UpdatedAt

`UpdatedAt` फ़ील्ड वाले मॉडल के लिए, फ़ील्ड को वर्तमान समय पर सेट किया जाएगा जब रिकॉर्ड अपडेट किया जाता है या बनाया जाता है यदि इसका मान शून्य है

```go
db.Save(&user) // set `UpdatedAt` to current time

db.Model(&user).Update("name", "jinzhu") // will set `UpdatedAt` to current time

db.Model(&user).UpdateColumn("name", "jinzhu") // `UpdatedAt` won't be changed

user2 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Create(&user2) // user2's `UpdatedAt` won't be changed when creating

user3 := User{Name: "jinzhu", UpdatedAt: time.Now()}
db.Save(&user3) // user3's `UpdatedAt` will change to current time when updating
```

आप `autoUpdateTime` टैग को `false` पर सेट करके टाइमस्टैम्प ट्रैकिंग को disable कर सकते हैं, उदाहरण के लिए:

```go
type User struct {
  UpdatedAt time.Time `gorm:"autoUpdateTime:false"`
}
```

{% note %}
**ध्यान दें** GORM multiple समय ट्रैकिंग फ़ील्ड का समर्थन करता है और UNIX (नैनो/मिली) सेकंड के साथ ट्रैक करता है, चेकआउट [Models](models.html#time_tracking) अधिक जानकारी के लिए
{% endnote %}
