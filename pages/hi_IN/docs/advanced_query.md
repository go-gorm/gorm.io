---
title: Advanced Query
layout: page
---

## <span id="smart_select">स्मार्ट सेलेक्ट फील्ड्स</span>

जीओआरएम(GORM) चयन के साथ विशिष्ट क्षेत्रों का चयन ( [`Select`](query.html)) करने की अनुमति देता है, यदि आप अक्सर इसे अपने आवेदन में उपयोग करते हैं, तो हो सकता है कि आप एपीआई उपयोग के लिए एक छोटी संरचना को परिभाषित करना चाहते हैं जो स्वचालित रूप से विशिष्ट क्षेत्रों का चयन कर सकता है, उदाहरण के लिए |

```go
type User struct {
  ID     uint
  Name   string
  Age    int
  Gender string
  // hundreds of fields
}

type APIUser struct {
  ID   uint
  Name string
}

// Select `id`, `name` automatically when querying
// / query करते समय `id`, `name` स्वचालित रूप से Select  करता 
db.Model(&User{}).Limit(10).Find(&APIUser{})
// SELECT `id`, `name` FROM `users` LIMIT 10
```

{% note warn %}
**NOTE** `QueryFields` mode वर्तमान के लिए सभी फ़ील्ड्स के नाम से Select करेगा
{% endnote %}

```go
db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{
  QueryFields: true,
})

db.Find(&user)
//db वह सभी fild ढूंढता है जो अंदर है(user) 
// नीचे  की तरह
// SELECT `users`.`name`, `users`.`age`, ... FROM `users` // इस विकल्प के साथ

// Session Mode
db.Session(&gorm.Session{QueryFields: true}).Find(&user)
// SELECT `users`.`name`, `users`.`age`, ... FROM `users`
```

## Locking (FOR UPDATE) //लॉकिंग (UPDATE के लिए)

उदाहरण के लिए GORM विभिन्न प्रकार के locks का समर्थन करता है

```go
db.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&users)
// SELECT * FROM `users` FOR UPDATE

db.Clauses(clause.Locking{
  Strength: "SHARE",
  Table: clause.Table{Name: clause.CurrentTable},
}).Find(&users)
// SELECT * FROM `users` FOR SHARE OF `users`

db.Clauses(clause.Locking{
  Strength: "UPDATE",
  Options: "NOWAIT",
}).Find(&users)
// SELECT * FROM `users` FOR UPDATE NOWAIT
```

अधिक विवरण के लिए [Raw SQL and SQL Builder](sql_builder.html) देखें

## SubQuery //सबक्वेरी

एक subquery को एक query के भीतर nested किया जा सकता है, param के रूप में `*gorm.DB` ऑब्जेक्ट का उपयोग करते समय GORM सबक्वेरी उत्पन्न कर सकता है

```go
db.Where("amount > (?)", db.Table("orders").Select("AVG(amount)")).Find(&orders)
// SELECT * FROM "orders" WHERE amount > (SELECT AVG(amount) FROM "orders");
// चुनें * "orders" से जहां amount > ("orders" से AVG(amount) चुनें);

subQuery := db.Select("AVG(age)").Where("name LIKE ?", "name%").Table("users")
db.Select("AVG(age) as avgage").Group("name").Having("AVG(age) > (?)", subQuery).Find(&results)
// SELECT AVG(age) as avgage FROM `users` GROUP BY `name` HAVING AVG(age) > (SELECT AVG(age) FROM `users` WHERE name LIKE "name%")
```

### <span id="from_subquery">From SubQuery //सबक्वेरी से</span>

GORM आपको `Table` विधि के साथ FROM खंड में subquery का उपयोग करने की अनुमति देता है, उदाहरण के लिए:

