{% if page.comments && config.disqus_shortname %}
<section id="comments">
<div id="disqus_thread"></div>
</sction>

<script>
var disqus_config = function () {
this.page.url = '{{ url }}';
this.page.identifier = '{{ url }}';
this.language = '{{ disqus_lang() }}';
};

(function() { // DON'T EDIT BELOW THIS LINE
var d = document, s = d.createElement('script');
s.src = 'https://{{ config.disqus_shortname }}.disqus.com/embed.js';
s.setAttribute('data-timestamp', +new Date());
(d.head || d.body).appendChild(s);
})();
</script>
{% endif %}
