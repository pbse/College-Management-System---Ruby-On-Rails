 //the prtototype $$ does'nt work with other language characters like 'é', but jQuery works, $J will is combination of jQuery and Prototype $$
$J=function(paramstr){var j = jQuery.noConflict(); return $A(j(paramstr));}

//a class for DateField, it will return whether date is valid
// the variable datediv should contain a rails dateselect(with select boxes for day, month and year) field


var DateField = Class.create();
DateField.prototype = {
    initialize : function(datediv){
        datesel = datediv.select('select');
        this.daysel = datesel[0];
        this.monthsel = datesel[1];
        this.yearsel = datesel[2];

        this.day = this.daysel.value;
        this.month = this.monthsel.value;
        this.year = this.yearsel.value;
        if(this.valid())
            this.value = this.day+'/'+this.month+'/'+this.year;
        else
            this.value = null;
    },
    valid : function(){
        this.enabled = !this.daysel.disabled || !this.monthsel.disabled || !this.yearsel.disabled;
        this.empty = this.day == "" || this.month == "" || this.year == "";
        return !(this.empty || !this.enabled);
    }
};
var invalid_el = new Element('span',{
    'class':'LV_validation_message LV_invalid',
    'id':'invalid_field'
});
function store_list() {
    $('dest').childElements().each(
        function(thing, count) {

        });
}
function swap() {
    this.update(this.text == "REMOVE" ? "ADD" : "REMOVE");
    li = this.up();
    src_ul = this.up(1);
    dest_ul = [$('src'), $('dest')].without(src_ul).first();
    dest_ul.insert(li);
}
function add(){
    li=this.up();
    pos=($('dest').children.length) + 1;
    li.down(3).value = pos;
    li.down(4).value = 0;
    $('dest').insert(li);
    li.highlight();
    elem=".select_"+li.id
    $J(elem+" input").each(
        function(e){
            e.disabled = 0;
        }
        );
}
function remove(){
    li=this.up();
    li.down(3).value = -1;
    li.down(4).value = 1;
    li_next=li.next();
    $('src').insert(li);
    li.highlight();
    elem=".select_"+li.id
    $J(elem+" input").each(
        function(e){
            e.disabled = 1;
        }
        );
    while (li_next != null)
    {
        li_next.down(3).value -= 1;
        li_next = li_next.next();
    }
}

function moveup() {
    li = this.up();
    prev = li.previous();
    if (prev) {
        temp =li.down(3).value;
        li.down(3).value = prev.down(3).value;
        prev.down(3).value = temp;
        prev.insert({
            before: li
        });
    }
    li.highlight();
}

function movedown() {
    li = this.up();
    nxt = li.next();
    if (nxt) {
        temp =li.down(3).value;
        li.down(3).value = nxt.down(3).value;
        nxt.down(3).value = temp;
        nxt.insert({
            after: li
        });
        li.highlight();
    }
}

function div_toggle(){
    elem='.'+this.id

    if (this.checked)
    {
        $('disp').show();
        $J(elem).each(
            function (e) {
                e.show();

            }
            );
        $J(elem+" input,"+elem+" select").each(
            function(e){
                e.disabled = 0;
            }
            );
    }
    else
    {
        disp = false
        $J('.fields').each(
            function(e){
                if (e.style.display == "")
                {
                    disp = true;
                }

            }
            );

        if (disp==false)
        {
            $('disp').hide();
        }
        else
        {
            $('disp').show();
        }
        $J(elem).each(
            function (e) {
                e.hide();
            }
            );
        $J(elem+" input,"+elem+" select").each(
            function(e){
                e.disabled = 1;
            }
            );
    }
}

//Here starts the validation

function text_fields_present(){
    var text_fields = $$('.query-fields .text input');
    var filled_fields = new Array();
    text_fields.each(function(tf){
        if(tf.disabled == false && tf.value != ""){
            filled_fields[filled_fields.length] = tf;
        }
    });
    return !(filled_fields.length == 0);
}
//a class called DateField, which will return whether date is valid-- see top

function date_fields_present(){
    var date_fields = $$('.query-fields .date');
    var valid_fields = new Array();
    date_fields.each(function(dt){
        var date_check = new DateField(dt);
        if(date_check.valid()==true){
            valid_fields[valid_fields.length] = dt;
        }
    });
    return !(valid_fields.length == 0);
}

function check_box_present(){
    var check_boxes = $$('.query-fields .check input');
    var valid_fields = new Array();
    check_boxes.each(function(cb){
        if(!cb.disabled && cb.checked ){
            valid_fields[valid_fields.length] = cb;
        }
    });
    return !(valid_fields.length == 0);
}
function radio_button_present(){
    var radio_buttons = $$('.query-fields .radio-button input');
    var valid_fields = new Array();
    radio_buttons.each(function(rb){
        if(!rb.disabled && rb.checked ){
            valid_fields[valid_fields.length] = rb;
        }
    });
    return !(valid_fields.length == 0);
}
function report_column_present(){
    var report_columns = $('dest').childElements();
    var inv_el = invalid_el.cloneNode(true);
    inv_el.innerHTML = "No Input criterias.";
    return !(report_columns.length == 0);
}
function validate_form(){
    $('category-list').select('.LV_invalid').each(function(e){e.remove()});
    var inv_query = invalid_el.cloneNode(true);
    var inv_field = invalid_el.cloneNode(true);
    var query_present = (date_fields_present() || text_fields_present() || check_box_present() || radio_button_present() || radio_button_present());
    var column_present = report_column_present();
    inv_query.innerHTML = "No Input criterias.";
    if(!query_present) $('category-list').down().insert(inv_query);
    inv_field.innerHTML = "No Report fields selected.";
    if(!column_present) $('category-list').down().insert(inv_field );
    $('report_name').focus();
    return (query_present && column_present);
}

document.observe("dom:loaded", function() {

    $$('.swap').invoke('observe', 'click', swap);
    $$('.add').invoke('observe', 'click', add);
    $$('.remove').invoke('observe', 'click', remove);
    $$('.mup').invoke('observe', 'click', moveup);
    $$('.mud').invoke('observe', 'click', movedown);
    $$('.cbox').invoke('observe', 'click', div_toggle);
    $$('.cbox').each(
        function (e) {
            div_toggle.apply(e);
        }
        );
    $$('#src li input').each(
        function(e){
            e.disabled = 1;
        }
        );
    $$('#dest li input').each(
        function(e){
            e.disabled = 0;
        }
        );

});