```go
db.Table("(?) as u", db.Model(&User{}).Select("name", "age")).Where("age = ?", 18).Find(&User{})
// SELECT * FROM (SELECT `name`,`age` FROM `users`) as u WHERE `age` = 18

subQuery1 := db.Model(&User{}).Select("name")
subQuery2 := db.Model(&Pet{}).Select("name")
db.Table("(?) as u, (?) as p", subQuery1, subQuery2).Find(&User{})
// SELECT * FROM (SELECT `name` FROM `users`) as u, (SELECT `name` FROM `pets`) as p
```

## <span id="group_conditions">Group Conditions //समूह की शर्तें</span>

समूह शर्तों ( Group Conditions ) के साथ जटिल SQL query लिखना आसान

```go
db.Where(
    db.Where("pizza = ?", "pepperoni").Where(db.Where("size = ?", "small").Or("size = ?", "medium")),
).Or(
    db.Where("pizza = ?", "hawaiian").Where("size = ?", "xlarge"),
).Find(&Pizza{}).Statement

// SELECT * FROM `pizzas` WHERE (pizza = "pepperoni" AND (size = "small" OR size = "medium")) OR (pizza = "hawaiian" AND size = "xlarge")
```

## IN with multiple columns //IN कई कॉलम के साथ

एकाधिक कॉलम के साथ IN का चयन करना

```go
db.Where("(name, age, role) IN ?", [][]interface{}{{"jinzhu", 18, "admin"}, {"jinzhu2", 19, "user"}}).Find(&users)
// SELECT * FROM users WHERE (name, age, role) IN (("jinzhu", 18, "admin"), ("jinzhu 2", 19, "user"));
```

## Named Argument // नामांकित तर्क

