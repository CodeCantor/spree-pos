Spree::Product.class_eval do
attr_accessible :ean
end
Spree::Variant.class_eval do
attr_accessible :ean
end
Deface::Override.new(:virtual_path => "spree/admin/products/_form",
    :name => "Add ean to product form",
    :insert_after => "code[erb-silent]:contains('has_variants')",
    :text => "<% unless @product.has_variants? %> <p>
    <%= f.label :ean, t(:ean) %><br>
    <%= f.text_field :ean, :size => 16 %>
    </p> <%end%>",
    :disabled => false)
