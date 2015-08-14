$(function() {
    $.each(data, function(key, val) {
        $("#choices").append('<h3><input type="checkbox" name="' + key +
           '" checked="checked" id="id' + key + '">' +
           '<label for="id' + key + '">'+ val.label + '</label></h3>');
    });
    
    $("#choices").find("input").click(drawGraphs);
    drawGraphs();
})
