---
title: Write Driver
layout: page
---

## Writing a New Driver

GORM provides built-in support for popular databases like `SQLite`, `MySQL`, `Postgres`, `SQLServer` and `ClickHouse`. However, to integrate GORM with other databases, especially those not directly supported or that have unique features, you can write a custom driver. This process involves implementing the `Dialector` interface provided by GORM.

### Compatibility with MySQL or Postgres Dialects

For databases that are largely compatible with `MySQL` or `Postgres`, you can often use their respective dialects directly. However, if there are significant differences or additional features, writing a custom driver is advisable.

### Implementing the Dialector Interface

The `Dialector` interface in GORM is a set of methods that a database driver must implement to enable communication between the database and GORM. Here's a breakdown of the interface methods:

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

Each method in this interface plays a crucial role in how GORM interacts with the database, from initializing connections to handling queries and migrations.

### Steps to Write a New Driver

1. **Understand Database Specifics**: Familiarize yourself with the database's querying language, data types, and specific features or constraints.
2. **Implement Dialector Methods**: Based on the database specifics, implement each method in the `Dialector` interface. Ensure that your implementation correctly handles all the operations that GORM performs.
3. **Test the Driver**: Rigorously test the driver to ensure it handles all typical ORM operations, including CRUD actions, migrations, transactions, and advanced queries.
4. **Optimize and Refine**: Optimize the driver for performance and ensure it adheres to best practices in handling database interactions.
5. **Document Usage**: Provide clear documentation on how to use the driver, including setup, configuration, and any database-specific considerations.

For inspiration and guidance, examining the [MySQL Driver](https://github.com/go-gorm/mysql) can be helpful. This driver shows how the `Dialector` interface is implemented to suit the specific needs of the MySQL database.
