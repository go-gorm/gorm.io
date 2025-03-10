---
title: Объявление моделей
layout: страница
---

GORM simplifies database interactions by mapping Go structs to database tables. Understanding how to declare models in GORM is fundamental for leveraging its full capabilities.

## Объявление моделей

Models are defined using normal structs. These structs can contain fields with basic Go types, pointers or aliases of these types, or even custom types, as long as they implement the [Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner) and [Valuer](https://pkg.go.dev/database/sql/driver#Valuer) interfaces from the `database/sql` package

Consider the following example of a `User` model:

```go
type User struct {
  ID           uint           // Standard field for the primary key
  Name         string         // A regular string field
  Email        *string        // A pointer to a string, allowing for null values
  Age          uint8          // An unsigned 8-bit integer
  Birthday     *time.Time     // A pointer to time.Time, can be null
  MemberNumber sql.NullString // Uses sql.NullString to handle nullable strings
  ActivatedAt  sql.NullTime   // Uses sql.NullTime for nullable time fields
  CreatedAt    time.Time      // Automatically managed by GORM for creation time
  UpdatedAt    time.Time      // Automatically managed by GORM for update time
  ignored      string         // fields that aren't exported are ignored
}
```

In this model:

- Basic data types like `uint`, `string`, and `uint8` are used directly.
- Pointers to types like `*string` and `*time.Time` indicate nullable fields.
- `sql.NullString` and `sql.NullTime` from the `database/sql` package are used for nullable fields with more control.
- `CreatedAt` and `UpdatedAt` are special fields that GORM automatically populates with the current time when a record is created or updated.
- Non-exported fields (starting with a small letter) are not mapped

In addition to the fundamental features of model declaration in GORM, it's important to highlight the support for serialization through the serializer tag. This feature enhances the flexibility of how data is stored and retrieved from the database, especially for fields that require custom serialization logic, See [Serializer](serializer.html) for a detailed explanation

### Преобразования

1. **Primary Key**: GORM uses a field named `ID` as the default primary key for each model.

2. **Table Names**: By default, GORM converts struct names to `snake_case` and pluralizes them for table names. For instance, a `User` struct becomes `users` in the database, and a `GormUserName` becomes `gorm_user_names`.

3. **Column Names**: GORM automatically converts struct field names to `snake_case` for column names in the database.

4. **Timestamp Fields**: GORM uses fields named `CreatedAt` and `UpdatedAt` to automatically track the creation and update times of records.

Following these conventions can greatly reduce the amount of configuration or code you need to write. However, GORM is also flexible, allowing you to customize these settings if the default conventions don't fit your requirements. You can learn more about customizing these conventions in GORM's documentation on [conventions](conventions.html).

### `gorm.Model`

GORM provides a predefined struct named `gorm.Model`, which includes commonly used fields:

```go
// объявление gorm.Model
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

- **Embedding in Your Struct**: You can embed `gorm.Model` directly in your structs to include these fields automatically. This is useful for maintaining consistency across different models and leveraging GORM's built-in conventions, refer [Embedded Struct](#embedded_struct)

- **Fields Included**:
  - `ID`: A unique identifier for each record (primary key).
  - `CreatedAt`: Automatically set to the current time when a record is created.
  - `UpdatedAt`: Automatically updated to the current time whenever a record is updated.
  - `DeletedAt`: Used for soft deletes (marking records as deleted without actually removing them from the database).

## Дополнительно

### <span id="field_permission">Разрешение для каждого поля</span>

Экспортированные поля имеют все разрешения при выполнении CRUD с помощью GORM, и GORM позволяет вам изменять разрешение на уровне поля с помощью тегов, поэтому вы можете сделать поле доступным только для чтения, записи, создания, обновления или игнорируемым

{% note warn %}
Игнорируемые поля не будут созданы при использовании GORM Migrator для создания таблицы
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // разрешены чтение и создание
  Name string `gorm:"<-:update"` // разрешены чтение и обновление
  Name string `gorm:"<-"`        // разрешены чтение и запись (создание и обновление)
  Name string `gorm:"<-:false"`  // разрешено чтение, отключена запись
  Name string `gorm:"->"`        // только чтение (отключена запись если она не настроена)
  Name string `gorm:"->;<-:create"` // разрешены чтение и создание
  Name string `gorm:"->:false;<-:create"` // только создание (отключено чтение из базы данных)
  Name string `gorm:"-"`            // игнорируйте это поле при записи и чтении с помощью struct
  Name string `gorm:"-:all"`        // игнорируйте это поле при записи, чтении и миграции с помощью struct
  Name string `gorm:"-:migration"`  // игнорируйте это поле при миграции с помощью struct
}
```

### <name id="time_tracking">Создание/обновление Time/Unix (Milli/Nano) секунд отслеживания</span>

GORM использует `CreatedAt`, `UpdatedAt` для отслеживания создания/обновления времени. Если эти поля определены, GORM автоматически установит [текущее время](gorm_config.html#now_func) при создании/обновлении

Чтобы использовать поля с другим именем, вы можете настроить эти поля при помощи тегов `autoCreateTime`, `autoUpdateTime`

Если вы предпочитаете сохранять UNIX (milli/nano) секунды вместо времени, вы можете просто изменить тип данных поля с `time.Time` на `int`

```go
type User struct {
  CreatedAt time.Time // Установить текущее время, если оно равно нулю при создании
  UpdatedAt int       // Установить в формате секунд unix при обновлении или создание, если оно равно нулю
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Использование формата unix в наносекундах в качестве времени обновления
  Updated   int64 `gorm:"autoUpdateTime:milli"`// Использование формата unix в миллисекундах в качестве времени обновления
  Created   int64 `gorm:"autoCreateTime"`      // Использование формата unix в секундах при создании
}
```

### <span id="embedded_struct">Вложенные структуры</span>

Для анонимных полей GORM будет включать свои поля в свою же родительскую структуру, например:

```go
type Author struct {
  Name  string
  Email string
}

type Blog struct {
  Author
  ID      int
  Upvotes int32
}
// equals
type Blog struct {
  ID      int64
  Name    string
  Email   string
  Upvotes int32
}
```

Вы можете вставить обычные поля структуры с тегом `embedded`, например:

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
// эквивалентно
type Blog struct {
  ID    int64
    Name  string
    Email string
  Upvotes  int32
}
```

Также вы можете использовать тег `embeddedPrefix` для добавления префикса во встроенные поля в db, например:

```go
type Blog struct {
  ID      int
  Author  Author `gorm:"embedded;embeddedPrefix:author_"`
  Upvotes int32
}
// эквивалентно
type Blog struct {
  ID          int64
    AuthorName  string
    AuthorEmail string
  Upvotes     int32
}
```


### <span id="tags">Теги полей</span>

Tags are optional to use when declaring models, GORM supports the following tags: Tags are case insensitive, however `camelCase` is preferred. If multiple tags are used they should be separated by a semicolon (`;`). Characters that have special meaning to the parser can be escaped with a backslash (`\`) allowing them to be used as parameter values.

| Наименование тэга      | Описание                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| column                 | название столбца                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| type                   | тип данных столбца, предпочитайте использовать совместимый общий тип, например: bool, int, uint, float, string, time, bytes, который работает для всех баз данных и может использоваться вместе с другими тегами, например ` not null `, ` size `, ` autoIncrement `... также поддерживается указанный тип данных базы данных, например ` varbinary (8) `, при использовании указанного типа данных базы данных он должен быть полным типом данных базы данных, например: ` MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT ` |
| serializer             | указывает сериализатор для сериализации и десериализации данных в Бд, например: `serializer:json/gob/unixtime`                                                                                                                                                                                                                                                                                                                                                                                                           |
| size                   | определяет размер/длину данных столбца, например: `size:256`                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| primaryKey             | указывает столбец в качестве первичного ключа                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| unique                 | указывает столбец, как уникальный                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| default                | задает значение столбца по умолчанию                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| precision              | определяет точность значений столбца                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| scale                  | specifies column scale                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| not null               | указывает столбец, как NOT NULL                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| autoIncrement          | определяет столбец с авто инкрементом                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| autoIncrementIncrement | шаг автоматического увеличения, управляет интервалом между последовательными значениями столбца                                                                                                                                                                                                                                                                                                                                                                                                                          |
| embedded               | встраиваемое поле                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| embeddedPrefix         | префикс имени столбца для встроенных полей                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| autoCreateTime         | отслеживать текущее время при создании, для полей `int`, он будет отслеживать секунды unix, используйте значение `nano`/`milli` для отслеживания unix нано/миллисекунд, например: `autoCreateTime:nano`                                                                                                                                                                                                                                                                                                                  |
| autoUpdateTime         | отслеживайте текущее время при создании/обновлении, для полей `int` оно будет отслеживать секунды unix, используйте значение `nano`/`milli` для отслеживания unix нано/миллисекунд, например: `autoUpdateTime:milli`                                                                                                                                                                                                                                                                                                     |
| index                  | создает индекс с параметрами, используйте одно и то же имя для нескольких полей, создавая составные индексы, смотрите [Индексы](indexes.html) для получения подробной информации                                                                                                                                                                                                                                                                                                                                         |
| uniqueIndex            | то же, что и параметр `index`, но создает уникальный индекс                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| check                  | создает ограничение проверки, например: `check:age > 13`, смотрите [Ограничения](constraints.html)                                                                                                                                                                                                                                                                                                                                                                                                                    |
| <-                     | устанавливает разрешение на запись поля, `<-:create` поле только для создания, `<-:update` поле только для обновления, `<-:false` нет разрешения на запись, `<-` разрешение на создание и обновление                                                                                                                                                                                                                                                                                                         |
| ->                     | устанавливает разрешение на чтение поля, `->:false` нет разрешения на чтение                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| -                      | игнорировать это поле, `-` нет разрешения на чтение/запись, `-:migration` нет разрешения на миграцию, `-:all` нет разрешения на чтение/запись/миграцию                                                                                                                                                                                                                                                                                                                                                                   |
| comment                | добавить комментарий к полю при миграции                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |

### Взаимосвязи

GORM позволяет настраивать внешние ключи (foreign keys), ограничения (constraints), отношения многие ко многим через теги связей, для получения подробной информации перейдите в [раздел Ассоциации](associations.html#tags)
