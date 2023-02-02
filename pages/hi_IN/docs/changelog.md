---
title: Change Log //लॉग बदलें
layout: पृष्ठ
---

## v2.0 - 2020.08

जीओआरएम 2.0 स्क्रैच से एक पुनर्लेखन(rewrite) है, यह कुछ असंगत-एपीआई (incompatible-API) परिवर्तन और कई सुधार पेश करता है

* Performance Improvements // कार्य में सुधार
* Modularity //प्रतिरूपकता
* Context, Batch Insert, Prepared Statement Mode, DryRun Mode, Join Preload, Find To Map, Create From Map, FindInBatches का समर्थन करता है
* Nested Transaction/SavePoint/RollbackTo SavePoint का समर्थन करता है
* Named Argument, Group Conditions, Upsert, Locking, Optimizer/Index/Comment Hints supports, SubQuery का सुधार
* Full self-reference relationships supports, Join Table improvements, Association Mode for batch data
* Multiple fields support for tracking create/update time, which adds support for UNIX (milli/nano) seconds
* Field permissions support: read-only, write-only, create-only, update-only, ignored
* New plugin system: multiple databases, read/write splitting support with plugin Database Resolver, prometheus integrations...
* New Hooks API: unified interface with plugins
* New Migrator: allows to create database foreign keys for relationships, constraints/checker support, enhanced index support
* New Logger: context support, improved extensibility
* Unified Naming strategy: table name, field name, join table name, foreign key, checker, index name rules
* Better customized data type support (e.g: JSON)

[GORM 2.0 Release Note](v2_release_note.html)

## v1.0 - 2016.04

[GORM V1 Docs](https://v1.gorm.io)

Breaking Changes:

* `gorm.Open` returns `*gorm.DB` instead of `gorm.DB`
* Updating will only update changed fields
* Soft Delete's will only check `deleted_at IS NULL`
* New ToDBName logic Common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` was converted to lowercase, so `HTTP`'s db name is `http`, but not `h_t_t_p`, but for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it to `sku`
* Error `RecordNotFound` has been renamed to `ErrRecordNotFound`
* `mssql` dialect has been renamed to `github.com/jinzhu/gorm/dialects/mssql`
* `Hstore` has been moved to package `github.com/jinzhu/gorm/dialects/postgres`
