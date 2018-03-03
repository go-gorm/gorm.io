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

* 新しい ToDBName ロジック
    
    When GORM convert struct, field name to db name, only common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` were handled, so `HTTP`'s db name is `http`, but not `h_t_t_p`.
    
    しかし、 `SKU`のように一覧ではなく、他のドイツ語のそれの db 名は `s_k_u`、この変更は、それを修正します。

* エラー `RecordNotFound` `ErrRecordNotFound` に改名します。

* `mssql` dialect has been renamed to "github.com/jinzhu/gorm/dialects/mssql"

* `Hstore` 「github.com/jinzhu/gorm/dialects/postgres」パッケージに移動しました