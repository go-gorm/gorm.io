<footer id="footer" class="wrapper">
  <div class="inner">
    <div id="footer-copyright">
      &copy; 2013~{{ moment(Date.now()).year() }} <a href="{{ config.author_url }}" target="_blank">{{ config.author }}</a><br>
      Documentation licensed under <a href="http://creativecommons.org/licenses/by/4.0/" target="_blank">CC BY 4.0</a>.<br>
      <div id="gorm.cn" style="display:none">
      感谢 <a href="https://www.qiniu.com/" target="_blank">七牛云</a> 对 CDN 的赞助，<a href="https://github.com/unknwon" target="_blank">无闻</a> 对域名 <a href="https://gorm.cn" target="_blank">gorm.cn</a> 的捐赠<br>
      <a href="http://beian.miit.gov.cn/" target="_blank" data-spm-anchor-id="a3c00.7621333.7y9jhqsfz.112">浙ICP备2020033190号-1</a><br>
      </div>

      <script>
        if (window.location.hostname.includes("gorm.cn")) {
          document.getElementById("gorm.cn").style.display = 'block';
        }
      </script>
    </div>
    <div id="footer-links">
      <a href="https://twitter.com/{{ config.twitter }}" class="footer-link" target="_blank"><i class="fab fa-twitter"></i></a>
      <a href="https://github.com/{{ config.github }}" class="footer-link" target="_blank"><i class="fab fa-github-alt"></i></a>
    </div>
  </div>
</footer>
