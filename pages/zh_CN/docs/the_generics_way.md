---
title: The Generics Way to Use GORM
layout: page
---

GORM has officially introduced support for **Go Generics** in its latest version (>= `v1.30.0`). 为日常开发带来了更高的可用性与类型安全，并避免 SQL 污染风险等等。 此外，我们还优化了 Joins 和 Preload 的功能表现，并新增事务超时处理机制，以帮助开发者更好地应对连接泄漏等常见异常场景。

本次更新在保持原有 API 完全兼容的前提下，较为克制地引入了泛型接口。 你可以在项目中灵活混用传统与泛型两种接口形式，只需在新代码中引入泛型方式，无需担心与现有逻辑或 GORM 插件（如数据加解密、分库分表、读写分离、Tracing 等）之间的兼容性问题。

为了避免误用，我们在泛型版本中有意移除了一些容易引发歧义或并发问题的接口，如 `FirstOrCreate`、`Save` 等。 同时，我们也在规划全新的 `gorm` 命令行工具，未来将提供更强的代码生成、类型安全支持、静态检查 (lint) 能力，进一步减少误用带来的风险。

我们强烈建议你在新项目或重构工作中优先采用泛型版本接口，以获得更好的开发体验、更强的类型保障，以及更易维护的代码结构。

## Generic APIs

GORM 泛型接口与原接口功能基本不变。 以下是一些最常用操作在泛型接口下的写法：

```go
ctx := context.Background()

// 创建记录
gorm.G[User](db).Create(ctx, &User{Name: "Alice"})
gorm.G[User](db).CreateInBatches(ctx, users, 10)

// 查询记录
user, err := gorm.G[User](db).Where("name = ?", "Jinzhu").First(ctx)
users, err := gorm.G[User](db).Where("age <= ?", 18).Find(ctx)

// 更新记录
gorm.G[User](db).Where("id = ?", u.ID).Update(ctx, "age", 18)
gorm.G[User](db).Where("id = ?", u.ID).Updates(ctx, User{Name: "Jinzhu", Age: 18})

// 删除记录
gorm.G[User](db).Where("id = ?", u.ID).Delete(ctx)
```

泛型接口也完整支持 GORM 的高级特性，通过可选参数传入子句(clause)或插件(plugin)扩展，示例如下。

```go
// OnConflict：插入冲突时的异常
err := gorm.G[Language](DB, clause.OnConflict{DoNothing: true}).Create(ctx, &lang)
err := gorm.G[Language](DB, clause.OnConflict{
  Columns:   []clause.Column{{Name: "id"}},
  DoUpdates: clause.Assignments(map[string]interface{}{"count": gorm.Expr("GREATEST(count, VALUES(count))")}),
}).Create(ctx, &lang)

// Hints 执行计划
err := gorm.G[User](DB,
  hints.New("MAX_EXECUTION_TIME(100)"),
  hints.New("USE_INDEX(t1, idx1)"),
).Find(ctx)
// SELECT /*+ MAX_EXECUTION_TIME(100) USE_INDEX(t1, idx1) */ * FROM `users`

// 读写分离，强制使用写库进行读操作
err := gorm.G[User](DB, dbresolver.Write).Find(ctx)

// 获取原始执行结果信息
result := gorm.WithResult()
err := gorm.G[User](DB, result).CreateInBatches(ctx, &users, 2)
// result.RowsAffected
// result.Result.LastInsertId()
```

## Joins / Preload 介绍

新版 GORM 泛型接口在关联查询(Joins)与预加载(Preload)方面进行了增强，支持更灵活的关联方式、更强大的查询表达能力，并显著简化了复杂查询的构造流程。

- **Joins 接口**: 轻松指定不同的 Join 类型(如 InnerJoin、LeftJoin 等)，同时支持基于关联关系自定义 Join 条件，使复杂的跨表查询更加简洁直观。

```go
// 只加载拥有公司信息的用户
users, err := gorm.G[User](db).Joins(clause.Has("Company"), nil).Find(ctx)

// 使用 Left Join 并自定义关联表的过滤条件
user, err = gorm.G[User](db).Joins(clause.LeftJoin.Association("Company"), func(db gorm.JoinBuilder, joinTable clause.Table, curTable clause.Table) error {
    db.Where(map[string]any{"name": company.Name})
    return nil
}).Where(map[string]any{"name": user.Name}).First(ctx)

// 从 SubQuery 中构建 Join
users, err = gorm.G[User](db).Joins(clause.LeftJoin.AssociationFrom("Company", gorm.G[Company](DB).Select("Name")).As("t"),
    func(db gorm.JoinBuilder, joinTable clause.Table, curTable clause.Table) error {
        db.Where("?.name = ?", joinTable, u.Company.Name)
        return nil
    },
).Find(ctx)
```

