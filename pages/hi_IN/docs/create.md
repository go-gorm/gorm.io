---
title: Create(बनाएं)
layout: पृष्ठ
---

## Create Record

```go
user := User{Name: "Jinzhu", Age: 18, Birthday: time.Now()}

result := db.Create(&user) // pass pointer of data to Create

user.ID             // inserted  डेटा की  primary key लौटाता है
result.Error        // returns error
result.RowsAffected // रिटर्न सम्मिलित रिकॉर्ड गिनती
```

## Selected फ़ील्ड्स के साथ रिकॉर्ड Create करे ।

एक रिकॉर्ड Create और specified फ़ील्ड के लिए एक मान assign करें।

```go
db.Select("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`name`,`age`,`created_at`) VALUES ("jinzhu", 18, "2020-07-04 11:05:21.775")
```

एक रिकॉर्ड Create और omit के लिए passed किए गए फ़ील्ड के मानों को ignore करें।

```go
db.Omit("Name", "Age", "CreatedAt").Create(&user)
// INSERT INTO `users` (`birthday`,`updated_at`) VALUES ("2020-01-01 00:00:00.000", "2020-07-04 11:05:21.775")
```

## <span id="batch_insert">Batch Insert</span>

कुशलतापूर्वक बड़ी संख्या में रिकॉर्ड insert करने के लिए, एक slice को `Create` method में पास करें। GORM सभी डेटा डालने और primary key मानों को backfill करने के लिए एक single SQL स्टेटमेंट generate करेगा, hook methods को भी invoked किया जाएगा।

```go
var users = []User{{Name: "jinzhu1"}, {Name: "jinzhu2"}, {Name: "jinzhu3"}}
db.Create(&users)

for _, user := range users {
  user.ID // 1,2,3
}
```

`CreateInBatches` के साथ बनाते समय आप बैच size specify कर सकते हैं, उदा

```go
var users = []User{{Name: "jinzhu_1"}, ...., {Name: "jinzhu_10000"}}

// batch size 100
db.CreateInBatches(users, 100)
```

[Upsert](#upsert) और [Create with Associations](#create_with_associations) का उपयोग करते समय Batch Insert भी support है

{% note warn %}
**ध्यान दें** GORM को `CreateBatchSize` विकल्प के साथ प्रारंभ करें, सभी `INSERT` रिकॉर्ड और& associations बनाते समय इस विकल्प का सम्मान करेंगे
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  CreateBatchSize: 1000,
})

db := db.Session(&gorm.Session{CreateBatchSize: 1000})

users = [5000]User{{Name: "jinzhu", Pets: []Pet{pet1, pet2, pet3}}...}

db.Create(&users)
// INSERT INTO users xxx (5 batches)
// INSERT INTO pets xxx (15 batches)
```

## Create Hooks

GORM user defined हुक को `BeforeSave`, `BeforeCreate`, `AfterSave`, `AfterCreate` के लिए लागू करने की अनुमति देता है।  रिकॉर्ड create करते समय इन hook method को कॉल किया जाएगा, जीवनचक्र पर विवरण के लिए [Hooks](hooks.html) देखें

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  u.UUID = uuid.New()

    if u.Role == "admin" {
        return errors.New("invalid role")
    }
    return
}
```

अगर आप `Hooks` methods को छोड़ना चाहते हैं, तो आप `SkipHooks` session मोड का उपयोग कर सकते हैं, उदाहरण के लिए:

```go
DB.Session(&gorm.Session{SkipHooks: true}).Create(&user)

DB.Session(&gorm.Session{SkipHooks: true}).Create(&users)

DB.Session(&gorm.Session{SkipHooks: true}).CreateInBatches(users, 100)
```

## Create From Map

GORM `map[string]interface{}` और `[]map[string]interface{}{}` से create का समर्थन करता है, e.g:

```go
db.Model(&User{}).Create(map[string]interface{}{
  "Name": "jinzhu", "Age": 18,
})

// batch insert from `[]map[string]interface{}{}`
db.Model(&User{}).Create([]map[string]interface{}{
  {"Name": "jinzhu_1", "Age": 18},
  {"Name": "jinzhu_2", "Age": 20},
})
```

{% note warn %}
**ध्यान दें** map से बनाते समय, हुक नहीं लगाए जाएंगे, associations save नहीं करा जाएगा और प्राथमिक कुंजी मान वापस नहीं भरे जाएंगे
{% endnote %}

## <span id="create_from_sql_expr">Create From SQL Expression/Context Valuer</span>

