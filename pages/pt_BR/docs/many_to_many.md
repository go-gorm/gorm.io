---
title: Muitos Para Muitos
layout: page
---

## Muitos Para Muitos

Muitos para muitos adiciona uma tabela de união (tabela pivot) entre dois models.

Por exemplo, se sua aplicação inclui usuarios e linguagens, e um usuário pode falar várias linguagens, e uma linguagem pode ser falada por vários usuarios.

```go
// User possui e pertence a várias linguagens, `user_languages` é a tabela de união (tabela pivot)

type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
}
```

Ao utilizar o `AutoMigrate` do GORM para criar a tabela para o model `User`, o GORM vair criar a tabela pivot automaticamente

## Referência

### Declação
```go
// User possui e pertence a muitas linguagens,  use `user_languages` como tabela de união (tabela pivot)

type User struct {
  gorm.Model
  Languages []*Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
  Users []*User `gorm:"many2many:user_languages;"`
}
```

### Recuperando
```go
// Recupera a lista de usuários com idiomas utilizando edger loading
func GetAllUsers(db *gorm.DB) ([]User, error) {
    var users []User
    err := db.Model(&User{}).Preload("Languages").Find(&users).Error
    return users, err
}

// Retrieve language list with edger loading users
func GetAllLanguages(db *gorm.DB) ([]Language, error) {
    var languages []Language
    err := db.Model(&Language{}).Preload("Users").Find(&languages).Error
    return languages, err
}
```

## Sobrescrevendo Chaves Estrangeiras

Para uma relação `de muitos2many`, a tabela de união é dona da chave estrangeira que faz referência a dois models, por exemplo:

```go
type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_languages;"`
}

type Language struct {
  gorm.Model
  Name string
}

// Tabela de união(Pivot): user_languages
//   Chave estrangeira: user_id, referencia: users.id
//   Chave estrangeira: language_id, referencia: languages.id
```

Para sobrescrever, você pode usar a tag `foreignKey`, `references`, `joinForeignKey`, `joinReferences`, não é necessário usá-las juntas, você pode apenas usar uma delas para sobrescrever algumas chaves/referências estrangeiras

```go
type User struct {
    gorm.Model
    Profiles []Profile `gorm:"many2many:user_profiles;foreignKey:Refer;joinForeignKey:UserReferID;References:UserRefer;joinReferences:ProfileRefer"`
    Refer    uint      `gorm:"index:,unique"`
}

type Profile struct {
    gorm.Model
    Name      string
    UserRefer uint `gorm:"index:,unique"`
}

// Cria a tabela: user_profiles
//   Chave estrangeira: user_refer_id, referencia: users.refer
//   Chave estrangeira: profile_refer, referencia: profiles.user_refer
```

{% note warn %}
**NOTA:** Alguns bancos de dados só permitem criar chaves estrangeiras de banco de dados que referenciam um campo com índice exclusivo, então você precisa especificar a tag de `unique index` se você estiver criando chaves estrangeiras de banco de dados quando migrar
{% endnote %}

## Muitos para Muitos Auto-Referenciáveis

Auto-referenciando relacionamentos muitos para muitos

```go
type User struct {
  gorm.Model
    Friends []*User `gorm:"many2many:user_friends"`
}

// Cria a tabela: user_friends
//   Chave estrangeira: user_id, referencia: users.id
//   Chave estrangeira: friend_id, referencia: users.id
```

## Eager Loading

O GORM permite eager loading para associações de muitos para muitos, isso com `Preload`, cheque [Preloading (Eager loading)](preload.html) para mais detalhes

## CRUD de muitos para muitos

Por favor cheque [Modo de associação](associations.html#Association-Mode) para trabalhar com relacionamentos de muitos para muitos

## Customizando União de Tabelas

`JoinTable` pode ser um modelo completo, isso tendo `Soft Delete`,`Hooks` suporta e mais campos, você pode configurá-lo com `SetupJoinTable`, por exemplo:

{% note warn %}
**NOTA:** A personalização de chaves estangeiras da tabela de união, requer chaves primárias compostas ou índice único composto
{% endnote %}

```go
type Person struct {
  ID        int
  Name      string
  Addresses []Address `gorm:"many2many:person_addresses;"`
}

type Address struct {
  ID   uint
  Name string
}

type PersonAddress struct {
  PersonID  int `gorm:"primaryKey"`
  AddressID int `gorm:"primaryKey"`
  CreatedAt time.Time
  DeletedAt gorm.DeletedAt
}

func (PersonAddress) BeforeCreate(db *gorm.DB) error {
  // ...
}

// Altera o campo Addresses do modelo pessoa ' join table to PersonAddress
// O PersonAddress deve ser defenido para todas as chaves estrangeiras requeridas ou lançará um erro
err := db.SetupJoinTable(&Person{}, "Addresses", &PersonAddress{})
```

## Restrições de CHAVES ESTRANGEIRAS

Você pode configurar `OnUpdate`, `OnDelete` restrições com a tag `OnDelete`, ela será criada quando realizar as migrates com o GORM, por exemplo:

```go
type User struct {
  gorm.Model
  Languages []Language `gorm:"many2many:user_speaks;"`
}

type Language struct {
  Code string `gorm:"primarykey"`
  Name string
}

// CREATE TABLE `user_speaks` (`user_id` integer,`language_code` text,PRIMARY KEY (`user_id`,`language_code`),CONSTRAINT `fk_user_speaks_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,CONSTRAINT `fk_user_speaks_language` FOREIGN KEY (`language_code`) REFERENCES `languages`(`code`) ON DELETE SET NULL ON UPDATE CASCADE);
```

Também é permitido deletar relacionamentos de muitos para muitos, isso utilizando a tag `Select` quando deletando, dê uma olhada em [Deletando Com Select](associations.html#delete_with_select) para mais detalhes

## Chaves Estrangeiras Compostas

Se você estiver utilizando [Chaves Primárias Compostas](composite_primary_key.html) para seus models, o GORM habilitará chaves estrangeiras compostas por padrão

Você pode substituir as chaves estrangeiras padrão, para especificar várias chaves estrangeiras, apenas separe essas chaves pelo nome por vírgulas, por exemplo:

```go
type Tag struct {
  ID     uint   `gorm:"primaryKey"`
  Locale string `gorm:"primaryKey"`
  Value  string
}

type Blog struct {
  ID         uint   `gorm:"primaryKey"`
  Locale     string `gorm:"primaryKey"`
  Subject    string
  Body       string
  Tags       []Tag `gorm:"many2many:blog_tags;"`
  LocaleTags []Tag `gorm:"many2many:locale_blog_tags;ForeignKey:id,locale;References:id"`
  SharedTags []Tag `gorm:"many2many:shared_blog_tags;ForeignKey:id;References:id"`
}

// Join Table: blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: blog_locale, reference: blogs.locale
//   foreign key: tag_id, reference: tags.id
//   foreign key: tag_locale, reference: tags.locale

// Join Table: locale_blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: blog_locale, reference: blogs.locale
//   foreign key: tag_id, reference: tags.id

// Join Table: shared_blog_tags
//   foreign key: blog_id, reference: blogs.id
//   foreign key: tag_id, reference: tags.id
```

Veja também [Chaves Primárias Compostas](composite_primary_key.html)
