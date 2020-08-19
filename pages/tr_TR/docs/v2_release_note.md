---
title: GORM 2.0 Release Note (Draft)
layout: page
---

<style>
li.toc-item.toc-level-4 { display: none; }
</style>

GORM 2.0 is a rewrite from scratch, it introduces some incompatible-API change and many improvements

**Highlights**

* Performance Improvements
* Modularity
* Context, Batch Insert, Prepared Statment Mode, DryRun Mode, Join Preload, Find To Map, Create From Map, FindInBatches supports
* Nested Transaction/SavePoint/RollbackTo SavePoint supports
* Named Argument, Group Conditions, Upsert, Locking, Optimizer/Index/Comment Hints supports, SubQuery improvements
* Full self-reference relationships supports, Join Table improvements, Association Mode for batch data
* Multiple fields support for tracking create/update time, which adds support for UNIX (milli/nano) seconds
* Field permissions support: read-only, write-only, create-only, update-only, ignored
* New plugin system: read/write splitting with plugin Database Resolver, prometheus integrations...
* New Hooks API: unified interface with plugins
* New Migrator: allows to create database foreign keys for relationships, constraints/checker support, enhanced index support
* New Logger: context support, improved extensibility
* Unified Naming strategy: table name, field name, join table name, foreign key, checker, index name rules
* Better customized data type support (e.g: JSON)

## How To Upgrade

* GORM's developments moved to [github.com/go-gorm](https://github.com/go-gorm), and the import path changed to `gorm.io/gorm`, for previous projects, you can keep using `github.com/jinzhu/gorm`
* Database drivers have been split into separate projects, e.g: [github.com/go-gorm/sqlserver](https://github.com/go-gorm/sqlserver), and its import path also changed

### Install

```sh
go get gorm.io/gorm
```

### Quick Start

```go
import (
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
)

func init() {
  db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})

  // Most CRUD API kept compatibility
  db.AutoMigrate(&Product{})
  db.Create(&user)
  db.First(&user, 1)
  db.Model(&user).Update("Age", 18)
  db.Model(&user).Omit("Role").Updates(map[string]interface{}{"Name": "jinzhu", "Role": "admin"})
  db.Delete(&user)
}
```

## Major Features

## Breaking Changes

## Happy Hacking!
