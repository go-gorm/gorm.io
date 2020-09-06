---
title: Написание плагинов
layout: страница
---

## Callbacks

Сам GORM основан на методах `Callbacks`, у которого есть callback функции для `Create`, `Query`, `Update`, `Delete`, `Row`, `Raw`, с помощью которых вы можете полностью настроить GORM по своему усмотрению

Вызовы callback регистрируются в глобальной `*gorm.DB`, а не на сессионном уровне, если вам требуется `*gorm. B` с другими функциями callback, вам нужно инициализировать другой `*gorm.DB`

### Регистрация функций callback

Регистрация функции callback в Callbacks

```go
func cropImage(db *gorm.DB) {
  if db.Statement.Schema != nil {
    // обрезать поля картинок и загрузить на CDN, пример кода
    for _, field := range db.Statement.Schema.Fields {
      switch db.Statement.ReflectValue.Kind() {
      case reflect.Slice, reflect.Array:
        for i := 0; i < db.Statement.ReflectValue.Len(); i++ {
          // Получить значение из поля
          if fieldValue, isZero := field.ValueOf(db.Statement.ReflectValue.Index(i)); !isZero {
            if crop, ok := fieldValue.(CropInterface); ok {
              crop.Crop()
            }
          }
        }
      case reflect.Struct:
        // Получить значение из поля
        if fieldValue, isZero := field.ValueOf(db.Statement.ReflectValue); isZero {
          if crop, ok := fieldValue.(CropInterface); ok {
            crop.Crop()
          }
        }

        // Установить значение в поле
        err := field.Set(db.Statement.ReflectValue, "newValue")
      }
    }

    // Все поля для текущей модели
    db.Statement.Schema.Fields

    // Все первичные ключи для текущей модели
    db.Statement.Schema.PrimaryFields

    // Приоритетный первичный ключ: поле в названием id или первый определенный первичный ключ
    db.Statement.Schema.PrioritizedPrimaryField

    // Все связи для текущей модели
    db.Statement.Schema.Relationships

    // Найти поле при помощи названия поля или названия в БД
    field := db.Statement.Schema.LookUpField("Name")

    // работа
  }
}

db.Callback().Create().Register("crop_image", cropImage)
// Регистрация callback для процесса Create
```

### Удаление функций callback

Удаление функции callback из Callbacks

```go
db.Callback().Create().Remove("gorm:create")
// удалить callback `gorm:create` из обработчика Create
```

### Замена функций callback

Заменить callback с идентичным именем на новый

```go
db.Callback().Create().Replace("gorm:create", newCreateFunction)
// заменить callback `gorm:create` новой функцией `newCreateFunction` для обработчика Create
```

### Регистрация функций callback с порядком выполнения

Регистрация функций callback с порядком выполнения

```go
// before gorm:create
db.Callback().Create().Before("gorm:create").Register("update_created_at", updateCreated)

// after gorm:create
db.Callback().Create().After("gorm:create").Register("update_created_at", updateCreated)

// after gorm:query
db.Callback().Query().After("gorm:query").Register("my_plugin:after_query", afterQuery)

// after gorm:delete
db.Callback().Delete().After("gorm:delete").Register("my_plugin:after_delete", afterDelete)

// before gorm:update
db.Callback().Update().Before("gorm:update").Register("my_plugin:before_update", beforeUpdate)

// before gorm:create and after gorm:before_create
db.Callback().Create().Before("gorm:create").After("gorm:before_create").Register("my_plugin:before_create", beforeCreate)

// before any other callbacks
db.Callback().Create().Before("*").Register("update_created_at", updateCreated)

// after any other callbacks
db.Callback().Create().After("*").Register("update_created_at", updateCreated)
```

### Существующие функции callback

GORM предоставляет [некоторые функции callback](https://github.com/go-gorm/gorm/blob/master/callbacks/callbacks.go) для поддержки текущих функций GORM, ознакомьтесь с ними перед началом написания своих плагинов

## Плагин

GORM предоставляет метод `Use` для регистрации плагинов, плагин должен реализовывать интерфейс `Plugin`

```go
type Plugin interface {
  Name() string
  Initialize(*gorm.DB) error
}
```

Метод `Initialize` будет вызван при первом регистрации плагина в GORM, и GORM сохранит его в зарегистрированные плагины, обращайтесь к ним таким образом:

```go
db.Config.Plugins[pluginName]
```

Смотрите [Prometheus](prometheus.html) в качестве примера
