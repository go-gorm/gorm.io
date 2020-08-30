---
title: 변경 로그
layout: page
---

## v2.0 - 2020.08

GORM 2.0은 처음부터 다시 작성되었으며 일부 호환되지 않는 API 변경 및 많은 개선 사항을 도입했습니다.

* 성능 향상
* 모듈성
* Context, Batch Insert, Prepared Statment Mode, DryRun Mode, Join Preload, Find To Map, Create From Map, FindInBatches 지원
* Nested Transaction/SavePoint/RollbackTo SavePoint 지원
* 명명 된 인수, 그룹 조건, Upsert, 잠금, 최적화/색인/주석 힌트 지원, 하위 쿼리 개선
* 완전한 자기 참조관계 지원, Join 테이블 개선, Association Mode for batch data
* 여러개의 생성/수정 시간 트래커 지원, UNIX (milli/nano) 초 지원
* 필드 권한 지원: read-only, write-only, create-only, update-only, ignored
* 새로운 플러그인 시스템: 다중 데이터베이스, Database Resolver플러그인으로 읽기/쓰기 분활 지원, prometheus 통합...
* 새로운 Hooks API: 플러그인과 통합 된 인터페이스
* New Migrator: 관계, 제약 / 체커 지원, 향상된 인덱스 지원을위한 데이터베이스 외래 키 생성 가능
* New Logger: context 지원, 향상된 확장성
* 이름규칙 통합: 테이블 이름, 필드 이름, join 테이블 이름, 외래키, 체커, index 이름 규칙
* 더 나은 데이터타입 커스터마이징(e.g: JSON)

[GORM 2.0 릴리즈 노트](v2_release_note.html)

## v1.0 - 2016.04

[GORM V1 Docs](https://v1.gorm.io)

주요 변경사항:

* `gorm.Open`가 `gorm.DB`대신 `*gorm.DB`를 반환합니다
* 업데이트하면 변경된 필드 만 업데이트됩니다
* Soft Delete는 `deleted_at IS NULL`인지만 확인합니다
* 새로운 ToDBName 로직 GO린터의 일반적인 이니셜 `HTTP`, `URI`들이 소문자로 변경됨. 따라서 `HTTP`의 db이름은 `http`로 변경됨 ( `h_t_t_p` 아님). 하지만 목록에 없는 몇몇 이니셜 `SKU`같은건 `s_k_u`였으나, `sku`로 변경됨
* RecordNotFound가 ErrRecordNotFound로 이름이 변경되었습니다
* `mssql` 의 이름이 `github.com/jinzhu/gorm/dialects/mssql` 로 변경되었습니다
* `Hstore` 가 `github.com/jinzhu/gorm/dialects/postgres` 패키지로 이동되었습니다
