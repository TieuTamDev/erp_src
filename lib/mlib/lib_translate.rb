public
	def lib_translate(value)
	    # if lang != "en"
	    #   I18n.locale = lang
	    # end
    	return I18n.t("#{value}", :default => "#{value}")
  	end

  	def lib_translate_var(string, var)
	    sentence = I18n.t("#{string}", :default => "#{string}")
	    if sentence == string
	      var.each do |key, value|
	        return string.sub! key.to_s, value.to_s
	      end
	    else
	      return I18n.t(string, var) 
	    end
	end
	def current_translations
	  @translations ||= I18n.backend.send(:translations)
	  @translations[I18n.locale].with_indifferent_access
	end