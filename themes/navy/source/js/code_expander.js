(function() {
  'use strict';

  $("figure.highlight").on("mouseover", function() {
    let width = $(this).width();
    $(this).data("width", $(this).width())
    if (width < $(this).find("table").width()) {
      $(this).css("overflow-x", "scroll");
      $(this).width($(".article-content").width() + $("#article-toc").width());
    }
  }).on("mouseout", function() {
    $(this).width($(this).data("width"));
  })
}())
