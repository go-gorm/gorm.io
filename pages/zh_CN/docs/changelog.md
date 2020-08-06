---
title: 更新日志
layout: page
---

## v2.0 - 2020.07

GORM 2.0 是根据我们在过去几年里收到的反馈从零重写的，它引入了一些不兼容的 API 更改和许多改进

* Performance Improvements
* Modularity
* Context, Batch Insert, Prepared Statment, DryRun Mode, Join Preload, Find To Map, FindInBatches
* SavePoint/RollbackTo/Nested Transaction Support
* Association improvements (On Delete/Update), Modify Join Table for Many2Many, Association Mode for batch data
* SQL Builder, Upsert, Locking, Optimizer/Index/Comment Hints supports
* Multiple fields support for auto-creating/updating time, which also support UNIX (nano) seconds
* Field permissions support: read-only, write-only, create-only, update-only, ignored
* All new Migrator, Logger
* Naming strategy (Unified table name, field name, join table name, foreign key, checker, index name rule)
* Better customized data type support (e.g: JSON)
* All new plugin system, Hooks API

## v1.0 - 2016.04

[GORM V1 文档](https://v1.gorm.io)

破坏性变更

* `gorm.Open` 返回类型是 `*gorm.DB` 而不是 `gorm.DB`

* Update 只会更新有变更的字段

* 开启软删除后，默认只会检查 `deleted_at IS NULL` 的记录

* 新的 ToDBName 逻辑

  当 GORM 将 struct、字段转换为数据库名时，采用了类似于 [golint](https://github.com/golang/lint/blob/master/lint.go#L702) 处理 `HTTP` 和 `URI` 缩写的方式。因此，`HTTP` 的数据库名是 `http` ，而不是 `h_t_t_p`。

  But for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it.

* Error `RecordNotFound` has been renamed to `ErrRecordNotFound`

* `mssql` dialect has been renamed to "github.com/jinzhu/gorm/dialects/mssql"

* `Hstore` has been moved to package "github.com/jinzhu/gorm/dialects/postgres"
