---
title: Prometheus
layout: page
---

GORMはPrometheusプラグインを提供しており、これを利用して [DBStats](https://pkg.go.dev/database/sql?tab=doc#DBStats) やユーザー定義のメトリクスを収集することができます。

https://github.com/go-gorm/prometheus

## 使い方

```go
import (
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
  "gorm.io/plugin/prometheus"
)

db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})

db.Use(prometheus.New(prometheus.Config{
  DBName:          "db1", // use `DBName` as metrics label
  RefreshInterval: 15,    // Refresh metrics interval (default 15 seconds)
  PushAddr:        "prometheus pusher address", // push metrics if `PushAddr` configured
  StartServer:     true,  // start http server to expose metrics
  HTTPServerPort:  8080,  // configure http server port, default port 8080 (if you have configured multiple instances, only the first `HTTPServerPort` will be used to start server)
  MetricsCollector: []prometheus.MetricsCollector {
    &prometheus.MySQL{
      VariableNames: []string{"Threads_running"},
    },
  },  // user defined metrics
}))
```

## ユーザー定義のメトリクス

Prometheusプラグインを使用して、メトリクスの定義、またそれを収集することができます。 これには `MetricsCollector` インターフェースの実装が必要になります。

```go
type MetricsCollector interface {
  Metrics(*Prometheus) []prometheus.Collector
}
```

### MySQL

以下はMySQLのステータスをメトリクスとして収集する例です。詳細は [prometheus.MySQL](https://github.com/go-gorm/prometheus/blob/master/mysql.go) をチェックしてください。

```go
&prometheus.MySQL{
  Prefix: "gorm_status_",
  // Metrics name prefix, default is `gorm_status_`
  // For example, Threads_running's metric name is `gorm_status_Threads_running`
  Interval: 100,
  // Fetch interval, default use Prometheus's RefreshInterval
  VariableNames: []string{"Threads_running"},
  // Select variables from SHOW STATUS, if not set, uses all status variables
}
```
