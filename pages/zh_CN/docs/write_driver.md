---
title: 编写驱动
layout: page
---

GORM 为热门数据库提供内置支持，例如 `SQLite`, `MySQL`, `Postgres`, `SQLServer`,`ClickHouse`.。 当然了，当您需要将 GORM 集成到不直接支持的数据库或具有独特功能的数据库时，您可以创建自定义驱动。 这涉及实现GORM提供的`Dialector ` 接口。

## 兼容 MySQL 或 Postgres 方言

For databases that closely resemble the behavior of `MySQL` or `Postgres`, you can often use the respective dialects directly. However, if your database significantly deviates from these dialects or offers additional features, developing a custom driver is recommended.

## 实现Dialector接口

GORM 中的 `Dialector` 接口包含一组方法，数据库驱动必须实现这些方法，以便在数据库与 GORM 之间进行通信。 让我们来看看怎么实现这些关键方法：

```go
type Dialector interface {
  Name() string                      // Returns the name of the database dialect
  Initialize(*DB) error              // Initializes the database connection
  Migrator(db *DB) Migrator          // Provides the database migration tool
  DataTypeOf(*schema.Field) string   // Determines the data type for a schema field
  DefaultValueOf(*schema.Field) clause.Expression // Provides the default value for a schema field
  BindVarTo(writer clause.Writer, stmt *Statement, v interface{}) // Handles variable binding in SQL statements
  QuoteTo(clause.Writer, string)     // Manages quoting of identifiers
  Explain(sql string, vars ...interface{}) string // Formats SQL statements with variables
}
```

这个接口中的每个方法在 GORM 与数据库的交互中都起着至关重要的作用，从建立连接到处理查询和迁移。

### 嵌套事务支持

如果您的数据库支持保存点，您可以实现 `SavePointerDialectorInterface` 以获得嵌套事务支持和 `SavePoint`支持。

```go
type SavePointerDialectorInterface interface {
    SavePoint(tx *DB, name string) error // 在事务中保存一个保存点
    RollbackTo(tx *DB, name string) error // 将事务回滚到指定的保存点
}
```

通过实现这些方法，您可以启用保存点和嵌套事务的支持，从而提供高级的事务管理功能。

### 自定义子句构建器

在 GORM 中定义自定义子句构建器允许您扩展特定数据库操作的查询功能。 在这个示例中，我们将通过步骤定义一个自定义子句构建器，用于 "LIMIT" 子句，这个子句可能具有特定数据库的行为。

- **第一步: 定义一个自定义子句构建器函数：**

要创建一个自定义子句构建器，您需要定义一个符合 `clause.ClauseBuilder` 接口的函数。 This function will be responsible for constructing the SQL clause for a specific operation. In our example, we'll create a custom "LIMIT" clause builder.

Here's the basic structure of a custom "LIMIT" clause builder function:

```go
func MyCustomLimitBuilder(c clause.Clause, builder clause.Builder) {
    if limit, ok := c.Expression.(clause.Limit); ok {
        // Handle the "LIMIT" clause logic here
        // You can access the limit values using limit.Limit and limit.Offset
        builder.WriteString("MYLIMIT")
    }
}
```

- The function takes two parameters: `c` of type `clause.Clause` and `builder` of type `clause.Builder`.
- Inside the function, we check if the `c.Expression` is a `clause.Limit`. If it is, we proceed to handle the "LIMIT" clause logic.

Replace `MYLIMIT` with the actual SQL logic for your database. This is where you can implement database-specific behavior for the "LIMIT" clause.

- **Step 2: Register the Custom Clause Builder**:

To make your custom "LIMIT" clause builder available to GORM, register it with the `db.ClauseBuilders` map, typically during driver initialization. Here's how to register the custom "LIMIT" clause builder:

```go
func (d *MyDialector) Initialize(db *gorm.DB) error {
    // Register the custom "LIMIT" clause builder
    db.ClauseBuilders["LIMIT"] = MyCustomLimitBuilder

    //...
}
```

In this code, we use the key `"LIMIT"` to register our custom clause builder in the `db.ClauseBuilders` map, associating our custom builder with the "LIMIT" clause.

- **Step 3: Use the Custom Clause Builder**:

After registering the custom clause builder, GORM will call it when generating SQL statements that involve the "LIMIT" clause. You can use your custom logic to generate the SQL clause as needed.

Here's an example of how you can use the custom "LIMIT" clause builder in a GORM query:

```go
query := db.Model(&User{})

// Apply the custom "LIMIT" clause using the Limit method
query = query.Limit(10) // You can also provide an offset, e.g., query.Limit(10).Offset(5)

// Execute the query
result := query.Find(&results)
// SQL: SELECT * FROM users MYLIMIT
```

In this example, we use the Limit method with GORM, and behind the scenes, our custom "LIMIT" clause builder (MyCustomLimitBuilder) will be invoked to handle the generation of the "LIMIT" clause.

For inspiration and guidance, examining the [MySQL Driver](https://github.com/go-gorm/mysql) can be helpful. This driver demonstrates how the `Dialector` interface is implemented to suit the specific needs of the MySQL database.
