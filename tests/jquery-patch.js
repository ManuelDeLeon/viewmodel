(function($) {
  $.fn.inlineStyle = function(prop) {
    return this.prop('style')[$.camelCase(prop)];
  };
})(jQuery);