- **Preload 接口**: 简化自定义查询条件流程，新增了 `LimitPerRecord` 选项，允许在预加载集合关联时为每条主记录限制子项数量。

```go
// 普通的关联加载
users, err := gorm.G[User](db).Preload("Friends", func(db gorm.PreloadBuilder) error {
    db.Where("age > ?", 14)
    return nil
}).Where("age > ?", 18).Find(ctx)

// 预加载朋友及其宠物
users, err := gorm.G[User](db).Preload("Friends.Pets", nil).Where("age > ?", 18).Find(ctx)

// 预加载朋友及其宠物信息，年龄从大到小排序，每个朋友最多预加载 2 个宠物
users, err = gorm.G[User](db).Preload("Friends", func(db gorm.PreloadBuilder) error {
    db.Select("id", "name").Order("age desc")
    return nil
}).Preload("Friends.Pets", func(db gorm.PreloadBuilder) error {
    db.LimitPerRecord(2)
    return nil
}).Find(ctx)
```

## Complex Raw SQL

GORM 泛型版本依然支持通过 Raw 方法执行原始 SQL 查询，适用于某些非常规或复杂语句的场景：

```go
users, err := gorm.G[User](DB).Raw("SELECT name FROM users WHERE id = ?", user.ID).Find(ctx)
```

不过，我们更推荐使用全新的代码生成工具来实现类型安全、可维护性强的原生查询，避免手写 SQL 带来的易错和 SQL 注入等风险。

### 代码生成工具使用流程

- **1. 安装命令行工具**

```bash
go install gorm.io/cmd/gorm@latest
```

- **2. 定义查询接口**

你只需将查询接口定义为标准的 Go interface，通过注释或模板语法标注 SQL，生成器将自动生成类型安全的实现：

```go
type Query[T any] interface {
	// GetByID queries data by ID and returns it as a struct.
	//
	// SELECT * FROM @@table WHERE id=@id
	GetByID(id int) (T, error)

	// SELECT * FROM @@table WHERE @@column=@value
	FilterWithColumn(column string, value string) (T, error)

	// SELECT * FROM users
	//   {{if user.ID > 0}}
	//       WHERE id=@user.ID
	//   {{else if user.Name != ""}}
	//       WHERE username=@user.Name
	//   {{end}}
	QueryWith(user models.User) (T, error)

	// UPDATE @@table
	//  {{set}}
	//    {{if user.Name != ""}} username=@user.Name, {{end}}
	//    {{if user.Age > 0}} age=@user.Age, {{end}}
	//    {{if user.Age >= 18}} is_adult=1 {{else}} is_adult=0 {{end}}
	//  {{end}}
	// WHERE id=@id
	Update(user models.User, id int) error

	// SELECT * FROM @@table
	// {{where}}
	//   {{for _, user := range users}}
	//     {{if user.Name != "" && user.Age > 0}}
	//       (username = @user.Name AND age=@user.Age AND role LIKE concat("%",@user.Role,"%")) OR
	//     {{end}}
	//   {{end}}
	// {{end}}
	Filter(users []models.User) ([]T, error)

	// where("name=@name AND age=@age")
	FilterByNameAndAge(name string, age int)

	// SELECT * FROM @@table
	//  {{where}}
	//    {{if !start.IsZero()}}
	//      created_time > @start
	//    {{end}}
	//    {{if !end.IsZero()}}
	//      AND created_time < @end
	//    {{end}}
	//  {{end}}
	FilterWithTime(start, end time.Time) ([]T, error)
}
```

- **3. 运行代码生成命令**

```bash
gorm gen -i ./examples/example.go -o query
```

- **4. 调用生成的查询 API**

```go
import "your_project/query"

company, err := query.Query[Company].GetByID(ctx, 10)
// SELECT * FROM `companies` WHERE id=10
user, err := query.Query[User].GetByID(ctx, 10)
// SELECT * FROM `users` WHERE id=10

// Combine with other Generic APIs
err := query.Query[User].FilterByNameAndAge("jinzhu", 18).Delete(ctx)
// DELETE FROM `users` WHERE name='jinzhu' AND age=18

users, err := query.Query[User].FilterByNameAndAge("jinzhu", 18).Find(ctx)
// SELECT * FROM `users` WHERE name='jinzhu' AND age=18
```

## Summary

本次发布是 GORM 在泛型支持与全新 `gorm` 命令工具方向上的新一步。 该系列功能我们已筹划许久，此次终于得以抽出时间，将其初步落地并面向社区发布。

接下来，我们将持续优化和迭代泛型 API 体系、全新 `gorm` 命令工具，并重构和完善 gorm.io 的官方文档，为开发者带来更清晰、更高效的使用体验。

感谢 GORM 多年来众多使用者与 Sponsors 的支持。 GORM 过去 12 年的发展与你们离不开你们的支持 ❤️
