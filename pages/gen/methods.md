---
title: Methods
layout: page
---

#### Methods


##### Generate model bind custom method
```Go
//package test_model

type CommonMethod struct {
    ID   int32
    Name *string
}

func (m *CommonMethod) IsEmpty() bool {
    if m == nil {
        return true
    }
    return m.ID == 0
}
func (m *CommonMethod) GetName() string {
    if m == nil || m.Name == nil {
        return ""
    }
    return *m.Name
}

//package main

m:=test_model.CommonMethod{}
// add custom method to generated model struct
g.GenerateModel("people", gen.WithMethod(m.IsEmpty))
// also you can input a struct,will bind all method
g.GenerateModel("user", gen.WithMethod(m))
```


##### Gen bind result

Add custom method to generated model struct,e.g.

```go

package model

import (
	"time"

	"gorm.io/gorm"
)

const TableNamePerson = "people"

// Person mapped from table <people>
type Person struct {
	ID          int64          `gorm:"column:id;primaryKey;autoIncrement:true" json:"id"`
	Name        *string        `gorm:"column:name" json:"name"`
	Age         *int32         `gorm:"column:age" json:"age"`
	Flag        *bool          `gorm:"column:flag" json:"flag"`
	Commit      *string        `gorm:"column:commit" json:"commit"`
	First       *bool          `gorm:"column:First" json:"First"`
	FlagAnother *int32         `gorm:"column:flag_another" json:"flag_another"`
	Bit         *[]byte        `gorm:"column:bit" json:"bit"`
	Small       *int32         `gorm:"column:small" json:"small"`
	DeletedAt   gorm.DeletedAt `gorm:"column:deleted_at" json:"deleted_at"`
	Score       *float64       `gorm:"column:score" json:"score"`
	Type        *int32         `gorm:"column:type" json:"type"`
	Birth       *time.Time     `gorm:"column:birth" json:"birth"`
}

// TableName Person's table name
func (*Person) TableName() string {
	return TableNamePerson
}

func (m *Person) IsEmpty() bool {
	if m == nil {
		return true
	}
	return m.ID == 0
}

```

Input a struct, bind all custom method to generated model struct,e.g.
```go

package model

import (
	"time"
)

const TableNameJustUser = "user"

// User mapped from table <user>
type User struct {
	ID             int64      `gorm:"column:id;primaryKey;autoIncrement:true" json:"id"`
	Name           *string    `gorm:"column:name" json:"name"`
	Address        *string    `gorm:"column:address" json:"address"`
	RegisterTime   *time.Time `gorm:"column:register_time" json:"register_time"`
	Alive          *bool      `gorm:"column:alive" json:"alive"`
	CreatedAt      *time.Time `gorm:"column:created_at" json:"created_at"`
	CompanyID      *int64     `gorm:"column:company_id;default:666" json:"company_id"`
	PrivateURL     *string    `gorm:"column:private_url;default:https://a.b.c" json:"private_url"`
	XMLHTTPRequest *string    `gorm:"column:xmlHTTPRequest;default:' '" json:"xmlHTTPRequest"`
	JStr           *string    `gorm:"column:jStr" json:"jStr"`
	Geo            *string    `gorm:"column:geo" json:"geo"`
	Mint           *int32     `gorm:"column:mint" json:"mint"`
	Blank          *string    `gorm:"column:blank;default:' '" json:"blank"`
}

// TableName JustUser's table name
func (*User) TableName() string {
	return TableNameJustUser
}

func (m *User) IsEmpty() bool {
	if m == nil {
		return true
	}
	return m.ID == 0
}

func (m *User) GetName() string {
	if m == nil || m.Name == nil {
		return ""
	}
	return *m.Name
}

```
