module ApplicationHelper  
  def breadcrumbs(custom_items = nil)
    crumbs = []
    
    if custom_items.present? 
      crumbs = process_custom_breadcrumbs(custom_items)
    else 
      crumbs = process_automatic_breadcrumbs
    end

    render_breadcrumb_container(crumbs)
  end

  def required_label(form, field, text, options = {})
    html = form.label(field, text, options)
    html += content_tag(:span, ' *', class: 'text-danger')
    html.html_safe
  end
 
  private 
  def process_automatic_breadcrumbs
    crumbs = []
    path = request.path.split('/').reject(&:empty?)
    
    path.each_with_index do |segment, index|
      next if segment == 'rails'
      
      translated_segment = lib_translate("#{segment}") || segment.titleize
      
      link = if index == path.size - 1
              content_tag(:li, translated_segment, class: 'breadcrumb-item text-truncate active text-primary', style: 'max-width: 250px', title: translated_segment)
            else
              content_tag(:li, link_to(translated_segment, '/' + path[0..index].join('/')), class: 'breadcrumb-item text-truncate', style: 'max-width: 250px', title: translated_segment)
            end
      crumbs << link
    end

    crumbs
  end

  def process_custom_breadcrumbs(items)
    items.map do |item|
      if item[:current]
        content_tag(:li, lib_translate(item[:title]) || item[:title], class: 'breadcrumb-item text-truncate active text-primary', style: 'max-width: 250px', title: lib_translate(item[:title]) || item[:title])
      else
        content_tag(:li, link_to(lib_translate(item[:title]) || item[:title], item[:path]), class: 'breadcrumb-item text-truncate', style: 'max-width: 250px', title: lib_translate(item[:title]) || item[:title])
      end
    end
  end

  def render_breadcrumb_container(crumbs)
    content_tag(:ol, safe_join(crumbs), class: 'breadcrumb mb-1')
  end

  def to_roman(num)
    return '' if num <= 0
    roman_values = [
      [1000, 'M'], [900, 'CM'], [500, 'D'], [400, 'CD'],
      [100, 'C'], [90, 'XC'], [50, 'L'], [40, 'XL'],
      [10, 'X'], [9, 'IX'], [5, 'V'], [4, 'IV'], [1, 'I']
    ]
    result = ''
    roman_values.each do |value, symbol|
      while num >= value
        result += symbol
        num -= value
      end
    end
    result
  end


  # Hai 29/7/2025 setting_holidays collums sort
  def sort_link(column, title = nil)
    title ||= column.titleize
    current_column = params[:order_by]
    current_direction = params[:direction].to_s.downcase == 'desc' ? 'desc' : 'asc'

    new_direction = (current_column == column && current_direction == 'asc') ? 'desc' : 'asc'

    # Chọn icon phù hợp
    icon = if current_column == column
             current_direction == 'asc' ? '↑' : '↓'
           else
             '⇅'
           end

    link_to "#{title} #{icon}".html_safe,
            request.query_parameters.merge(order_by: column, direction: new_direction),
            class: "sort-link #{'active' if current_column == column}"
  end
end
