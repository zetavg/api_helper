this = locals[:self_resource]

unless inclusion_field(this).blank?
  inclusion_field(this).each_pair do |field_name, includable_field|
    # use this if fieldset is used
    # next if fieldset(this).present? && !fieldset(this).include?(field_name)

    # include that child
    if inclusion[this].include?(field_name)

      child field_name.to_sym, root: field_name.to_sym, object_root: false do
        template = (includable_field[:resource_name] || field_name).to_s.underscore.singularize
        extends template
      end

    # not to include that child
    else

      node field_name do |obj|
        if obj.try(includable_field[:id_field]).present?
          obj.try(includable_field[:id_field])
        else
          foreign_key = obj.class.try("#{field_name}_foreign_key")
          obj.try(foreign_key) if foreign_key.present?
        end
      end
    end
  end
end
