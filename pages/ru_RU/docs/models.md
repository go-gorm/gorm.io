---
title: Объявление моделей
layout: страница
---

## Объявление моделей

Модели являются обычными структурами с основными типами Go, указателями/псевдонимами или пользовательскими типами, реализующими интерфейсы [Scanner](https://pkg.go.dev/database/sql/?tab=doc#Scanner) и [Valuer](https://pkg.go.dev/database/sql/driver#Valuer)

Например:

```go
type User struct {
  ID           uint
  Name         string
  Email        *string
  Age          uint8
  Birthday     *time.Time
  MemberNumber sql.NullString
  ActivatedAt  sql.NullTime
  CreatedAt    time.Time
  UpdatedAt    time.Time
}
```

## Преобразования

По умолчанию, GORM использует в качестве первичного ключа `ID`, преобразует имя структуры в `snake_cases` в качестве имени таблицы, `snake_case` в качестве имени столбца и использует `CreatedAt`, `UpdatedAt` для отслеживания времени создания/обновления

Если вы следуете правилам, принятым GORM, вам нужно написать очень мало конфигурации/кода, Если правила не соответствует вашим требованиям, [GORM позволяет настроить их](conventions.html)

## gorm.Model

GORM определяет структуру `gorm.Model`, которая включает в себя поля `ID`, `CreatedAt`, `UpdatedAt`, `DeletedAt`

```go
// объявление gorm.Model
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

Вы можете встроить gorm.Model в свою структуру. Чтобы включить эти поля, смотрите [Встроенные структуры](#embedded_struct)

## Дополнительно

### <span id="field_permission">Разрешение для каждого поля</span>

Экспортированные поля имеют все разрешения при выполнении CRUD с помощью GORM, но GORM позволяет изменять права на уровне поля при помощи тега, так что вы можете указать, что поле доступно для чтения, записи, создания, обновления или игнорирования

{% note warn %}
Игнорируемые поля не будут созданы при использовании GORM Migrator для создания таблицы
{% endnote %}

```go
type User struct {
  Name string `gorm:"<-:create"` // allow read and create
  Name string `gorm:"<-:update"` // allow read and update
  Name string `gorm:"<-"`        // allow read and write (create and update)
  Name string `gorm:"<-:false"`  // allow read, disable write permission
  Name string `gorm:"->"`        // readonly (disable write permission unless it configured)
  Name string `gorm:"->;<-:create"` // allow read and create
  Name string `gorm:"->:false;<-:create"` // createonly (disabled read from db)
  Name string `gorm:"-"`            // ignore this field when write and read with struct
  Name string `gorm:"-:all"`        // ignore this field when write, read and migrate with struct
  Name string `gorm:"-:migration"`  // ignore this field when migrate with struct
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
type User struct {
  gorm.Model
  Name string
}
// эквивалентно
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
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

Также вы можете использовать тег `embeddedrefix` для добавления префикса во встроенные поля в db, например:

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

Теги необязательны для использования при определении моделей, GORM поддерживает следующие теги: Теги не чувствительны к регистру, однако `регистру` является предпочтительным.

| Наименование тэга      | Описание                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| column                 | название столбца                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| type                   | тип данных столбца, предпочитайте использовать совместимый общий тип, например: bool, int, uint, float, string, time, bytes, который работает для всех баз данных и может использоваться вместе с другими тегами, например ` not null `, ` size `, ` autoIncrement `... также поддерживается указанный тип данных базы данных, например ` varbinary (8) `, при использовании указанного типа данных базы данных он должен быть полным типом данных базы данных, например: ` MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT ` |
| size                   | задает размер/длину столбца, например: `size:256`                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| primaryKey             | указать столбец в качестве первичного ключа                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| unique                 | указать столбец как уникальный                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| default                | задает значение столбца по умолчанию                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| precision              | определяет точность столбца                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| scale                  | указывает размерность столбца                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| not null               | указывает что столбец не может быть пустым (NOT NULL)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| autoIncrement          | указывает что столбец является автоинкрементом                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| autoIncrementIncrement | шаг автоинкремента, контролирует интервал между последовательными значениями столбца                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| embedded               | встраиваемое поле                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| embeddedPrefix         | префикс наименования столбца для встраиваемого поля                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| autoCreateTime         | отслеживать текущее время при создании, для `int` полей, он будет отслеживать unix секунд, используйте значение `nano`/`milli` для отслеживания unix nano/milli секунд, например: `autoCreateTime:nano`                                                                                                                                                                                                                                                                                                                  |
| autoUpdateTime         | отслеживать текущее время при создании/обновлении, для `int` полей, он будет отслеживать unix секунд, используйте значение `nano`/`milli` для отслеживания unix nano/milli секунд, e.: `autoUpdateTime:milli`                                                                                                                                                                                                                                                                                                            |
| index                  | создать индекс с параметрами, используйте одинаковое имя для нескольких полей для создания составных индексов, смотрите [Индексы](indexes.html) для подробностей                                                                                                                                                                                                                                                                                                                                                         |
| uniqueIndex            | то же самое, что и `index`, но создает уникальный индекс                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| check                  | создает ограничение проверки (constraint), например: `check:(age > 13)`, см. [Ограничения](constraints.html)                                                                                                                                                                                                                                                                                                                                                                                                          |
| <-                     | задать разрешение на запись, `<-:create` только для создания, `<-:update` только обновление, `<-:false` нет разрешения на запись, `<-` разрешение на создание и обновление                                                                                                                                                                                                                                                                                                                                   |
| ->                     | задать разрешение на чтение, `->:false` нет разрешения на чтение                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| -                      | ignore this field, `-` no read/write permission, `-:migration` no migrate permission, `-:all` no read/write/migrate permission                                                                                                                                                                                                                                                                                                                                                                                           |
| comment                | добавить комментарий для поля при миграции                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |

### Взаимосвязи

GORM позволяет настраивать внешние ключи (foreign keys), ограничения (constraints), отношения многие ко многим через теги связей, для получения подробной информации перейдите в [раздел Ассоциации](associations.html#tags)
