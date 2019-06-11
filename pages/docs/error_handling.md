---
title: Error Handling
layout: page
---

In Go, error handling is important.

You are encouraged to do error check after any [Immediate Methods](/docs/method_chaining.html#Immediate-Methods)

## Error Handling

Error handling in GORM is different than idiomatic Go code because of its chainable API, but still easy to implement.

If any error occurs, GORM will set `*gorm.DB`'s `Error` field, which you can check like this:

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

When processing data, it is common for multiple errors to occur. GORM provides an API to return all errors as a slice:

```go
// If there are more than one error happened, `GetErrors` returns them as `[]error`
errors := db.First(&user).Limit(10).Find(&users).GetErrors()

fmt.Println(len(errors))

for _, err := range errors {
  fmt.Println(err)
}
```

## RecordNotFound Error

GORM provides a shortcut to handle `RecordNotFound` errors. If there are several errors, it will check if any of them is a `RecordNotFound` error.

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
