showStatus = function(status) {
  $('.options').hide();
  $('.status').show().html(status);
}
$(document).ready(function() {
  $('.accept').click(function(e) {
    e.preventDefault();
    var player = $(e.currentTarget).attr('data_id'),
        image = $(e.currentTarget).attr('image_id');
    $.post('/update-player', { player_id: player, correct: true, image_id: image}, function(data) {
      console.log('sent');
    })
    showStatus('Accepted');
  });
  $('.reject').click(function(e) {
    e.preventDefault();
    var player = $(e.currentTarget).attr('data_id'),
        image = $(e.currentTarget).attr('image_id');
    $.post('/update-player', { player_id: player, correct: false, image_id: image}, function(data) {
      console.log('sent');
    })
    showStatus('Rejected');
  });
})