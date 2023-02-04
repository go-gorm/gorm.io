---
title: Change Log //लॉग बदलें
layout: पृष्ठ
---

## v2.0 - 2020.08

जीओआरएम 2.0 स्क्रैच से एक पुनर्लेखन(rewrite) है, यह कुछ असंगत-एपीआई (incompatible-API) परिवर्तन और कई सुधार पेश करता है

* Performance Improvements // कार्य में सुधार
* Modularity //प्रतिरूपकता
* Context, Batch Insert, Prepared Statement Mode, DryRun Mode, Join Preload, Find To Map, Create From Map, FindInBatches का समर्थन करता है
* Nested Transaction/SavePoint/RollbackTo SavePoint का समर्थन करता है
* Named Argument, Group Conditions, Upsert, Locking, Optimizer/Index/Comment Hints supports, SubQuery का सुधार
* Full self-reference relationships supports, Join Table improvements, Association Mode for batch data
* ट्रैकिंग create/update समय के लिए एकाधिक फ़ील्ड समर्थन करते हैं, जो यूनिक्स (मिली/नैनो) सेकेंड के लिए समर्थन जोड़ता है
* फ़ील्ड अनुमतियाँ समर्थन: रीड-ओनली, राइट-ओनली, क्रिएट-ओनली, अपडेट-ओनली, ignored
* नई प्लगइन प्रणाली(system): एकाधिक डेटाबेस, प्लगइन डेटाबेस रिज़ॉल्वर, प्रोमेथियस इंटीग्रेशन ( prometheus integrations) के साथ पढ़ने/लिखने के विभाजन का समर्थन...
* न्यू हुक एपीआई(API): प्लगइन्स के साथ एकीकृत इंटरफ़ेस(unified interface)
* न्यू माइग्रेटर: रिश्तों(relationships), (constraints) बाधाओं/चेकर समर्थन, (enhanced index support) उन्नत सूचकांक समर्थन के लिए डेटाबेस विदेशी कुंजी(foreign keys) बनाने की अनुमति देता है
* नया Logger: (context) संदर्भ समर्थन, बेहतर एक्स्टेंसिबिलिटी
* (Unified Naming strategy) एकीकृत नामकरण रणनीति: table का नाम, फ़ील्ड का नाम, join table name, विदेशी कुंजी, चेकर, सूचकांक नाम नियम शामिल
* बेहतर अनुकूलित डेटा प्रकार समर्थन (उदाहरण: JSON)

[GORM 2.0 रिलीज नोट](v2_release_note.html)

## v1.0 - 2016.04

[GORM V1 डॉक्स](https://v1.gorm.io)

ब्रेकिंग परिवर्तन:

* `gorm.Open` returns `*gorm.DB` instead of `gorm.DB`
* Updating will only update changed fields
* Soft Delete's will only check `deleted_at IS NULL`
* New ToDBName logic Common initialisms from [golint](https://github.com/golang/lint/blob/master/lint.go#L702) like `HTTP`, `URI` was converted to lowercase, so `HTTP`'s db name is `http`, but not `h_t_t_p`, but for some other initialisms not in the list, like `SKU`, it's db name was `s_k_u`, this change fixed it to `sku`
* Error `RecordNotFound` has been renamed to `ErrRecordNotFound`
* `mssql` dialect has been renamed to `github.com/jinzhu/gorm/dialects/mssql`
* `Hstore` has been moved to package `github.com/jinzhu/gorm/dialects/postgres`
