---
title: Prometheus
layout: page
---

GORM 提供了 Prometheus 插件来收集 [DBStats](https://pkg.go.dev/database/sql?tab=doc#DBStats) 和用户自定义指标

https://github.com/go-gorm/prometheus

## 用法

```go
import (
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
  "gorm.io/plugin/prometheus"
)

db, err := gorm.Open(sqlite.Open("gorm.db"), &gorm.Config{})

db.Use(prometheus.New(prometheus.Config{
  DBName:          "db1", // 使用 `DBName` 作为指标 label
  RefreshInterval: 15,    // 指标刷新频率（默认为 15 秒）
  PushAddr:        "prometheus pusher address", // 如果配置了 `PushAddr`，则推送指标
  StartServer:     true,  // 启用一个 http 服务来暴露指标
  HTTPServerPort:  8080,  // 配置 http 服务监听端口，默认端口为 8080 （如果您配置了多个，只有第一个 `HTTPServerPort` 会被使用）
  MetricsCollector: []prometheus.MetricsCollector {
    &prometheus.MySQL{
      VariableNames: []string{"Threads_running"},
    },
  },  // 用户自定义指标
}))
```

## 用户自定义指标

您可以通过 GORM Prometheus 插件定义并收集自定义的指标，这需要实现 `MetricCollector` 接口

```go
type MetricsCollector interface {
  Metrics(*Prometheus) []prometheus.Collector
}
```

### MySQL

GORM 提供了一个示例，说明如何收集 MySQL 状态指标，查看 [prometheus.MySQL](https://github.com/go-gorm/prometheus/blob/master/mysql.go) 获取详情

```go
&prometheus.MySQL{
  // 指标名前缀，默认为 `gorm_status_`
  // 例如： Threads_running 的指标名就是 `gorm_status_Threads_running`
  Prefix: "gorm_status_",
  // 拉取频率，默认使用 Prometheus 的 RefreshInterval
  Interval: 100,
  // 从 SHOW STATUS 选择变量变量，如果不设置，则使用全部的状态变量
  VariableNames: []string{"Threads_running"},
}
```
