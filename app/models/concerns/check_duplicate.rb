module CheckDuplicate
    extend ActiveSupport::Concern
  
    class_methods do
      def check_duplicate(field_name, value)
        self.where("#{field_name} = ?", value).exists?
      end
    end
    
  end