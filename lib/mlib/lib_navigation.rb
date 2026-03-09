class Navigation_Utils
  def get_navigation(userId,userType,platformName,naviName)


    # Get navigation
    oPlatform = Mapplication.where("name = '#{platformName}'").first
    if oPlatform.nil?
      return ""
    end


    oNavigation = oPlatform.navigations.where("name = '#{naviName}'").first
    if oNavigation.nil?
      return ""
    end

    @navi_root_items = []
    if(userId.nil?)
      if(userType == MConst::CLIENT_ADMIN_SYSTEM)

        @navi_root_items = oNavigation.naviitems.where("naviitemparent_id is NULL")
      end
    else

      oUser = User.where("id = #{userId}").first
      oNavigation.naviitems.where("naviitemparent_id is NULL").order('morder asc').each do |oNavi|
        if does_accessright(userId,userType,oNavi.feature,"VIEW",platformName) == true #|| does_accessright_children(userId,userType,oNavi,"VIEW",platformName)
          @navi_root_items.append(oNavi)

        end

      end
    end

    result = []
    result.push("<ul>")
    @navi_root_items.each do |item|

      result_item = []
      render_navigation_item(item,result_item,userId,userType,platformName)
      result.push(result_item)

    end
    result.push("</ul>")
    return result.join("")

  end

  def render_navigation_item(naviitem,result,userId,userType,platfromName)
    @navi_item = Naviitem.find(naviitem)
    target = "_self"
    if @navi_item.path.downcase().include? MConst::WEBMAIL
      target = "_blank"
    end
    navi_title = lib_translate(@navi_item.title)
    if @navi_item.subordinates.count == 0
      if(does_accessright(userId,userType, @navi_item.feature,"VIEW", platfromName))
        result.push("<li id='navi_li_#{@navi_item.id}'>" + "<a id='navi_a_#{@navi_item.id}'  target ='#{target}'   href='" +@navi_item.path+ "'>"+ navi_title + "</a></li>")
      end
    else
      result.push("<li id='navi_li_#{@navi_item.id}'>" + "<a id='navi_#{@navi_item.id}' target ='#{target}'    href='" +@navi_item.path+ "'>"+ navi_title + "&nbsp;&nbsp;</a>")
      result.push("<ul id='child_navi_#{@navi_item.id}'>")
      @sorted_childrens = @navi_item.subordinates.order('morder asc')
      @sorted_childrens.each do |item|
          new_result = []
          render_navigation_item(item.id,new_result,userId,userType,platfromName)
          result.push(new_result)
      end
      result.push("</ul>")
      result.push("</li>")

    end
    return
  end

  # Get Application Navigation
  def get_applications_navigation(userId,userType,selected_app)
    if(userId.nil?)
      if(userType == MConst::CLIENT_ADMIN_SYSTEM)
        @apps = Mapplication.all
      end
    else
      @apps = []
      Mapplication.all.each do |mappl|

        #oChild_Apps = Mapplication.where("parent_app = #{mappl.id}")
        #if !oChild_Apps.nil? && oChild_Apps.count > 0
        #  flag = false
        #  oChild_Apps.each do |oApp|
        #    if  does_application_accessright(userId, userType,oApp.name)
        #      flag = true
        #    end
        #  end

        #  if flag == true
        #    @apps.push(mappl)
        #  end


        #else
          if  does_application_accessright(userId, userType,mappl.name)
            @apps.push(mappl)
          end
        #end


		  end
    end

    result = []
    result.push("<ul>")
    if(!@apps.nil?)
      @apps.each do |app|
          szhref = "#"
          szname = ""
          if !app.app_root.nil?
            szhref = app.app_root
          end
          if !app.name.nil?
                szname = lib_translate(app.name)
          end
          if app.status != MConst::STATE_STOPPED && (app.parent_app.nil? || app.parent_app == "" )
            if selected_app == szname
              result.push("<li>" + "<a href='" +szhref+ "' data-turbolinks='false' class='active_menu_header'>"+ szname + "</a>")
            else
              result.push("<li>" + "<a href='" +szhref+ "' data-turbolinks='false'>"+ szname + "</a>")
            end

            sub_apps = Mapplication.where("parent_app = #{app.id.to_s}").order("created_at asc")

            if sub_apps.count > 0
				if selected_app == szname
					result.push("<ul style='display:block;' id ='ul_#{szname}' >")
				else
					result.push("<ul>")
				end
              sub_apps.each do |oSubApp|
                szhref = "#"
                szname = ""
                if !oSubApp.app_root.nil?
                  szhref = oSubApp.app_root
                end
                if !oSubApp.name.nil?
                  szname = lib_translate(oSubApp.name)
                end
                if oSubApp.status != MConst::STATE_STOPPED
                  result.push("<li>" + "<a href='" +szhref+ "' data-turbolinks='false'>"+ szname + "</a></li>")
                end
              end
              result.push("</ul>")
            end
            result.push("</li>")
          end
      end
    end
    result.push("</ul>")
    return result.join("")
  end


end