---
title: 更新日志
layout: page
---

## v2.0 - 2020.07

GORM 2.0 是根据我们在过去几年里收到的反馈从零重写的，它引入了一些不兼容的 API 更改和许多改进

* 性能改进
* 模块化
* Context、批量插入、Prepared Statment、DryRun 模式、Join Preload、Find To Map、FindInBatches
* SavePoint、RollbackTo、嵌套事务
* 关联改进（删除、更新时），修改 Many2Many 的连接表，批量数据关联模式
* SQL 构建器、Upsert、Locking 和 Optimizer、Index、Comment 提示
* 支持多个字段的自动追踪创建、更新时间，且支持纳秒级、毫秒级、秒级时间戳
* 字段级权限控制：只读、只写、只创建、只更新、忽略
* 全新的 Migrator、Logger
* 命名策略(统一表名、字段名、连接表名、外键、检查器、索引名称规则)
* 更好的自定义数据类型支持（例如：JSON）
* 全新的插件系统、Hooks API

## v1.0 - 2016.04

[GORM V1 文档](https://v1.gorm.io)

破坏性变更

* `gorm.Open` 返回类型是 `*gorm.DB` 而不是 `gorm.DB`

* Update 只会更新有变更的字段

* 开启软删除后，默认只会检查 `deleted_at IS NULL` 的记录

* 新的 ToDBName 逻辑

  当 GORM 将 struct、字段转换为数据库名时，采用了类似于 [golint](https://github.com/golang/lint/blob/master/lint.go#L702) 处理 `HTTP` 和 `URI` 缩写的方式。因此，`HTTP` 的数据库名是 `http` ，而不是 `h_t_t_p`。

  但是对于列表中没有的其他缩写，例如但是对于列表中没有的其他缩写，例如`SKU`，db名是 `s_k_u`，此次更新修复了该问题。

* `RecordNotFound ` 错误已被重命名为 `ErrRecordNotFound `

* `mssql` 已被重命名为 ”github.com/jinzhu/gorm/dialects/mssql”

* `Hstore` 已移至 ”github.com/jinzhu/gorm/dialects/postgres”
