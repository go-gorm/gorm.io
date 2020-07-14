---
title: Прометий
layout: страница
---

GORM предоставляет плагин Prometheus для сбора [DBStats](https://pkg.go.dev/database/sql?tab=doc#DBStats) или пользовательских метрик

https://github.com/go-gorm/prometheus

## Использование

```go
import (
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
  "gorm.io/plugin/prometheus"
)

db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})

db.Use(prometheus.New(prometheus.Config{
  DBName:          "db1", // используйте `DBName` как метку метрики
  RefreshInterval: 15,    // Интервал обновления метрик (по умолчанию 15 секунд)
  PushAddr:        "prometheus pusher address", // push метрики если `PushAddr` настроен
  StartServer:     true,  // стартовать http сервер для выгрузки метрик
  HTTPServerPort:  8080,  // настройка порта сервера http, порт по умолчанию 8080 (если объявлено несколько раз, будет использован первый параметр `HTTPServerPort` для старта сервера)
  MetricsCollector: []prometheus.MetricsCollector {
    &prometheus.MySQL{
      VariableNames: []string{"Threads_running"},
    },
  },  // пользовательские метрики
}))
```

## Пользовательские метрики

Вы можете определить ваши метрики и собрать их с помощью плагина GORM Prometheus, который должен реализовывать интерфейс `MetricsCollector`

```go
type MetricsCollector interface {
  Metrics(*Prometheus) []prometheus.Collector
}
```

### MySQL

GORM представляет пример того, как собирать статусы MySQL в качестве метрики, посмотрите [prometheus.MySQL](https://github.com/go-gorm/prometheus/blob/master/mysql.go)

```go
&prometheus.MySQL{
  Prefix: "gorm_status_",
  // Префикс имени метки, по умолчанию `gorm_status_`
  // Например, имя метрики Threads_running будет `gorm_status_Threads_running`
  Interval: 100,
  // Интервал выборки, по умолчанию используется интервал обновления Prometheus's RefreshInterval
  VariableNames: []string{"Threads_running"},
  // Выбор переменных из SHOW STATUS, если не установлено, используются все статусные переменные
}
```
