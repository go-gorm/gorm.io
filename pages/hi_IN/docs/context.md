---
title: Context
layout: पृष्ठ
---

GORM कॉन्टेक्स्ट सपोर्ट प्रदान करता है, आप इसे `WithContext` method के साथ उपयोग कर सकते हैं

## Single Session Mode

सिंगल सेशन मोड आमतौर पर तब उपयोग किया जाता है जब आप एक ही ऑपरेशन करना चाहते हैं

```go
db.WithContext(ctx).Find(&users)
```

## Continuous session mode

Continuous session मोड का उपयोग आमतौर पर तब किया जाता है जब आप operations का एक समूह perform करना चाहते हैं, उदाहरण के लिए:

```go
tx := db.WithContext(ctx)
tx.First(&user, 1)
tx.Model(&user).Update("role", "admin")
```

## Context timeout

लंबे समय तक चलने वाले प्रश्नों(queries) के लिए टाइमआउट सेट करने के लिए आप `db.WithContext` के टाइमआउट के साथ संदर्भ(context) में पास कर सकते हैं, उदाहरण के लिए:

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

db.WithContext(ctx).Find(&users)
```

## Context in Hooks/Callbacks

आप `Context` ऑब्जेक्ट को वर्तमान `स्टेटमेंट` से एक्सेस कर सकते हैं, उदाहरण के लिए:

```go
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
  ctx := tx.Statement.Context
  // ...
  return
}
```

## Chi Middleware Example

Continuous session मोड जो API अनुरोधों(requests) को संभालने में सहायक हो सकता है, उदाहरण के लिए, आप मिडलवेयर में टाइमआउट संदर्भ के साथ `*gorm.DB` सेटअप कर सकते हैं और फिर `*gorm.DB</code का उपयोग कर सकते हैं। > सभी अनुरोधों को संसाधित करते समय</p>

<p spaces-before="0">Following is a Chi middleware example:</p>

<pre><code class="go">func SetDBMiddleware(next http.Handler) http.Handler {
  return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    timeoutContext, _ := context.WithTimeout(context.Background(), time.Second)
    ctx := context.WithValue(r.Context(), "DB", db.WithContext(timeoutContext))
    next.ServeHTTP(w, r.WithContext(ctx))
  })
}

r := chi.NewRouter()
r.Use(SetDBMiddleware)

r.Get("/", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var users []User
  db.Find(&users)

  // lots of db operations
})

r.Get("/user", func(w http.ResponseWriter, r *http.Request) {
  db, ok := ctx.Value("DB").(*gorm.DB)

  var user User
  db.First(&user)

  // lots of db operations
})
`</pre>

{% note %}
**ध्यान दें** `Context` को `WithContext` के साथ सेट करना गोरूटीन-सुरक्षित है, [Session देखें ](session.html) विवरण के लिए
{% endnote %}

## Logger

Logger `Context` भी स्वीकार करता है, आप इसे लॉग ट्रैकिंग के लिए उपयोग कर सकते हैं, विवरण के लिए [Logger](logger.html) देखें
