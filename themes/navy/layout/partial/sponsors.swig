<div class="sponsors-wrapper-pc open-collective-sponsors">
  <div class="inner">
    <div class="sponsors">
      <h1>Platinum Sponsors {% if !homepage %}<i class="far fa-kiss-wink-heart"></i>{% endif %}</h1>
      <div class="sponsor_item">
        <a href="https://chainlinklabs.com" target="_blank" rel="sponsored noopener">
          <img src="{{ url_for('/sponsors-imgs/chainlink.png') }}" alt="chainlink">
        </a>
      </div>

      <a class="become-sponsor" href="/contribute.html#Donations">Become a Sponsor!</a>

      {% if page.path.match("contribute") || homepage %}
      <h1>OpenCollective Sponsors {% if !homepage %}<i class="far fa-kiss-wink-heart"></i>{% endif %}</h1>
      {% if homepage %}
      <object type="image/svg+xml" data="https://opencollective.com/gorm/tiers/sponsor.svg?avatarHeight=58&width=1080"></object>
      {% else %}
      <object type="image/svg+xml" data="https://opencollective.com/gorm/tiers/sponsor.svg?avatarHeight=42&width=800"></object>
      {% endif %}
      {% endif %}

      {% if page.path.match("contribute") %}
      <h1>Github Backers <i class="far fa-kiss-wink-heart"></i></h1>
      <div class="backers_link">
      View Github Backers on <a href="https://github.com/sponsors/jinzhu">https://github.com/sponsors/jinzhu</a>
      </div>

      <h1>Patreon Backers <i class="far fa-kiss-wink-heart"></i></h1>
      <div class="backers_link">
      View Patreon Backers on <a href="https://www.patreon.com/jinzhu">https://www.patreon.com/jinzhu</a>
      </div>

      <h1>OpenCollective Backers <i class="far fa-kiss-wink-heart"></i></h1>
      <object type="image/svg+xml" data="https://opencollective.com/gorm/backers.svg?avatarHeight=32&width=760"></object>
      {% endif %}
    </div>
  </div>
</div>

<div class="sponsors-wrapper-mobile open-collective-sponsors">
  <div class="inner">
    <div class="sponsors">
      <h1>Platinum Sponsors</h1>
      <div class="sponsor_item">
        <a href="https://chainlinklabs.com" target="_blank" rel="sponsored noopener">
          <img src="{{ url_for('/sponsors-imgs/chainlink.png') }}" alt="chainlink">
        </a>
      </div>

      <a class="become-sponsor" href="/contribute.html#Donations">Become a Sponsor!</a>

      <h1>OpenCollective Sponsors</h1>
      {% if homepage %}
      <object type="image/svg+xml" data="https://opencollective.com/gorm/tiers/sponsor.svg?avatarHeight=48&width=350"></object>
      {% else %}
      <object type="image/svg+xml" data="https://opencollective.com/gorm/tiers/sponsor.svg?avatarHeight=38&width=350"></object>
      {% endif %}
    </div>
  </div>
</div>
