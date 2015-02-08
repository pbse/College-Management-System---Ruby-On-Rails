function add_fields(link, association, content){
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g");
    $(link).up().insert({
        before: content.replace(regexp, new_id)
    });
$$('.input-type-select').invoke('observe','change',toggle_custom);
}

function remove_fields(link){
//    console.log($(link).previous("input[type=hidden]"));
    $(link).previous("input[type=hidden]").value='1';
    $(link).up(".fields").hide();
}

function toggle_custom(){
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
$$('.input-type-select').invoke('observe','change',toggle_custom);
$('school_asset_asset_fields_attributes_0_field_type').fire('change');
$$('select').each(function(e){
    toggle_custom.call(e);
});
});