GORM SQL अभिव्यक्ति के साथ डेटा सम्मिलित करने की अनुमति देता है, इस लक्ष्य को प्राप्त करने के दो तरीके हैं, `map[string]interface{}` या [Customized Data Types](data_types.html#gorm_valuer_interface), उदाहरण के लिए:

```go
// Create from map
db.Model(User{}).Create(map[string]interface{}{
  "Name": "jinzhu",
  "Location": clause.Expr{SQL: "ST_PointFromText(?)", Vars: []interface{}{"POINT(100 100)"}},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"));

// Create from customized data type
type Location struct {
    X, Y int
}

// Scan implements the sql.Scanner interface
func (loc *Location) Scan(v interface{}) error {
  // Scan a value into struct from database driver
}

func (loc Location) GormDataType() string {
  return "geometry"
}

func (loc Location) GormValue(ctx context.Context, db *gorm.DB) clause.Expr {
  return clause.Expr{
    SQL:  "ST_PointFromText(?)",
    Vars: []interface{}{fmt.Sprintf("POINT(%d %d)", loc.X, loc.Y)},
  }
}

type User struct {
  Name     string
  Location Location
}

db.Create(&User{
  Name:     "jinzhu",
  Location: Location{X: 100, Y: 100},
})
// INSERT INTO `users` (`name`,`location`) VALUES ("jinzhu",ST_PointFromText("POINT(100 100)"))
```

## Advanced

### <span id="create_with_associations">Create With Associations</span>

Associations के साथ कुछ डेटा बनाते समय, यदि इसके associations का मूल्य शून्य-मान नहीं है, तो उन associations को upserted करे जाएगा, और इसके `Hooks` methods को लागू किया जाएगा।

```go
type CreditCard struct {
  gorm.Model
  Number   string
  UserID   uint
}

type User struct {
  gorm.Model
  Name       string
  CreditCard CreditCard
}

db.Create(&User{
  Name: "jinzhu",
  CreditCard: CreditCard{Number: "411111111111"}
})
// INSERT INTO `users` ...
// INSERT INTO `credit_cards` ...
```

आप `Select`, `Omit` के साथ saving associations को छोड़ सकते हैं, उदाहरण के लिए:

```go
db.Omit("CreditCard").Create(&user)

// skip all associations
db.Omit(clause.Associations).Create(&user)
```

### <span id="default_values">Default Values</span>

आप `default` टैग वाले फ़ील्ड के लिए डिफ़ॉल्ट मान कर सकते हैं, उदाहरण के लिए:

```go
type User struct {
  ID   int64
  Name string `gorm:"default:galeone"`
  Age  int64  `gorm:"default:18"`
}
```

फिर [शून्य-मान के लिए डेटाबेस में डालने पर डिफ़ॉल्ट मान *का उपयोग* किया जाएगा ](https://tour.golang.org/basics/12) फ़ील्ड्स

{% note warn %}
**ध्यान दें** कोई भी शून्य मान जैसे `0`, `''`, `false` नहीं होगा डिफ़ॉल्ट मान परिभाषित उन फ़ील्ड के लिए डेटाबेस में save किया गया है, आप इससे बचने के लिए पॉइंटर प्रकार या स्कैनर/वैल्यूअर(Scanner/Valuer) का उपयोग करना चाहेंगे, उदाहरण के लिए:
{% endnote %}

```go
type User struct {
  gorm.Model
  Name string
  Age  *int           `gorm:"default:18"`
  Active sql.NullBool `gorm:"default:true"`
}
```

{% note warn %}
**ध्यान दें** यदि आप डिफ़ॉल्ट मान परिभाषा को छोड़ना चाहते हैं, तो आपको `डिफ़ॉल्ट` टैग डेटाबेस में डिफ़ॉल्ट या वर्चुअल/जेनरेट (virtual/generated) किए गए मान वाले फ़ील्ड के लिए सेटअप करना होगा माइग्रेट करते समय, आप `डिफ़ॉल्ट:(-)` का उपयोग कर सकते हैं, उदाहरण के लिए:
{% endnote %}

```go
type User struct {
  ID        string `gorm:"default:uuid_generate_v3()"` // db func
  FirstName string
  LastName  string
  Age       uint8
  FullName  string `gorm:"->;type:GENERATED ALWAYS AS (concat(firstname,' ',lastname));default:(-);"`
}
```

वर्चुअल/जेनरेट(virtual/generated) किए गए मान का उपयोग करते समय, आपको इसकी बनाने/अपडेट (creating/updating) करने की अनुमति को अक्षम(disable) करने की आवश्यकता हो सकती है, [Field-Level Permission](models.html#field_permission) देखें

### <span id="upsert">Upsert / On Conflict</span>

GORM विभिन्न डेटाबेस के लिए compatible Upsert support प्रदान करता है

```go
import "gorm.io/gorm/clause"

// Do nothing on conflict
db.Clauses(clause.OnConflict{DoNothing: true}).Create(&user)

// Update columns to default value on `id` conflict
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"role": "user"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET ***; SQL Server
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE ***; MySQL

// Use SQL expression
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"count": gorm.Expr("GREATEST(count, VALUES(count))")}),
}).Create(&users)
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `count`=GREATEST(count, VALUES(count));

// Update columns to new value on `id` conflict
db.Clauses(clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.AssignmentColumns([]string{"name", "age"}),
}).Create(&users)
// MERGE INTO "users" USING *** WHEN NOT MATCHED THEN INSERT *** WHEN MATCHED THEN UPDATE SET "name"="excluded"."name"; SQL Server
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age"; PostgreSQL
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age); MySQL

// Update all columns to new value on conflict except primary keys and those columns having default values from sql func
db.Clauses(clause.OnConflict{
  UpdateAll: true,
}).Create(&users)
// INSERT INTO "users" *** ON CONFLICT ("id") DO UPDATE SET "name"="excluded"."name", "age"="excluded"."age", ...;
// INSERT INTO `users` *** ON DUPLICATE KEY UPDATE `name`=VALUES(name),`age`=VALUES(age), ...; MySQL
```

[Advanced Query](advanced_query.html) पर `FirstOrInit`, `FirstOrCreate` भी चेकआउट करें

अधिक विवरण के लिए [Raw SQL and SQL Builder](sql_builder.html) चेकआउट करें
