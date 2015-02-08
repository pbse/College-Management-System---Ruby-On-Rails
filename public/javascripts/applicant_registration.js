function add_fields(link, association, content){
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g");
    $(link).up().insert({
        before: content.replace(regexp, new_id)
    });
    if ($$('.input-type-select')!=""){
        $$('.input-type-select').invoke('observe','change',toggle_custom);
    }
}

function add_addl_attachment(link, association, content){
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g");
    if ($$(".addl_attachments").first().select("div.fields").size()==4){
        alert("Cant add more than 4 additional attachments.");
    }else{
        $(link).up().insert({
            before: content.replace(regexp, new_id)
        });
    }
}

function remove_fields(link){
    //    console.log($(link).previous("input[type=hidden]"));
    $(link).previous("input[type=hidden]").value='1';
    $(link).up(".fields").hide();
     j(link.up(".fields")).attr('class',"new_class")
}

function toggle_custom(val){
    console.log(this)
    console.log(val)
    dest = this.up(2).select('.custom')[0]
    //if(dest != null)
    if(this.value == 'text'){
        dest.hide();
    }
    else{
        dest.show();
    }
    return true; 
}
document.observe("dom:loaded", function() {
    if ($$('.input-type-select')!=""){
        $$('.input-type-select').invoke('observe','change',toggle_custom);
        $$('.input-type-select').first().fire('change');
        $$('select').each(function(e){
            toggle_custom.call(e);
        });
    }
});
