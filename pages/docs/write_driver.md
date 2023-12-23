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

For inspiration and guidance, examining the [MySQL Driver](https://github.com/go-gorm/mysql) can be helpful. This driver shows how the `Dialector` interface is implemented to suit the specific needs of the MySQL database.
