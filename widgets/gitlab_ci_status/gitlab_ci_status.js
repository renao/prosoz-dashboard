/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const Cls = (Dashing.GitlabCIStatus = class GitlabCIStatus extends Dashing.Widget {
  static initClass() {
  
    Batman.Filters.classByPipelineStatus = function(status) {
      if (status === 'success') {
        return 'pipeline-status--success';
      } else if (status === 'failed') {
        return 'pipeline-status--failed';
      } else {
        return 'pipeline-status--running';
      }
    };
  }

  ready() {}

  onData(data) {
    return console.log(data);
  }
});
Cls.initClass();
