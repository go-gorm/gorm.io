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
    
    将GORM从类型名或字段名转换为db名时，采用了类似于 [golint](https://github.com/golang/lint/blob/master/lint.go#L702) 处理`HTTP`和`URI` 缩写的方式。 因此，`HTTP` 的数据库名是 `http` ，而不是 `h_t_t_p`。
    
    但是对于列表中没有的其他缩写，例如`SKU`，db名是 `s_k_u`，此更新修复了该问题。

* 错误`RecordNotFound`已重命名为`ErrRecordNotFound`

* `mssql`被重命名为"github.com/jinzhu/gorm/dialects/mssql"

* `Hstore`已移至"github.com/jinzhu/gorm/dialects/postgres"