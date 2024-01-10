define(function(){
  //http://stackoverflow.com/questions/1740700/how-to-get-hex-color-value-rather-than-rgb-value
  return function rgb2hex(rgb) {
      if (/^#[0-9A-F]{6}$/i.test(rgb)) return rgb;

      rgb = rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
      function hex(x) {
          return ("0" + parseInt(x).toString(16)).slice(-2);
      }
      return '#' + hex(rgb[1]) + hex(rgb[2]) + hex(rgb[3]);
  }
});
