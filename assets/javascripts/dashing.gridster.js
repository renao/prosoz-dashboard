/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
//= require_directory ./gridster

// This file enables gridster integration (http://gridster.net/)
// Delete it if you'd rather handle the layout yourself.
// You'll miss out on a lot if you do, but we won't hold it against you.

Dashing.gridsterLayout = function(positions) {
  Dashing.customGridsterLayout = true;
  positions = positions.replace(/^"|"$/g, '');
  positions = $.parseJSON(positions);
  const widgets = $("[data-row^=]");
  return (() => {
    const result = [];
    for (let index = 0; index < widgets.length; index++) {
      const widget = widgets[index];
      $(widget).attr('data-row', positions[index].row);
      result.push($(widget).attr('data-col', positions[index].col));
    }
    return result;
  })();
};

Dashing.getWidgetPositions = () => $(".gridster ul:first").gridster().data('gridster').serialize();

Dashing.showGridsterInstructions = function() {
  const newWidgetPositions = Dashing.getWidgetPositions();

  if (JSON.stringify(newWidgetPositions) !== JSON.stringify(Dashing.currentWidgetPositions)) {
    Dashing.currentWidgetPositions = newWidgetPositions;
    $('#save-gridster').slideDown();
    return $('#gridster-code').text(`\
<script type='text/javascript'>\n \
$(function() {\n \
\ \ Dashing.gridsterLayout('${JSON.stringify(Dashing.currentWidgetPositions)}')\n \
});\n \
</script>\
`);
  }
};

$(function() {
  $('#save-gridster').leanModal();

  return $('#save-gridster').click(() => $('#save-gridster').slideUp());
});
