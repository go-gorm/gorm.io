---
title: Объявление моделей
layout: страница
---

## Объявление моделей

Models are normal structs with basic Go types, pointers/alias of them or custom types implementing [Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner) and [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) interfaces

Например:

```go
type User struct {
  ID           uint
  Name         string
  Email        *string
  Age          uint8
  Birthday     *time.Time
  MemberNumber sql.NullString
  ActivedAt    sql.NullTime
  CreatedAt    time.Time
  UpdatedAt    time.Time
}
```

## Преобразования

По умолчанию, GORM использует в качестве первичного ключа `ID`, преобразует имя struct в `snake_cases` в качестве имени таблицы, `snake_case` в качестве имени столбца и использует `CreatedAt`, `UpdatedAt` для отслеживания времени создания/обновления

Если вы следуете правилам, принятым GORM, вам нужно написать очень мало конфигурации/кода, Если правила не соответствует вашим требованиям, [GORM позволяет настроить их](conventions.html)

## gorm.Model

GORM определил struct `gorm.Model`, который включает в себя поля `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`

```go
// объявление gorm.Model
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

Вы можете вставить его (gorm.Model) в свой struct, чтобы включить эти поля, смотрите [Встроенный struct](#embedded_struct)

## Дополнительно

### Разрешения на уровне поля

Exported fields have all permission when doing CRUD with GORM, and GORM allows you to change the field-level permission with tag, so you can make a field to be read-only, write-only, create-only, update-only or ignored

{% note warn %}
**NOTE** ignored fields won't be created when using GORM Migrator to create table
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // allow read and create
  Name string `gorm:"<-:update"` // allow read and update
  Name string `gorm:"<-"`        // allow read and write (create and update)
  Name string `gorm:"<-:false"`  // allow read, disable write permission
  Name string `gorm:"->"`        // readonly (disable write permission unless it configured )
  Name string `gorm:"->;<-:create"` // allow read and create
  Name string `gorm:"->:false;<-:create"` // createonly (disabled read from db)
  Name string `gorm:"-"`  // ignore this field when write and read
}
```

### <name id="time_tracking">Создание/обновление Time/Unix (Milli/Nano) секунд отслеживания</span>

GORM use `CreatedAt`, `UpdatedAt` to track creating/updating time by convention, and GORM will fill [current time](gorm_config.html#now_func) into it when creating/updating if they are defined

To use fields with a different name, you can configure those fields with tag `autoCreateTime`, `autoUpdateTime`

If you prefer to save UNIX (milli/nano) seconds instead of time, you can simply change the field's data type from `time.Time` to `int`

```go
type User struct {
  CreatedAt time.Time // Set to current time if it is zero on creating
  UpdatedAt int       // Set to current unix seconds on updaing or if it is zero on creating
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Use unix nano seconds as updating time
  Updated   int64 `gorm:"autoUpdateTime:milli"`// Use unix milli seconds as updating time
  Created   int64 `gorm:"autoCreateTime"`      // Use unix seconds as creating time
}
```

### <span id="embedded_struct">Встроенный struct</span>

For anonymous fields, GORM will include its fields into its parent struct, for example:

```go
type User struct {
  gorm.Model
  Name string
}
// equals
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
}
```

For a normal struct field, you can embed it with the tag `embedded`, for example:

```go
type Author struct {
    Name  string
    Email string
}

type Blog struct {
  ID      int
  Author  Author `gorm:"embedded"`
  Upvotes int32
}
// equals
type Blog struct {
  ID    int64
    Name  string
    Email string
  Upvotes  int32
}
```

And you can use tag `embeddedPrefix` to add prefix to embedded fields' db name, for example:

```go
type Blog struct {
  ID      int
  Author  Author `gorm:"embedded;embeddedPrefix:author_"`
  Upvotes int32
}
// equals
type Blog struct {
  ID          int64
    AuthorName  string
    AuthorEmail string
  Upvotes     int32
}
```


### <span id="tags">Fields Tags</span>

Tags are optional to use when declaring models, GORM supports the following tags: Tag name case doesn't matter, `camelCase` is preferred to use.

| Назвние тэга   | Описание                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column         | название столбца                                                                                                                                                                                                                                                                                                                                                                                                                              |
| type           | column data type, prefer to use compatible general type, e.g: bool, int, uint, float, string, time, bytes, which works for all databases, and can be used with other tags together, like `not null`, `size`, `autoIncrement`... specified database data type like `varbinary(8)` also supported, when using specified database data type, it needs to be a full database data type, for example: `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| size           | задает размер/длину столбца, например: `size:256`                                                                                                                                                                                                                                                                                                                                                                                             |
| primaryKey     | указать столбец в качестве первичного ключа                                                                                                                                                                                                                                                                                                                                                                                                   |
| unique         | указать столбец как уникальный                                                                                                                                                                                                                                                                                                                                                                                                                |
| default        | задает значение столбца по умолчанию                                                                                                                                                                                                                                                                                                                                                                                                          |
| precision      | определяет точность столбца                                                                                                                                                                                                                                                                                                                                                                                                                   |
| scale          | specifies column scale                                                                                                                                                                                                                                                                                                                                                                                                                        |
| not null       | specifies column as NOT NULL                                                                                                                                                                                                                                                                                                                                                                                                                  |
| autoIncrement  | specifies column auto incrementable                                                                                                                                                                                                                                                                                                                                                                                                           |
| embedded       | embed the field                                                                                                                                                                                                                                                                                                                                                                                                                               |
| embeddedPrefix | column name prefix for embedded fields                                                                                                                                                                                                                                                                                                                                                                                                        |
| autoCreateTime | track current time when creating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoCreateTime:nano`                                                                                                                                                                                                                                                                         |
| autoUpdateTime | track current time when creating/updating, for `int` fields, it will track unix seconds, use value `nano`/`milli` to track unix nano/milli seconds, e.g: `autoUpdateTime:milli`                                                                                                                                                                                                                                                               |
| index          | create index with options, use same name for multiple fields creates composite indexes, refer [Indexes](indexes.html) for details                                                                                                                                                                                                                                                                                                             |
| uniqueIndex    | same as `index`, but create uniqued index                                                                                                                                                                                                                                                                                                                                                                                                     |
| check          | creates check constraint, eg: `check:age > 13`, refer [Constraints](constraints.html)                                                                                                                                                                                                                                                                                                                                                      |
| <-             | set field's write permission, `<-:create` create-only field, `<-:update` update-only field, `<-:false` no write permission, `<-` create and update permission                                                                                                                                                                                                                                                                     |
| ->             | set field's read permission, `->:false` no read permission                                                                                                                                                                                                                                                                                                                                                                                 |
| -              | ignore this fields, `-` no read/write permission                                                                                                                                                                                                                                                                                                                                                                                              |

### Взаимосвязи

GORM allows configure foreign keys, constraints, many2many table through tags for Associations, check out the [Associations section](associations.html#tags) for details
