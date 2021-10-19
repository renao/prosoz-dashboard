/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// dashing.js is located in the dashing framework
// It includes jquery & batman for you.
//= require dashing.js

//= require_directory .
//= require_tree ../../widgets

console.log("Yeah! The dashboard has started!");

Dashing.on('ready', function() {
  if (!Dashing.widget_margins) { Dashing.widget_margins = [5, 5]; }
  if (!Dashing.widget_base_dimensions) { Dashing.widget_base_dimensions = [300, 360]; }
  if (!Dashing.numColumns) { Dashing.numColumns = 4; }

  const contentWidth = (Dashing.widget_base_dimensions[0] + (Dashing.widget_margins[0] * 2)) * Dashing.numColumns;

  return Batman.setImmediate(function() {
    $('.gridster').width(contentWidth);
    return $('.gridster ul:first').gridster({
      widget_margins: Dashing.widget_margins,
      widget_base_dimensions: Dashing.widget_base_dimensions,
      avoid_overlapped_widgets: !Dashing.customGridsterLayout,
      draggable: {
        stop: Dashing.showGridsterInstructions,
        start() { return Dashing.currentWidgetPositions = Dashing.getWidgetPositions(); }
      }
    });
  });
});
