---
title: Error Handling
layout: page
---

In Go, error handling is important.

You are encouraged to do error check after any [Immediate Methods](/docs/method_chaining.html#Immediate-Methods)

## Error Handling

Error handling in GORM is different with idiomatic Go code because of its chainable API, but it is still fairly easy to do that.

If there are any error happened, GORM will set it to `*gorm.DB`'s `Error` field, you could check it like this:

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
	// error handling...
}
```

Or

```go
if result := db.Where("name = ?", "jinzhu").First(&user); result.Error != nil {
	// error handling...
}
```

## Errors

It is common several errors happend during processing data, GORM provides an API to return all happened errors as a slice

```go
// If there are more than one error happened, `GetErrors` returns them as `[]error`
db.First(&user).Limit(10).Find(&users).GetErrors()

fmt.Println(len(errors))

for _, err := range errors {
  fmt.Println(err)
}
```

## RecordNotFound Error

GORM provides a shortcut to handle `RecordNotFound` error, if there are several errors happened, it will check each error if any of them is `RecordNotFound` error.

```go
// Check if returns RecordNotFound error
db.Where("name = ?", "hello world").First(&user).RecordNotFound()

if db.Model(&user).Related(&credit_card).RecordNotFound() {
  // record not found
}

if err := db.Where("name = ?", "jinzhu").First(&user).Error; gorm.IsRecordNotFoundError(err) {
  // record not found
}
```
