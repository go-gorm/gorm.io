---
title: Объявление моделей
layout: страница
---
## Объявление моделей

Модели обычно являются обычными Golang структурами, основными типами Go или указателями. [`sql.Scanner`](https://golang.org/pkg/database/sql/#Scanner) и [`driver.Valuer`](https://golang.org/pkg/database/sql/driver/#Valuer) интерфейсы также поддерживаются.

Пример модели:

```go
type User struct {   
    gorm.Model   Name string   
    Age sql.NullInt64   
    Birthday *time.Time   
    Email string `gorm:"type:varchar(100);unique_index"`   
    Role string `gorm:"size:255"` // установим размер поля в 255 символов   
    MemberNumber *string `gorm:"unique;not null"` // сделаем поле уникальным и не null
    Num int `gorm:"AUTO_INCREMENT"` // установим число как автоинкремент
    Address string `gorm:"index:addr"` // сделаем индекс `addr` для поля
    IgnoreMe int `gorm:"-"` // игнорируем это поле
}
```

## Struct tags

Теги необязательно используются при объявлении моделей. GORM поддерживает следующие теги:

### Поддерживаемые теги

| Тег             | Описание                                                                  |
| --------------- | ------------------------------------------------------------------------- |
| Column          | Указывает имя столбца                                                     |
| Type            | Укажите тип данных столбца                                                |
| Size            | Задает размер столбца, по умолчанию 255                                   |
| PRIMARY_KEY     | Определяет столбец как первичный ключ                                     |
| UNIQUE          | Указывает столбец как уникальный                                          |
| DEFAULT         | Задает значение столбца по умолчанию                                      |
| PRECISION       | Определяет точность столбца                                               |
| NOT NULL        | Определяет столбец как NOT NULL                                           |
| AUTO_INCREMENT  | Указывает столбец как автоинкрементный или нет                            |
| INDEX           | Создать индекс с именем или без него, то же имя создает составные индексы |
| UNIQUE_INDEX    | Like `INDEX`, create unique index                                         |
| EMBEDDED        | Set struct as embedded                                                    |
| EMBEDDED_PREFIX | Set embedded struct's prefix name                                         |
| -               | Ignore this fields                                                        |

### Struct tags for Associations

Check out the Associations section for details

| Tag                                | Description                                    |
| ---------------------------------- | ---------------------------------------------- |
| MANY2MANY                          | Specifies join table name                      |
| FOREIGNKEY                         | Specifies foreign key                          |
| ASSOCIATION_FOREIGNKEY             | Specifies association foreign key              |
| POLYMORPHIC                        | Specifies polymorphic type                     |
| POLYMORPHIC_VALUE                  | Specifies polymorphic value                    |
| JOINTABLE_FOREIGNKEY               | Specifies foreign key of jointable             |
| ASSOCIATION_JOINTABLE_FOREIGNKEY | Specifies association foreign key of jointable |
| SAVE_ASSOCIATIONS                  | AutoSave associations or not                   |
| ASSOCIATION_AUTOUPDATE             | AutoUpdate associations or not                 |
| ASSOCIATION_AUTOCREATE             | AutoCreate associations or not                 |
| ASSOCIATION_SAVE_REFERENCE       | AutoSave associations reference or not         |
| PRELOAD                            | Auto Preload associations or not               |