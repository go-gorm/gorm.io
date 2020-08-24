---
title: Цепочки методов
layout: страница
---

GORM позволяет делать цепочки методов, так что вы можете написать код следующим образом:

```go
db.Where("name = ?", "jinzhu").Where("age = ?", 18).First(&user)
```

В GORM существует три вида методов: `Метод цепочки`, `Метод окончания`, `Метод новой сессии`

## Метод цепочки

Методы цепочки - это методы изменения или добавления `Условий` к текущему `экземпляру`, например:

`Where`, `Select`, `Omit`, `Joins`, `Scopes`, `Preload`, `Raw`...

Вот [полный список](https://github.com/go-gorm/gorm/blob/master/chainable_api.go), также ознакомьтесь с [Конструктор SQL](sql_builder.html) для получения более подробной информации о `Условиях`

## Метод завершения

Завершители - это методы, которые выполняют зарегистрированные callback, которые будут генерировать и выполнять SQL, такие как эти методы:

`Create`, `First`, `Find`, `Take`, `Save`, `Update`, `Delete`, `Scan`, `Row`, `Rows`...

Смотрите [полный список тут](https://github.com/go-gorm/gorm/blob/master/finisher_api.go)

## Метод новой сессии

После новой инициализации `*gorm. B` или `Метода новой сессии`, следующий вызов методов создаст новый `экземпляр` вместо использования текущего

GROM определил методы `Session`, `WithContext`, `Debug`, как `Методы новой сессии`, см. [Сессия](session.html)

Давайте объясним это с примерами:

Пример 1:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db ново инициализированная *gorm.DB `метод новой сессии`
db.Where("name = ?", "jinzhu").Where("age = ?", 18).Find(&users)
// `Where("name = ?", "jinzhu")` первый вызов метода, создаст новый `экземпляр`
// `Where("age = ?", 18)` использует существующий `экземпляр`, и добавляет к нему условия
// `Find(&users)` это завершитель, выполняет зарегистрированные callback функции, генерирует и выполняет SQL
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18;

db.Where("name = ?", "jinzhu2").Where("age = ?", 20).Find(&users)
// `Where("name = ?", "jinzhu2")` первый вызов метода, так же создаст новый `экземпляр`
// `Where("age = ?", 20)` использует существующий `экземпляр`, и добавляет к нему условия
// `Find(&users)` это завершитель, выполняет зарегистрированные callback функции, генерирует и выполняет SQL
// SELECT * FROM users WHERE name = 'jinzhu2' AND age = 20;

db.Find(&users)
// `Find(&users)` это завершитель и он же первый метод вызова в `методе новой сессии` `*gorm.DB`
// создаст новый `экземпляр` и выполнит зарегистрированные callback функции, генерирует и выполняет SQL
// SELECT * FROM users;
```

Пример 2:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
// db ново инициализированная *gorm.DB, `метод новой сессии`
tx := db.Where("name = ?", "jinzhu")
// `Where("name = ?", "jinzhu")` первый вызов метода, создает новый `экземпляр` и добавляет условия

tx.Where("age = ?", 18).Find(&users)
// `tx.Where("age = ?", 18)` использует повторно `экземпляр`, и добавляет условия
// `Find(&users)` это завершитель, выполняет зарегистрированные callback функции, генерирует и выполняет SQL
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18

tx.Where("age = ?", 28).Find(&users)
// `tx.Where("age = ?", 18)` использует повторно `экземпляр`, и добавляет условия
// `Find(&users)` это завершитель, выполняет зарегистрированные callback функции, генерирует и выполняет SQL
// SELECT * FROM users WHERE name = 'jinzhu' AND age = 18 AND age = 20;
```

**ПРИМЕЧАНИЕ** В примере 2, первый запрос повлиял на второй сгенерированный SQL, так как GORM повторно использовал `Экземпляр`, это может вызвать непредвиденные проблемы, смотрите [Гороутинная Безопасность](#goroutine_safe) для того, чтобы избежать этого

## <span id="goroutine_safe">Method Chain Safety/Goroutine Safety</span>

Методы создадут новый `Экземпляр` при новой инициализации `*gorm. B` или после `Метода новой сессии`, поэтому для повторного использования `*gorm. B`, вам нужно убедиться, что они находятся в `Методе новой сессии`, например:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

// Безопасно для новой инициализации *gorm.DB
for i := 0; i < 100; i++ {
  go db.Where(...).First(&user)
}

tx := db.Where("name = ?", "jinzhu")
// НЕ Безопасно для повторного использования
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.WithContext(ctx)
// Безопасно после `Метода новой сессии`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.Where("name = ?", "jinzhu").WithContext(ctx)
// Безопасно после `Метода новой сессии`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user) // `name = 'jinzhu'` применит ко всем
}

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{WithConditions: true})
// Безопасно после `Метода новой сессии`
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user) // `name = 'jinzhu'` применит ко всем
}
```
