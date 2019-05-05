---
title: 更改日志
layout: page
---

## v2.0

制作中

## v1.0 - 2016.04.27

破坏性变更

* `gorm.Open`返回类型为`*gorm.DB`而不是`gorm.DB`

* 更新只会更新更改的字段

* 软删除的默认查询作用域只会检查 `deleted_at IS NULL`

* 新的ToDBName逻辑
    
    When GORM convert struct, field name to db name, only common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` were handled, so `HTTP`'s db name is `http`, but not `h_t_t_p`.
    
    But for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it.

* 错误`RecordNotFound`已重命名为`ErrRecordNotFound`

* `mssql`被重命名为"github.com/jinzhu/gorm/dialects/mssql"

* `Hstore`已移至"github.com/jinzhu/gorm/dialects/postgres"