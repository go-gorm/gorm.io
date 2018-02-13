title: Architecture
---

Gorm use chainable API, `*gorm.DB` is the bridge of chains, for each chain API, it will create a new relation.

```go
db, err := gorm.Open("postgres", "user=gorm dbname=gorm sslmode=disable")

// create a new relation
db = db.Where("name = ?", "jinzhu")

// filter even more
if SomeCondition {
    db = db.Where("age = ?", 20)
} else {
    db = db.Where("age = ?", 30)
}
if YetAnotherCondition {
    db = db.Where("active = ?", 1)
}
```

When we start to perform any operations, GORM will create a new `*gorm.Scope` instance based on current `*gorm.DB`

```go
// perform a querying operation
db.First(&user)
```

And based on current operation's type, it will call registered `creating`, `updating`, `querying`, `deleting` or `row_querying` callbacks to run the operation.

For above example, will call `querying` callbacks, refer [Querying Callbacks](callbacks.html#querying-an-object)


