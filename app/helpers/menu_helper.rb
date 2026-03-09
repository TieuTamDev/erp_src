module MenuHelper
  def menu_tree
    {
      "Individual" => {
        group:true,
        permission:[],
        submenu:
        {
          "dashboard" =>{
            id:"dashboard",
            icon: "ierp i_dashboard",
            link: root_path(lang: session[:lang]),
            permission:[
              ["DASHBOARD","READ"]
            ],
            submenu:{}
          },
          "Notifies" =>{
            id:"",
            icon: "ierp ithong_bao",
            link: notifies_index_path(lang: session[:lang]),
            permission:[],
            submenu:{}
          }
        }
      }
    }
  end

  def render_menu(menu_tree)
    content_tag(:ul) do
      menu_tree.map do |name,menu|
        if menu[:group]
          render_menu_group(name)
        else
          render_menu_item(name,menu[:submenu])
        end
      end.join.html_safe
    end
  end


  def action_link(link)
    "active" if request.env["PATH_INFO"] == link
  end

  def render_menu_group(name)
    content_tag(:div, class: "row navbar-vertical-label-wrapper mt-3 mb-2") do
      content_tag(:div,lib_translate(name), class: "col-auto navbar-vertical-label") +
      content_tag(:div,class:"col ps-0") do
        content_tag(:hr,class:"mb-0 navbar-vertical-divider")
      end
    end
  end

  def render_menu_item(name,menu)
    if menu[:submenu].empty?
      bactive = request.env['PATH_INFO'] == menu[:link]
      content_tag(:li) do
        link_to(menu[:link],class: "nav-link #{bactive ? "active": ""}",id:menu[:id],role:"button") do
          content_tag(:div,class:"d-flex align-items-center") do
            concat content_tag(:span,class:"nav-link-icon") do
              content_tag(:span,class: menu[:icon])
            end
            concat content_tag(:span,lib_translate(name),class:"nav-link-text ps-1")
          end
        end
      end
    else 
      content_tag(:li) do
        link_to(class: "nav-link",id:menu[:id], href: name,role:"button") do
          content_tag(:div,class:"d-flex align-items-center") do
            content_tag(:span,class:"nav-link-icon") do
              content_tag(:span,class: menu[:icon])
            end +
            content_tag(:span,lib_translate(name),class:"nav-link-text ps-1")
          end
        end
      end +
      connect_tag(:ul, class:"") do
        items = item[:submenu].map do |tittle,item|
          render_menu_item(tittle, item)
        end.join.html_safe
      end
    end
  end


end