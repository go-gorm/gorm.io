---
title: Change Log
layout: page
---

## v2.0

WIP

## v1.0 - 2016.04.27

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
