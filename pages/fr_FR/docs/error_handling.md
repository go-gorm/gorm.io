---
title: Error Handling
layout: page
---

In Go, error handling is important.

You are encouraged to do error check after any [Finisher Methods](method_chaining.html#finisher_method)

## Error Handling

Error handling in GORM is different than idiomatic Go code because of its chainable API.

If any error occurs, GORM will set `*gorm.DB`'s `Error` field, you need to check it like this:

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

## ErrRecordNotFound

GORM returns `ErrRecordNotFound` when failed to find data with `First`, `Last`, `Take`, if there are several errors happened, you can check the `ErrRecordNotFound` error with `errors.Is`, for example:

```go
// Check if returns RecordNotFound error
err := db.First(&user, 100).Error
errors.Is(err, gorm.ErrRecordNotFound)
```
## Dialect Translated Errors

If you would like to be able to use the dialect translated errors(like ErrDuplicatedKey), then enable the TranslateError flag when opening a db connection.

```go
db, err := gorm.Open(postgres.Open(postgresDSN), &gorm.Config{TranslateError: true})
```

## Errors

[Errors List](https://github.com/go-gorm/gorm/blob/master/errors.go)
