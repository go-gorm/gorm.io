---
title: Change log
layout: page
---

## v2.0 - 2020.07

GORM 2.0 wurde von Grund auf neu geschrieben, basierend auf dem Feedback, welches wir über die letzten Jahre erhalten habe. Es enthält einige nicht-abwärtskompatible Änderungen an der API und viele Verbesserungen

* Verbesserung der Geschwindigkeit
* Modularität
* Context, Batch Insert, Prepared Statment, DryRun Mode, Join Preload, Find To Map, FindInBatches
* Unterstützung für SavePoint / RollbackTo / Nested Transaction
* Association improvements (On Delete/Update), Modify Join Table for Many2Many, Association Mode for batch data
* Unterstützung für SQL Builder, Upsert, Locking, Optimizer / Index / Comment Hints
* Multiple fields support for auto-creating/updating time, which also support UNIX (nano) seconds
* Field permissions support: read-only, write-only, create-only, update-only, ignored
* All new Migrator, Logger
* Naming strategy (Unified table name, field name, join table name, foreign key, checker, index name rule)
* Better customized data type support (e.g: JSON)
* All new plugin system, Hooks API

## v1.0 - 2016.04

[GORM V1 Docs](https://v1.gorm.io)

Breaking Changes

* `gorm.Open` return type `*gorm.DB` instead of `gorm.DB`

* Updating will only update changed fields

* Soft Delete's will only check `deleted_at IS NULL`

* New ToDBName logic

  When GORM convert struct, field name to db name, only common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` were handled, so `HTTP`'s db name is `http`, but not `h_t_t_p`.

  But for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it.

* Error `RecordNotFound` has been renamed to `ErrRecordNotFound`

* `mssql` dialect has been renamed to "github.com/jinzhu/gorm/dialects/mssql"

* `Hstore` has been moved to package "github.com/jinzhu/gorm/dialects/postgres"