GORM नामित तर्कों का समर्थन करता है [`sql.NamedArg`](https://tip.golang.org/pkg/database/sql/#NamedArg) या `map[ string]इंटरफ़ेस{}{}`, उदाहरण के लिए:

```go
db.Where("name1 = @name OR name2 = @name", sql.Named("name", "jinzhu")).Find(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu"

db.Where("name1 = @name OR name2 = @name", map[string]interface{}{"name": "jinzhu"}).First(&user)
// SELECT * FROM `users` WHERE name1 = "jinzhu" OR name2 = "jinzhu" ORDER BY `users`.`id` LIMIT 1
```

अधिक विवरण के लिए [रॉ SQL और SQL बिल्डर](sql_builder.html#named_argument) देखें

## Find To Map //मानचित्र में खोजें

GORM परिणामों को `map[string]interface{}` या `[]map[string]interface{}` में स्कैन करने की अनुमति देता है, `Model` निर्दिष्ट करना न भूलें > या `तालिका`, उदाहरण के लिए:

```go
result := map[string]interface{}{}
db.Model(&User{}).First(&result, "id = ?", 1)

var results []map[string]interface{}
db.Table("users").Find(&results)
```

## FirstOrInit

पहले मिलान किए गए रिकॉर्ड प्राप्त करें या दी गई शर्तों के साथ एक नया उदाहरण आरंभ करें (only works with struct or map conditions)

```go
// User not found, initialize it with give conditions
db.FirstOrInit(&user, User{Name: "non_existing"})
// user -> User{Name: "non_existing"}

// Found user with `name` = `jinzhu`
db.Where(User{Name: "jinzhu"}).FirstOrInit(&user)
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}

// Found user with `name` = `jinzhu`
db.FirstOrInit(&user, map[string]interface{}{"name": "jinzhu"})
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

यदि रिकॉर्ड नहीं मिला तो अधिक विशेषताओं के साथ संरचना प्रारंभ करें, उन `Attrs` का उपयोग SQL query बनाने के लिए नहीं किया जाएगा

```go
// User not found, initialize it with give conditions and Attrs
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// User not found, initialize it with give conditions and Attrs
db.Where(User{Name: "non_existing"}).Attrs("age", 20).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// user -> User{Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, attributes will be ignored
db.Where(User{Name: "Jinzhu"}).Attrs(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 18}
```

`Assign` संरचना को विशेषताएँ मिले या न मिले, उन विशेषताओं का उपयोग SQL query बनाने के लिए नहीं किया जाएगा और अंतिम डेटा डेटाबेस में सहेजा नहीं जाएगा

```go
// User not found, initialize it with give conditions and Assign attributes
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrInit(&user)
// user -> User{Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, update it with Assign attributes
db.Where(User{Name: "Jinzhu"}).Assign(User{Age: 20}).FirstOrInit(&user)
// SELECT * FROM USERS WHERE name = jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "Jinzhu", Age: 20}
```

## FirstOrCreate

पहले मिलान किए गए रिकॉर्ड प्राप्त करें या दी गई शर्तों के साथ एक नया बनाएं (only works with struct, map conditions), `RowsAffected` `` निर्मित/अपडेट किए गए रिकॉर्ड की संख्या लौटाता है</p>

<pre><code class="go">// User not found, create a new record with give conditions
result := db.FirstOrCreate(&user, User{Name: "non_existing"})
// INSERT INTO "users" (name) VALUES ("non_existing");
// user -> User{ID: 112, Name: "non_existing"}
// result.RowsAffected // => 1

// Found user with `name` = `jinzhu`
result := db.Where(User{Name: "jinzhu"}).FirstOrCreate(&user)
// user -> User{ID: 111, Name: "jinzhu", "Age": 18}
// result.RowsAffected // => 0
``</pre>

यदि रिकॉर्ड नहीं मिला तो अधिक विशेषताओं के साथ संरचना बनाएं, उन `Attrs` का उपयोग SQL query बनाने के लिए नहीं किया जाएगा

```go
// User not found, create it with give conditions and Attrs
db.Where(User{Name: "non_existing"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, attributes will be ignored
db.Where(User{Name: "jinzhu"}).Attrs(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// user -> User{ID: 111, Name: "jinzhu", Age: 18}
```

रिकॉर्ड के लिए विशेषताएँ `Assign` चाहे वह मिले या नहीं और उन्हें डेटाबेस में वापस सहेजें (save)।

```go
// User not found, initialize it with give conditions and Assign attributes
db.Where(User{Name: "non_existing"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'non_existing' ORDER BY id LIMIT 1;
// INSERT INTO "users" (name, age) VALUES ("non_existing", 20);
// user -> User{ID: 112, Name: "non_existing", Age: 20}

// Found user with `name` = `jinzhu`, update it with Assign attributes
db.Where(User{Name: "jinzhu"}).Assign(User{Age: 20}).FirstOrCreate(&user)
// SELECT * FROM users WHERE name = 'jinzhu' ORDER BY id LIMIT 1;
// UPDATE users SET age=20 WHERE id = 111;
// user -> User{ID: 111, Name: "jinzhu", Age: 20}
```

## Optimizer/Index Hints

Optimizer संकेत query Optimizer को एक certain query execution योजना चुनने के लिए नियंत्रित करने की अनुमति देते हैं, GORM इसे `gorm.io/hints` के साथ समर्थन करता है, उदा:

```go
import "gorm.io/hints"

db.Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find(&User{})
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Query planner के भ्रमित होने की स्थिति में इंडेक्स संकेत डेटाबेस को इंडेक्स संकेत पास करने की अनुमति देते हैं।

```go
import "gorm.io/hints"

db.Clauses(hints.UseIndex("idx_user_name")).Find(&User{})
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

db.Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find(&User{})
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)"
```

अधिक विवरण के लिए [Optimizer Hints/Index/Comment](hints.html) देखें</p> 



## Iteration

GORM Rows के माध्यम से पुनरावृति(iterating) का समर्थन करता है



```go
rows, err := db.Model(&User{}).Where("name = ?", "jinzhu").Rows()
defer rows.Close()

for rows.Next() {
  var user User
  // ScanRows is a method of `gorm.DB`, it can be used to scan a row into a struct
  db.ScanRows(rows, &user)

  // do something
}
```




## FindInBatches

batch में Query और process रिकॉर्ड



```go
// batch size 100
result := db.Where("processed = ?", false).FindInBatches(&results, 100, func(tx *gorm.DB, batch int) error {
  for _, result := range results {
    // बैच प्रोसेसिंग में रिकॉर्ड मिले
  }

  tx.Save(&results)

  tx.RowsAffected // इस batch में रिकॉर्ड की संख्या

  batch // Batch 1, 2, 3

  // रिटर्न err भविष्य के बैचों को रोक देगा
  return nil
})

result.Error // returned error
result.RowsAffected // संसाधित रिकॉर्ड सभी बैचों(batch ) में गिने जाते हैं
```




## Query Hooks

GORM एक प्रश्न के लिए हुक`AfterFind` की अनुमति देता है, रिकॉर्ड की क्वेरी करते समय इसे कॉल किया जाएगा, विवरण के लिए [हुक](hooks.html) देखें



```go
func (u *User) AfterFind(tx *gorm.DB) (err error) {
  if u.Role == "" {
    u.Role = "user"
  }
  return
}
```




## <span id="pluck">Pluck</span>

डेटाबेस से एकल कॉलम को क्वेरी करें और एक स्लाइस में स्कैन करें, यदि आप कई कॉलमों को query करना चाहते हैं, तो [`Scan`के साथ `Select` का उपयोग करें।](query.html#scan) इसके बजाय



```go
var ages []int64
db.Model(&users).Pluck("age", &ages)

var names []string
db.Model(&User{}).Pluck("name", &names)

db.Table("deleted_users").Pluck("name", &names)

// Distinct Pluck
db.Model(&User{}).Distinct().Pluck("Name", &names)
// SELECT DISTINCT `name` FROM `users`

// Requesting more than one column, use `Scan` or `Find` like this:
db.Select("name", "age").Scan(&users)
db.Select("name", "age").Find(&users)
```




## Scopes

`Scopes` आपको आमतौर पर उपयोग की जाने वाली queries निर्दिष्ट करने की अनुमति देता है जिसे विधि कॉल(method calls) के रूप में संदर्भित(referenced) किया जा सकता है



```go
func AmountGreaterThan1000(db *gorm.DB) *gorm.DB {
  return db.Where("amount > ?", 1000)
}

func PaidWithCreditCard(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func PaidWithCod(db *gorm.DB) *gorm.DB {
  return db.Where("pay_mode_sign = ?", "C")
}

func OrderStatus(status []string) func (db *gorm.DB) *gorm.DB {
  return func (db *gorm.DB) *gorm.DB {
    return db.Where("status IN (?)", status)
  }
}

db.Scopes(AmountGreaterThan1000, PaidWithCreditCard).Find(&orders)
// Find all credit card orders and amount greater than 1000
// सभी क्रेडिट कार्ड ऑर्डर और 1000 से अधिक राशि का पता लगाएं

db.Scopes(AmountGreaterThan1000, PaidWithCod).Find(&orders)
// Find all COD orders and amount greater than 1000

db.Scopes(AmountGreaterThan1000, OrderStatus([]string{"paid", "shipped"})).Find(&orders)
// Find all paid, shipped orders that amount greater than 1000
```


विवरण के लिए [Scopes](scopes.html) चेकआउट करें



## <span id="count">Count</span>

मिलान किए गए रिकॉर्ड की संख्या प्राप्त करें



```go
db.Table("deleted_users").Count(&count)
// SELECT count(1) FROM deleted_users;

// Count with Distinct
db.Model(&User{}).Distinct("name").Count(&count)
// SELECT COUNT(DISTINCT(`name`)) FROM `users`

db.Table("deleted_users").Select("count(distinct(name))").Count(&count)
// SELECT count(distinct(name)) FROM deleted_users

// Count with Group
users := []User{
  {Name: "name1"},
  {Name: "name2"},
  {Name: "name3"},
  {Name: "name3"},
}

db.Model(&User{}).Group("name").Count(&count)
count // => 3
```
