---
title: 更新日志
layout: page
---

## v2.0 - 2020.08

GORM 2.0 是基于用户过去几年中的反馈进行思考后的重写，在该发行版本中将会引入不兼容 API 改动。

* 性能优化
* 代码模块化
* Context、批量插入、Prepared Statment、DryRun 模式、Join Preload, Find 到 Map, FindInBatches 支持
* SavePoint/RollbackTo/Nested Transaction 支持
* Named Argument, Group Conditions, Upsert, Locking, Optimizer/Index/Comment Hints supports, SubQuery improvements
* Full self-reference relationships supports, Join Table improvements, Association Mode for batch data
* Multiple fields support for tracking create/update time, which adds support for UNIX (milli/nano) seconds
* 字段级权限控制：只读、只写、只创建、只更新、忽略
* New plugin system: read/write splitting with plugin Database Resolver, prometheus integrations...
* New Hooks API: unified interface with plugins
* New Migrator: allows to create database foreign keys for relationships, constraints/checker support, enhanced index support
* 全新的 Logger：context 支持、提高可扩展性
* 统一命名策略（表名、字段名、连接表名、外键、检查器、索引名称规则）
* 更好的数据类型定义支持（例如 JSON）

[GORM 2.0 Release Note](v2_release_note.html)

## v1.0 - 2016.04

[GORM V1 文档](https://v1.gorm.io)

破坏性变更:

* `gorm.Open` 返回类型是 `*gorm.DB` 而不是 `gorm.DB`
* Update 只会更新有变更的字段
* 开启软删除后，默认只会检查 `deleted_at IS NULL` 的记录
* 根据 [golint](https://github.com/golang/lint/blob/master/lint.go#L702) 实现的新 ToDBname 初始化逻辑，例如 `HTTP`、`URI` 会被转换为小写，`HTTP` 其 db 名称为 `http` 而不是 `h_t_t_p`，但对于列表中不包含的其他初始值，例如 `SKU`，其 db 名称依然为 `s_k_u`，而此更新已将其修正为 `sku`
* `RecordNotFound ` 错误已被重命名为 `ErrRecordNotFound `
* `mssql` 已被重命名为 `github.com/jinzhu/gorm/dialects/mssql`
* `Hstore` 已移至 `github.com/jinzhu/gorm/dialects/postgres`
