---
title: Объявление моделей
layout: страница
---

## Объявление моделей

Модели являются обычными stuct с основными типами Go, указателями/псевдонимами или пользовательскими типами, реализующими интерфейсы [Scanner](https://pkg.go.dev/database/sql/sql#Scanner) и [Valuer](https://pkg.go.dev/database/sql/driver#Valuer)

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

```go
type User struct {
  gorm.Model
  Name string
}
// идентичен
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
}
```

## Дополнительно

### Разрешения на уровне поля

Экспортированные поля имеют все разрешения при выполнении CRUD с помощью GORM, но GORM позволяет изменять права на уровне поля при помощи тега, так что вы можете сделать поле только для чтения, записи, только для создания, обновления или игнорирования

```go
type User struct {
  Name string `gorm:"<-:create"` // разрешить чтение и создание
  Name string `gorm:"<-:update"` // разрешить чтение и обновление
  Name string `gorm:"<-"`        // разрешить чтение и запись (создание и обновление)
  Name string `gorm:"<-:false"`  // разрешить чтение, запретить запись
  Name string `gorm:"->"`        // только чтение (запрещает запись после создания)
  Name string `gorm:"->;<-:create"` // разрешить чтение и создание
  Name string `gorm:"->:false;<-:create"` // только создание (запрещает чтение из БД)
  Name string `gorm:"-"`  // игнорировать это поле при чтении и записи
}
```

### <name id="time_tracking">Автоматическое создание/обновление Time/Unix (Нано) секунды</span>

GORM использует `CreatedAt`, `UpdatedAt` для отслеживания создания/обновления времени, GORM заполнит [текущее время](gorm_config.html#current_time) при создании/обновлении, если эти поля определены

Чтобы использовать поля с другим именем, вы можете настроить эти поля при помощи тегов `autoCreateTime`, `autoUpdateTime`

Если вы предпочитаете сохранять UNIX (nano) секунды вместо времени, вы можете просто изменить тип данных поля с `time.Time` на `int`

```go
type User struct {
  CreatedAt time.Time // Установить на текущее время если ноль при создании
  UpdatedAt int       // Установить текущий unixtimestamp при обновлении или если ноль при создании
  Updated   int64 `gorm:"autoUpdateTime:nano"` // Установить unix NANO секунды как время обновления
  Created   int64 `gorm:"autoCreateTime"`      // Установить unixtimestamp секунды как время создания
}
```

### <span id="embedded_struct">Встроенный struct</span>

Для анонимных полей, GORM будет включать свои поля в свою родительскую структуру, например:

```go
type User struct {
  gorm.Model
  Name string
}
// идентичен
type User struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"`
  Name string
}
```

Для обычных полей struct вы можете вставить их с тегом `embedded`, например:

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
// идентично
type Blog struct {
  ID    int64
    Name  string
    Email string
  Upvotes  int32
}
```

И вы можете использовать тег `embeddedrefix` для добавления префикса во встроенные поля в db, например:

```go
type Blog struct {
  ID      int
  Author  Author `gorm:"embedded;embeddedPrefix:author_"`
  Upvotes int32
}
// идентично
type Blog struct {
  ID          int64
    AuthorName  string
    AuthorEmail string
  Upvotes     int32
}
```


### Теги полей

Теги необязательны для использования при определении моделей, GORM поддерживает следующие теги:

Имя тега не имеет значения, предпочтительнее использовать `camelCase`.

| Назвние тэга   | Описание                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| column         | название столбца                                                                                                                                                                                                                                                                                                                                                                                                                         |
| type           | тип данных столбца, используйте совместимый общий тип, например.: bool, int, uint, float, string, time, bytes, которые работают с тегами типа `not null`, `size`, `autoIncrement`... специфические типы данных базы данных, такие как `varbinary(8)`, также поддерживается, при использовании указанного типа данных базы данных, он должен быть полным типом данных базы данных, например: `MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT` |
| size           | задает размер/длину столбца, например: `size:256`                                                                                                                                                                                                                                                                                                                                                                                        |
| primaryKey     | указать столбец в качестве первичного ключа                                                                                                                                                                                                                                                                                                                                                                                              |
| unique         | указать столбец как уникальный                                                                                                                                                                                                                                                                                                                                                                                                           |
| default        | задает значение столбца по умолчанию                                                                                                                                                                                                                                                                                                                                                                                                     |
| precision      | определяет точность столбца                                                                                                                                                                                                                                                                                                                                                                                                              |
| not null       | определяет столбец как НЕ NULL                                                                                                                                                                                                                                                                                                                                                                                                           |
| autoIncrement  | определяет столбец с авто инкрементом                                                                                                                                                                                                                                                                                                                                                                                                    |
| embedded       | встроенное поле                                                                                                                                                                                                                                                                                                                                                                                                                          |
| embeddedPrefix | префикс для встроенного поля                                                                                                                                                                                                                                                                                                                                                                                                             |
| autoCreateTime | сохранает время создания при создании, `autoCreateTime:nano` сохраняет unix nano время для `int` полей                                                                                                                                                                                                                                                                                                                                   |
| autoUpdateTime | сохраняет время обновления при создании/обновлении, `autoUpdateTime:nano` сохраняет unix нано время для `int` полей                                                                                                                                                                                                                                                                                                                      |
| index          | создать индекс с параметрами, одинаковое имя для нескольких полей создает составные индексы, смотрите [Индексы](indexes.html) для подробностей                                                                                                                                                                                                                                                                                           |
| uniqueIndex    | то же самое, что и `index`, но создает уникальный индекс                                                                                                                                                                                                                                                                                                                                                                                 |
| check          | создает ограничение проверки, например: `check:(age > 13)`, см. [Ограничения](constraints.html)                                                                                                                                                                                                                                                                                                                                       |
| <-             | задать разрешение на запись, `<-:create` только для создания, `<-:update` только обновление, `<-:false` Нет разрешения                                                                                                                                                                                                                                                                                                          |
| ->             | установить права на чтение полей                                                                                                                                                                                                                                                                                                                                                                                                         |
| -              | игнорировать эти поля (отключить разрешение на чтение/запись)                                                                                                                                                                                                                                                                                                                                                                            |

### Взаимосвязи

GORM позволяет настраивать внешние ключи, ограничения, many2many через теги связей, загляните в [раздел Ассоциации](associations.html#tags) для получения подробной информации
