---
title: समग्र प्राथमिक कुंजी//Composite Primary Key
layout: पृष्ठ
---

Multiple फ़ील्ड सेट करें क्योंकि primary key, composite primary key बनाती है, उदाहरण के लिए:

```go
type Product struct {
  ID           string `gorm:"primaryKey"`
  LanguageCode string `gorm:"primaryKey"`
  Code         string
  Name         string
}
```

**ध्यान दें** पूर्णांक `PrioritizedPrimaryField` डिफ़ॉल्ट रूप से `AutoIncrement` को सक्षम करता है, इसे अक्षम करने के लिए, आपको ``autoIncrement< को बंद करना होगा / कोड> int fields के लिए:</p>

<pre><code class="go">type Product struct {
  CategoryID uint64 `gorm:"primaryKey;autoIncrement:false"`
  TypeID     uint64 `gorm:"primaryKey;autoIncrement:false"`
}
``</pre>
