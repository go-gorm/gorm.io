<div class="sponsors-wrapper-pc open-collective-sponsors">
  <div class="inner">
    <div class="sponsors">
      <h1>Platinum Sponsors {% if !homepage %}<i class="far fa-kiss-wink-heart"></i>{% endif %}</h1>
      <div class="sponsor_item">
        <a href="https://chainlinklabs.com" target="_blank" rel="sponsored noopener">
          <img src="{{ url_for('/sponsors-imgs/chainlink.png') }}" alt="chainlink">
        </a>
      </div>

      <h1>Gold Sponsors {% if !homepage %}<i class="far fa-kiss-wink-heart"></i>{% endif %}</h1>
      <div class="sponsor_item">
        <a href="https://hubuc.com" target="_blank" rel="sponsored noopener">
          <img src="{{ url_for('/sponsors-imgs/hubuc.svg') }}" alt="hubuc">
        </a>
      </div>

      <a class="become-sponsor" href="/contribute.html#Donations">Become a Sponsor!</a>

      {% if page.path.match("contribute") %}
      <h1>Github Backers <i class="far fa-kiss-wink-heart"></i></h1>
      <div class="backers_link">
      View Github Backers on <a href="https://github.com/sponsors/jinzhu">https://github.com/sponsors/jinzhu</a>
      </div>

      <h1>Patreon Backers <i class="far fa-kiss-wink-heart"></i></h1>
      <div class="backers_link">
      View Patreon Backers on <a href="https://www.patreon.com/jinzhu">https://www.patreon.com/jinzhu</a>
      </div>
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

      <h1>Gold Sponsors</h1>
      <div class="sponsor_item">
        <a href="https://chainlinklabs.com" target="_blank" rel="sponsored noopener">
          <img src="{{ url_for('/sponsors-imgs/hubuc.svg') }}" alt="hubuc">
        </a>
      </div>

      <a class="become-sponsor" href="/contribute.html#Donations">Become a Sponsor!</a>
    </div>
  </div>
</div>
