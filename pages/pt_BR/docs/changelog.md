---
title: Change Log
layout: page
---

## v2.0 - 2020.08

GORM 2.0 é uma reescrita do zero, introduz algumas mudanças incompatíveis na API e muitas melhorias

* Melhorias de desempenho
* Modularidade
* Contexto, Inserção em Lote, Modo Prepared Statement, Modo DryRun e Pré-carregamento de relacionamentos, Mapeamento de resultados das consultas, Inserir registro a partir de map, suporte a FindInBatches
* Suporta Transação Aninhadasd/SavePoint/RollbackTo SavePoint
* Argumento Nomeado, Grupo de Condições, Upsert, Locking, suporte anOptimizer/Index/Comentários e melhorias das subconsultas
* Suporte completo para auto-referência, melhorias no relacionamento de tabelas e  modo de associação para lotes de dados
* Suporte a vários campos para rastreamento de tempo de criação/atualização, que adiciona suporte para UNIX (milli/nano) segundos
* Suporte às permissões de campo: read-only, write-only, create-only, update-only, ignored
* Novo sistema de plugin: vários bancos de dados, suporte a fracionamento na leitura/escrita com Database Resolver, integração com prometheus...
* Nova API Hooks: interface unificada com plugins
* Novo migrador: permite criar chaves estrangeiras para relacionamentos no banco de dados, suporte a constraints/checker, melhorias nos índices
* Novo Logger: suporte de contexto, extensibilidade melhorada
* Estratégia de nome unificada: nome da tabela, nome de campo, nome de tabela de junção, chave estrangeira, checker, regras de nome de índices
* Melhor suporte a tipos de dados personalizados (por exemplo: JSON)

[Nota de versão GORM 2.0](v2_release_note.html)

## v1.0 - 2016.04

[GORM V1 Docs](https://v1.gorm.io)

Alterações significativas

* `gorm.Open` retorna `*gorm.DB` em vez de `gorm.DB`
* Atualização salva apenas campos alterados
* O soft delete irá verificar apenas se  `deleted_at IS NULL`
* Nova lógica ToDBName Padrões comuns do [golint](https://github.com/golang/lint/blob/master/lint.go#L702) como `HTTP`, `URI` foi convertido para letras minúsculas, portanto o nome do banco de dados `HTTP` é `http`,  mas não `h_t_p`, mas para alguns outros padrões que não estão na lista, como `SKU`, é o nome do db era `s_k_u`, esta alteração corrigiu para `sku`
* Erro `RecordNotFound` foi renomeado para `ErrNotNotFound`
* `mssql` dialect foi renomeado para `github.com/jinzhu/gorm/dialects/mssql`
* `O Hstore` foi movido para o pacote `github.com/jinzhu/gorm/dialects/postgres`
