<div id="content-wrap">
  <div id="content" class="wrapper">
    <div id="content-inner">
      <article class="article-container" itemscope itemtype="http://schema.org/Article">
        <div class="article-inner">
          <div class="article">
            <div class="inner">
              <header class="article-header">
                <h1 class="article-title" itemprop="name">{{ page.title }}</h1>
                {% if page.lang ===  "en" %}
                <a href="{{ raw_link(page.source) }}" class="article-edit-link" title="{{ __('page.improve') }}"><i class="fa fa-pencil"></i></a>
                {% else %}
                <a href="https://translate.gorm.io/project/go-gorm/{{site.data.languages[page.lang].crowdin}}" class="article-edit-link" title="{{ __('page.improve') }}"><i class="fa fa-pencil"></i></a>
                {% endif %}
              </header>
              <div class="article-content" itemprop="articleBody">
                {{ page_anchor(page.content) }}
              </div>

              {% if page.path.match("doc") %}
              <div>
                <a href="v2_release_note.html" target="_blank">
                  <img alt="GitHub tag (latest SemVer)" src="https://img.shields.io/github/v/tag/go-gorm/gorm?label=Latest GORM Release&color=red&&style=for-the-badge&logo=go&logoColor=red">
                </a>
              </div>
              {% endif %}

              <footer class="article-footer">
                <time class="article-footer-updated" datetime="{{ date_xml(page.updated) }}" itemprop="dateModified">{{ __('page.last_updated', date(page.updated)) }}</time>
{{ page_nav() }}
              </footer>

              <div class="post_sponsors">
                {{ partial('partial/sponsors') }}
              </div>

              {{ partial('partial/comment') }}
            </div>
          </div>
          <aside id="article-toc" role="navigation">
            <div id="article-toc-inner">
              <div id="sidebar-ad-wrapper" class="tagmanager_ad"></div>
              <strong class="sidebar-title">{{ __('page.contents') }}</strong>
              {{ toc(page.content, {list_number: false}) }}

              {% if page.lang ===  "en" %}
                <a href="{{ raw_link(page.source) }}" target="_blank" id="article-improve">
                  {{ __('page.improve') }}
                </a>
              {% else %}
                <a href="https://translate.gorm.io/project/go-gorm/{{site.data.languages[page.lang].crowdin}}" target="_blank" id="article-improve">
                  {{ __('page.improve') }}
                </a>
              {% endif %}
              <a href="#" id="article-toc-top">{{ __('page.back_to_top') }}</a>
            </div>
          </aside>
        </div>
      </article>
      {{ partial('partial/sidebar') }}
    </div>
  </div>
</div>
