class Breadcrumb_Utils
  def get_breadcrumb(navi_path, platformName)
    result = []
    if !navi_path.nil? && navi_path.to_s !="/"
      # Get Mapplication
      platform = Mapplication.where("name = '#{platformName}'").first
      if platform.nil?
        return ""
      end
      navi_filter = MUtils.filter_url(navi_path)

      @navi = Naviitem.joins(:navigation).where("naviitems.path=?", navi_filter).where("navigations.mapplication_id=?",platform.id).first
      if @navi.nil?
        @navi = Naviitem.joins(:navigation).where("naviitems.path=?", navi_filter + "/").where("navigations.mapplication_id=?",platform.id).first
      end

      #@navi = Naviitem.where("path=?",navi_path).first
    if !@navi.nil?
      puts "NAVI is not NULL"
      result.push("<li class='active'>"+lib_translate(@navi.title)+"</li>")
      if !@navi.naviitemparent.nil?
        result_item = []
        render_breadcrumb_item(@navi.naviitemparent,result_item)
        result.insert(0, result_item)
      else
        result.insert(0,"<li><a href='/'>#{lib_translate('Home')}</a></li>")
      end
    else
      result.push("<li id='menu_active_empty' class='active'>#{lib_translate('Home')}</li>")
    end
    else
      result.push("<li id='menu_active_empty' class='active'>#{lib_translate('Home')}</li>")
    end
    return result.join("")
  end

  def render_breadcrumb_item(naviitem,result)
    result.insert(0, "<li><a href='"+naviitem.path+"'>"+lib_translate(naviitem.title)+"</a></li>")

    if !naviitem.naviitemparent.nil?
      result_item = []
      render_breadcrumb_item(naviitem.naviitemparent,result_item)
      result.insert(0, result_item)
    else
      result.insert(0, "<li><a href='/'>#{lib_translate('Home')}</a></li>")
    end
  end

  def get_breadcrumb_api(navi_path, navi_name)
    result = []
    if !navi_path.nil? && navi_path.to_s !="/"
      navigation = Navigation.where("name=?",navi_name).first
      @navi = Naviitem.where(:path => navi_path, :navigation_id=> navigation.id).first
      #@navi = Naviitem.where("path=?",navi_path).first
      if !@navi.nil?
        result.push("<li class='active'>"+lib_translate(@navi.title)+"</li>")
        if !@navi.naviitemparent.nil?
          result_item = []
          render_breadcrumb_item(@navi.naviitemparent,result_item)
          result.insert(0, result_item)
        else
          result.insert(0,"<li><a href='#{navigation.mapplication.app_root}'>#{lib_translate('Home')}</a></li>")
        end
      else
        result.push("<li id='menu_active_empty' class='active'>#{lib_translate('Home')}</li>")
      end
    else
      result.push("<li id='menu_active_empty' class='active'>#{lib_translate('Home')}</li>")
    end
    return result.join("")
  end
end
