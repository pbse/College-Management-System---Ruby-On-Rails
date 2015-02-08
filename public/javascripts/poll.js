
function add_fields(link, association, content){
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g");
    $('options-container').insert({
        bottom: content.replace(regexp, new_id)
    });
}

function remove_fields(link){
//    console.log($(link).previous("input[type=hidden]"));
    $(link).previous("input[type=hidden]").value='1';
    $(link).up(".label-field-pair-for-poll-option").hide();
}

function toggle_custom(){
    if($('custom_answer').checked){
        $("custom").show();
    }
    else{
        $("custom").hide();
    }
    return true;
}