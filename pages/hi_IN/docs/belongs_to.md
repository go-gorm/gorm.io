---
title: "Belongs To //\nसे संबंधित"
layout: पृष्ठ
---

## Belongs To // से संबंधित

`belongs to` एसोसिएशन दूसरे मॉडल के साथ एक-से-एक कनेक्शन स्थापित करता है, जैसे कि declare मॉडल का प्रत्येक उदाहरण दूसरे मॉडल के एक उदाहरण से "belongs to" होता है।

उदाहरण के लिए, यदि आपके एप्लिकेशन में उपयोगकर्ता और कंपनियां शामिल हैं, और प्रत्येक उपयोगकर्ता को ठीक एक कंपनी को सौंपा जा सकता है, तो निम्न प्रकार उस संबंध का प्रतिनिधित्व करते हैं। यहाँ ध्यान दें कि, `उपयोगकर्ता` ऑब्जेक्ट पर, `CompanyID` के साथ-साथ `Company` दोनों होते हैं। डिफ़ॉल्ट रूप से, `CompanyID` का उपयोग `उपयोगकर्ता `और `कंपनी` तालिकाओं के बीच एक विदेशी कुंजी संबंध बनाने के लिए किया जाता है, और इस प्रकार कंपनी की आंतरिक संरचना( inner struct) को भरने के लिए `उपयोगकर्ता ` struct में शामिल किया जाना चाहिए।

```go
// `User` belongs to `Company`, `CompanyID` is the foreign key
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company
}

type Company struct {
  ID   int
  Name string
}
```

आंतरिक संरचना(inner struct) को पॉप्युलेट(populating) करने के विवरण के लिए [इजर लोडिंग(Eager Loading)](belongs_to.html#Eager-Loading) का संदर्भ लें।

## Override Foreign Key

संबंध से संबंधित परिभाषित करने के लिए, विदेशी कुंजी(foreign key) मौजूद होनी चाहिए, डिफ़ॉल्ट विदेशी कुंजी स्वामी के प्रकार के नाम और उसके प्राथमिक फ़ील्ड नाम का उपयोग करती है।

उपरोक्त उदाहरण के लिए, `उपयोगकर्ता` मॉडल को परिभाषित करने के लिए जो कि `कंपनी` से संबंधित है, विदेशी कुंजी (foreign key)`CompanyID` होनी चाहिए

GORM विदेशी कुंजी( foreign key) को अनुकूलित करने का एक तरीका प्रदान करता है, उदाहरण के लिए:

```go
type User struct {
  gorm.Model
  Name         string
  CompanyRefer int
  Company      Company `gorm:"foreignKey:CompanyRefer"`
  // use CompanyRefer as foreign key
}

type Company struct {
  ID   int
  Name string
}
```

## Override References

संबंध से संबंधित होने के लिए, GORM आमतौर पर मालिक के प्राथमिक क्षेत्र(primary field) को विदेशी कुंजी(foreign key) के मान के रूप में उपयोग करता है, उपरोक्त उदाहरण के लिए, यह `कंपनी` का फ़ील्ड `आईडी` है।

जब आप किसी उपयोगकर्ता को किसी कंपनी को असाइन करते हैं, तो GORM कंपनी की `ID` को उपयोगकर्ता के `CompanyID` फ़ील्ड में सहेज(save) देगा।

आप इसे `references` टैग से बदल सकते हैं, जैसे:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:Code"` // use Code as references
}

type Company struct {
  ID   int
  Code string
  Name string
}
```

{% note warn %}
**ध्यान दें** GORM आमतौर पर संबंध का अनुमान लगाता है क्योंकि `has one` यदि ओवरराइड विदेशी कुंजी नाम पहले से ही स्वामी के प्रकार में मौजूद है, तो हमें `references` को निर्दिष्ट करने की आवश्यकता है `belongs to` संबंध है।
{% endnote %}

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID string
  Company   Company `gorm:"references:CompanyID"` // use Company.CompanyID as references
}

type Company struct {
  CompanyID   int
  Code        string
  Name        string
}
```

## CRUD with Belongs To

रिलेशन्स के साथ काम करने के लिए कृपया [एसोसिएशन मोड](associations.html#Association-Mode) चेकआउट करें

## Eager Loading

जीओआरएम उत्सुक लोडिंग की अनुमति देता है `प्रीलोड` या `जॉइन` के साथ संबंधित है, विवरण के लिए [प्रीलोडिंग (Eager loading)](preload.html) देखें

## FOREIGN KEY Constraints

You can setup `OnUpdate`, `OnDelete` constraints with tag `constraint`, it will be created when migrating with GORM, for example:

```go
type User struct {
  gorm.Model
  Name      string
  CompanyID int
  Company   Company `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"`
}

type Company struct {
  ID   int
  Name string
}
```
