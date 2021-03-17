<header id="banner" class="wrapper">
  <div class="inner">
    <h2 id="banner-title">{{ page.subtitle }}</h2>
    <div id="banner-start">
      <span id="banner-start-command">{{ config.start }}</span><a id="banner-start-link" href="docs/"><i class="fa fa-arrow-right"></i></a>
    </div>
    <div id="banner-share">{{ partial('partial/share') }}</div>
  </div>
</header>

<div id="content-wrap">
  <div class="wrapper">
    <div class="inner features">
      {{ page.content }}
    </div>
  </div>

  {{ partial('partial/sponsors', {homepage: true}) }}
</div>
