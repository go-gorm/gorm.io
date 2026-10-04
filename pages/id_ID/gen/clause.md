---
title: Clauses
layout: page
---

Gen also support GORM Clauses, but unlike raw GORM every expression passed to `Clauses` is validated by a security check before it reaches the query builder (this is a safety guard for the type-safe API).

## Upsert

Gen provides compatible Upsert support for different databases [like GORM](../docs/create.html#upsert)

```go
u := query.User.WithContext(ctx) // query.User exists in gen.WithDefaultQuery mode;
                                 // otherwise use query.Use(db).User.WithContext(ctx)

user := model.User{Name: "Modi", Age: 18, Birthday: time.Now()}

// Save upserts every value; it is variadic:
err := u.Save(&user)
// equivalent to:
err = u.Clauses(clause.OnConflict{UpdateAll: true}).Create(&user)
```

Note that the generated `Save`'s underlying implementation is **different from GORM's** `Save`: it is exactly `Clauses(clause.OnConflict{UpdateAll: true}).Create(values)` (the generated method carries this warning in its own doc comment).

## Which clauses are allowed

Every expression passed to `Clauses` goes through Gen's security check (`gen.CheckClause`) before it reaches the query builder:

| Expression                                                                                                                                             | Constraint                                                                                                                                                                                                                                                                                    |
| ------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `hints.Hints`, `hints.IndexHint` (`gorm.io/hints`)                                                                                                     | always allowed                                                                                                                                                                                                                                                                                |
| `dbresolver.Operation` (`gorm.io/plugin/dbresolver`)                                                                                                   | always allowed                                                                                                                                                                                                                                                                                |
| `clause.OnConflict`                                                                                                                                    | `DoUpdates` assignments must not use `gorm.Expr` (`OnConflict clause assignment with gorm.Expr is banned for security reasons`)                                                                                                                                                               |
| `clause.Locking`                                                                                                                                       | `Strength` (upper-cased, whitespace-trimmed) only `UPDATE` or `SHARE`; `Options` empty, `NOWAIT` or `SKIP LOCKED` (same normalization); `Table.Raw` must be false                                                                                                                             |
| `clause.Insert`                                                                                                                                        | `Table.Raw` must be false; `Modifier` must be empty, `IGNORE`, or `<priority> IGNORE` where `<priority>` is `LOW_PRIORITY`/`DELAYED`/`HIGH_PRIORITY` (upper-cased and trimmed; a priority **without** `IGNORE` is rejected — the parser reads the first token as the ignore slot) |
| any other named `clause.Interface` whose `Name()` is `VALUES`, `SELECT`, `FROM`, `WHERE`, `GROUP BY`, `ORDER BY`, `LIMIT`, `UPDATE`, `SET` or `DELETE` | **banned** (`clause <name> is banned`) — those parts of the statement belong to the type-safe API                                                                                                                                                                                       |
| any other named `clause.Interface`                                                                                                                     | accepted (its name is not on the deny-list)                                                                                                                                                                                                                                                   |
| expressions that are not named `clause.Interface` values (raw fragments, arbitrary types)                                                              | rejected with `unknown clause <value>`                                                                                                                                                                                                                                                  |

Note the boundary: this is a name deny-list plus a few structural checks, not a proof that every accepted named clause is safe for your query — pass clauses from GORM's own `clause` package and the supported plugin packages above, not hand-rolled expressions or raw SQL fragments.

A rejected clause does not panic: the error is attached to the statement (`AddError`) and surfaces from the finishing method (`Find`, `Create`, …) like any query error.

## Hints

Optimizer hints allow to control the query optimizer to choose a certain query execution plan, GORM supports it with [gorm.io/hints](../docs/hints.html), e.g:

```go
import "gorm.io/hints"

u := query.Use(db).User

users, err := u.WithContext(ctx).Clauses(hints.New("MAX_EXECUTION_TIME(10000)")).Find()
// SELECT * /*+ MAX_EXECUTION_TIME(10000) */ FROM `users`
```

Index hints allow passing index hints to the database in case the query planner gets confused.

```go
import "gorm.io/hints"

u := query.Use(db).User

users, err := u.WithContext(ctx).Clauses(hints.UseIndex("idx_user_name")).Find()
// SELECT * FROM `users` USE INDEX (`idx_user_name`)

users, err := u.WithContext(ctx).Clauses(hints.ForceIndex("idx_user_name", "idx_user_id").ForJoin()).Find()
// SELECT * FROM `users` FORCE INDEX FOR JOIN (`idx_user_name`,`idx_user_id`)
```

## Custom clause validation

`query.Use(db, opts...)` / `query.SetDefault(db, opts...)` accept `gen.DOOption`s. `gen.WithClauseChecker` installs a custom validator that runs **before** the built-in check:

* return `nil` → the clause is accepted, skipping the built-in check;
* return `gen.ErrClauseNotHandled` → fall back to the built-in check;
* return any other error → the clause is rejected with your error.

```go
query.SetDefault(db, gen.WithClauseChecker(func(expr clause.Expression) error {
    if _, ok := expr.(clause.Locking); ok {
        return errors.New("row locking is disabled in this service")
    }
    return gen.ErrClauseNotHandled // everything else: default rules
}))
```

The built-in rules are also available programmatically as `gen.CheckClause(expr) error`.

Every generated DO also exposes `ReadDB()` / `WriteDB()` to route the statement through [dbresolver](https://github.com/go-gorm/dbresolver) read/write pools, and `Returning(value, columns...)` for PostgreSQL-style `RETURNING`.
