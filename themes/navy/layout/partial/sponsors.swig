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

      <h1>OpenCollective Sponsors {% if !homepage %}<i class="far fa-kiss-wink-heart"></i>{% endif %}</h1>
      {% if homepage %}
      <object type="image/svg+xml" data="https://opencollective.com/gorm/tiers/sponsor.svg?avatarHeight=58&width=1080"></object>
      {% else %}
      <object type="image/svg+xml" data="https://opencollective.com/gorm/tiers/sponsor.svg?avatarHeight=42&width=800"></object>
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
