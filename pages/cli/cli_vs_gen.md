---
title: CLI vs Gen
layout: page
---

# CLI vs Gen

`gorm.io/gen` arrived before Go generics. It generates full DAO structs and its own query layer. The newer CLI (`gorm cmd`) leans on generics, keeps the generated surface small, and sticks close to existing `gorm` APIs.

## How to choose

* Stay with **Gen** when you depend on its DAO chainers or database-to-model scaffolding.
* Prefer the **CLI** when you want lightweight helpers, typed methods defined by interfaces, and minimal divergence from core `gorm` patterns.

## Migration path

1. Generate CLI output into a new package (for example `internal/generated`).
2. Switch one module at a time to call `generated.Query[...]` and `gorm.G[...]` instead of DAO structs.
3. Remove Gen output once you have replaced the DAO usage you no longer need.

## CLI roadmap

* Additional commands such as `vet` (tag and association validation) and `migration`.

Head back to the [CLI overview](index.html) or read the [`gorm/gen` documentation](/gen/index.html).
