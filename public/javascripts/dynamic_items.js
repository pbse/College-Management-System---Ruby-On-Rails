var store_items = new Array();
    <% for item in @store_items -%>
    store_items.push(new Array(<%= item.store_id %>, '<%=h item.item_name %>', <%= item.id %>));
    <% end -%>


    function StoreSelected() {
    store_id = $('person_store_id').getValue();
    $$('#person_store_item_id select').each(function (ele){
        options = ele.options;
        options.length = 1;
        store_items.each(function(item) {
            if (item[0] == store_id) {
                options[options.length] = new Option(item[1], item[2]);
            }
        });

    });

}

document.observe('dom:loaded', function() {
    $('person_store_id').observe('change', StoreSelected);
});


