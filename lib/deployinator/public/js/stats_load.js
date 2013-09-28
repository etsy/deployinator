$(function() {
    $.each(data, function(key, val) {
        $("#choices").append('<br/><input type="checkbox" name="' + key +
           '" checked="checked" id="id' + key + '">' +
           '<label for="id' + key + '">'+ val.label + '</label>');
    });
    
    $("#choices").find("input").click(drawGraphs);
    drawGraphs();
})
