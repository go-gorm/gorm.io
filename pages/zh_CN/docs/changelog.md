---
title: 更新日志
layout: page
---

## v2.0 - 2020.08

GORM 2.0 是基于用户过去几年中的反馈进行思考后的重写，在该发行版本中将会引入不兼容 API 改动。

* 性能优化
* 代码模块化
* Context, Batch Insert, Prepared Statement Mode, DryRun Mode, Join Preload, Find To Map, Create From Map, FindInBatches supports
* SavePoint/RollbackTo/Nested Transaction 支持
* 命名参数、Group 条件、Upsert、锁定、优化/索引/评论提示支持、SubQuery 改进
* 完整的自引用支持，连接表改进，批量数据的关联模式
* 插入时间、更新时间可支持多个字段，加入了对 unix (nano) second 的支持
* 字段级权限控制：只读、只写、只创建、只更新、忽略
* 全新的插件系统：多数据库，由 Database Resolver 提供的读写分离支持，Prometheus 集成，以及更多...
* 全新的 Hook API：带插件的统一接口
* 全新的 Migrator：允许为关系创建数据库外键，约束、检查其支持，增强索引支持
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
