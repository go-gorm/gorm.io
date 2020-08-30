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

## <span id="finisher_method">Finisher Method</span>

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

{% note warn %}
**NOTE** In example 2, the first query affected the second generated SQL as GORM reused the `Statement`, this might cause unexpected issues, refer [Goroutine Safety](#goroutine_safe) for how to avoid it
{% endnote %}

## <span id="goroutine_safe">Method Chain Safety/Goroutine Safety</span>

Methods will create new `Statement` instances for new initialized `*gorm.DB` or after a `New Session Method`, so to reuse a `*gorm.DB`, you need to make sure they are under `New Session Mode`, for example:

```go
db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})

// Safe for new initialized *gorm.DB
for i := 0; i < 100; i++ {
  go db.Where(...).First(&user)
}

tx := db.Where("name = ?", "jinzhu")
// NOT Safe as reusing Statement
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.WithContext(ctx)
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user)
}

ctx, _ := context.WithTimeout(context.Background(), time.Second)
ctxDB := db.Where("name = ?", "jinzhu").WithContext(ctx)
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go ctxDB.Where(...).First(&user) // `name = 'jinzhu'` will apply to the query
}

tx := db.Where("name = ?", "jinzhu").Session(&gorm.Session{WithConditions: true})
// Safe after a `New Session Method`
for i := 0; i < 100; i++ {
  go tx.Where(...).First(&user) // `name = 'jinzhu'` will apply to the query
}
```
