showStatus = function(e, status) {
  $(e.currentTarget).parent('.options').hide();
  $(e.currentTarget).parent().siblings('.status').show().html(status);
}
$(document).ready(function() {
  $('.accept').click(function(e) {
    e.preventDefault();
    var player = $(e.currentTarget).attr('data_id'),
        image = $(e.currentTarget).attr('image_id');
    $.post('/update-player', { player_id: player, correct: true, image_id: image}, function(data) {
      console.log('sent');
    })
    showStatus(e, 'Accepted');
  });
  $('.reject').click(function(e) {
    e.preventDefault();
    var player = $(e.currentTarget).attr('data_id'),
        image = $(e.currentTarget).attr('image_id');
    $.post('/update-player', { player_id: player, correct: false, image_id: image}, function(data) {
      console.log('sent');
    })
    showStatus(e, 'Rejected');
  });
})