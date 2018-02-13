title: Error Handling
---

After perform any operations, if there are any error happened, GORM will set it to `*DB`'s `Error` field

```go
if err := db.Where("name = ?", "jinzhu").First(&user).Error; err != nil {
	// error handling...
}

// If there are more than one error happened, get all of them with `GetErrors`, it returns `[]error`
db.First(&user).Limit(10).Find(&users).GetErrors()

// Check if returns RecordNotFound error
db.Where("name = ?", "hello world").First(&user).RecordNotFound()

if db.Model(&user).Related(&credit_card).RecordNotFound() {
	// no credit card found handling
}
```
