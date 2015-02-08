//This area builds each elements of the menu item which is later cloned
var menu_item_el = new Element('li');
var check_box = new Element('input',{
    'type':'checkbox'
});
var add_button =  new Element('a',{
    'class':'add button'
});
var name_el = new Element('span');

var head_item = new Element('li',{
    'class':'listhead'
});
var toggler = new Element('span',{
    'id':'togall',
    'class':'togall'
});
toggler.innerHTML = "ALL";

//the elements are put in order to make a single menu_item
function make_li(li_class,li_type,li_text,li_val){
    menu_item = menu_item_el.cloneNode(true);
    menu_item.addClassName(li_class);
    check_box.name = "school[school_"+li_type+"][]";
    check_box.id = li_type+"_check_"+li_val;
    check_box.value = li_val;
    add_button.addClassName(li_type+'_button');
    name_el.innerHTML = li_text;
    menu_item.insert(check_box);
    menu_item.insert(name_el);
    menu_item.insert(add_button);
    return menu_item.cloneNode(true);
}

//this is used to check all the menu_items and to uncheck
function toggle_check(button, list){
    if ($(button).innerHTML == "NONE")
    {
        $$(list).each(
            function(e){
                e.checked = false;
            })
        $(button).innerHTML = "ALL";
    }
    else
    {
        $$(list).each(
            function(e){
                e.checked = true;
            })
        $(button).innerHTML = "NONE";
    }

}

//this is used to check all the menu_items and to uncheck
function check_toggler(){
    if (this.innerHTML == 'NONE'){        
        this.up().siblings().invoke('down').each(function(e){
            e.checked = false;
        });
        this.innerHTML = 'ALL';
    }
    else
    {
        this.up().siblings().invoke('down').each(function(e){
            e.checked = true;
        });
        this.innerHTML = 'NONE';
    }
}

//many menu items are made into a group and hence a menu
function show_submenu(menu_items,type,parent,check){
    if($(type+'_'+li.down().value)!=null){
        $(type+'_'+li.down().value).show();
    }
    else{
        ul = new Element('ul');
        ul.id = type+'_'+li.down().value;
        head = head_item.cloneNode(true);
        tog = toggler.cloneNode(true);
        if(menu_items.length != 0){
            head.innerHTML = (type.split("_").join(" ").capitalize())+" ";
        }
        else{
            head.innerHTML = ("No "+type.split("_").join(" ").capitalize())+" ";
        }
        head.insert(tog);
        ul.insert(head);
    
        menu_items.each(function(e){
            var sub_menu_li ;
            sub_menu_li = make_li('listodd',type,e[0],e[1])
            sub_menu_li.down().checked = check;
            ul.appendChild(sub_menu_li);
        });
        top_index = parent.cumulativeOffset()[1];
        if (type != "school"){
            ul.setStyle('top:'+top_index+'px');
            ul.setStyle('position:absolute');
            ul.setStyle('max-height:400px');
        }else{
            ul.setStyle('position:absolute');
            ul.setStyle('overflow:scroll');
        }
        
        if(type == 'edu_district'){
            $('edu_list').insert(ul);
            $$('#edu_list input').invoke('observe','change',check_checker);
            $$('.'+type+'_button').invoke('observe','click',load_sub_district);
        }
        else if(type == 'sub_district'){
            $('sub_list').insert(ul);
            $$('#sub_list input').invoke('observe','change',check_checker);
            $$('.'+type+'_button').invoke('observe','click',load_school);
        }
        else if(type == 'school'){
            $('school_list').insert(ul);
            $$('#school_list input').invoke('observe','change',check_checker);
        }
        $$('.togall').invoke('observe','click',check_toggler);
    }
}

//make a edu_district menu
function load_education_district(){
    li = this.up();
    check =  this.previous(1).checked;
    id = li.down().value;
    type = "edu_district";
    dest = $('edu_list');
    $$('#edu_list ul').invoke('hide');
    $$('#sub_list ul').invoke('hide');
    $$('#school_list ul').invoke('hide');
    l_array = new Array();
    l_array = revenue_district_selected[id];
    show_submenu(l_array,type,li,check);
}

//make a sub_district menu
function load_sub_district(){
    li = this.up();
    check =  this.previous(1).checked;
    id = li.down().value;
    type = "sub_district";
    dest = $('sub_list');
    $$('#sub_list ul').invoke('hide');
    $$('#school_list ul').invoke('hide');
    l_array = new Array();
    l_array = edu_district_selected[id];
    show_submenu(l_array,type,li,check);
}

//make a school menu. Also see the javascripts/statebodies.js.erb in the view folder
function load_school(){
    li = this.up();
    check =  this.previous(1).checked;
    id = li.down().value;
    type = "school";
    dest = $('school_list');
    $$('#school_list ul').invoke('hide');
    if($('school_'+id) == null){        
        l_array = new Array();
        l_array = sub_district_selected(id,li,check);
    }
    else
    {
        $('school_'+id).show();
    }
}

//this Fn check the parent menu checked value unchecks the parent if not all the items of submenu
function check_checker(){    
    ul_id = this.up(1).id;
    input_list = $$("#"+ul_id+" input");
    res = exploder(ul_id);
    if(this.checked==true){
        check_child(this.id)
    }
    getout = false;
    input_list.each(function(e){
        if(e.checked==false){
            parent_uncheck(res);
            getout = true;
            return;
        }
    });
}

//this Fn unchecks a parent
function parent_uncheck(arr){
    switch(arr[1]){
        case "edu_district":
            $('rev_district_check_'+arr[0]).checked = false;
            break;
        case "sub_district":
            $('edu_district_check_'+arr[0]).checked = false;
            parent_id = $('edu_district_check_'+arr[0]).up(1).id;
            parent_uncheck(exploder(parent_id));
            break;
        case "school":
            $('sub_district_check_'+arr[0]).checked = false;
            parent_id = $('sub_district_check_'+arr[0]).up(1).id;
            parent_uncheck(exploder(parent_id));
            break;
    }
}
function check_child(parent_id){    
    arr = parent_id.split("_");
    child_menu_number = arr.pop();
    arr.pop();
    child_menu_type = arr.join("_");
    switch(child_menu_type){
        case "rev_district":
            child_menu_type = "edu_district";
            break;
        case "edu_district":
            child_menu_type = "sub_district";
            break;
        case "sub_district":
            child_menu_type = "school";
            break;
    }
    child_menu_id = child_menu_type+"_"+child_menu_number;    
    if ($(child_menu_id) == null){
        return;
    }
    $$("#"+child_menu_id+" input").each(function(e){
        e.checked = true;
        check_child(e.id);
    });
    
}

// helper explodes a word ("name_id") format and returns an array [name,id]
function exploder(name){
    arr=name.split("_");
    res = new Array();
    res[0] = arr.pop();
    res[1] = arr.join("_");
    return res;
}

function check_all(){
    if(this.checked){
        check_child(this.id);
    }
}

document.observe("dom:loaded", function() {
    $$('.rev_button').invoke('observe','click',load_education_district);
    $$('#rev_list input').invoke('observe','change',check_all);
    $$('.togall').invoke('observe','click',check_toggler);    
});