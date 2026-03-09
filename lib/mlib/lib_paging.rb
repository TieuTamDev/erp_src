class CalculatorPaging
	def cal_limit_record(limit_record)
	  if(limit_record.to_s.empty?)
        limit_record = MConst::PAGE_LIMIT
      else
        limit_record = limit_record.to_i
      end
      return limit_record
	end

	def cal_total_page(limit_record, count)
	  total_page = 0      
      if(count.to_i % limit_record > 0)
        total_page = count / limit_record
      else
        total_page = count / limit_record - 1
      end
	end

	def cal_page_number(page_number, total_page)
	  if(page_number.to_s.empty?)
        page_number = 0
      else
        if(page_number.to_i <= 0)
          page_number = 0
        else  
          if page_number.to_i >= total_page
            page_number = total_page
          else
            page_number = page_number.to_i
          end
        end
      end
	end

	def paging(limit_record, page_number, count)
		
    end
end
public
  def cal_paging(limit_record, page_number, count)
    calculatorPaging = CalculatorPaging.new
    limit_record = calculatorPaging.cal_limit_record(limit_record)
	total_page = calculatorPaging.cal_total_page(limit_record, count)
	page_number = calculatorPaging.cal_page_number(page_number, total_page)
    start_row = page_number * limit_record
	if start_row < 0
		start_row = 0
	end
	
    return {limit_record: limit_record, page_number: page_number, start_row: start_row, total_page: total_page}
  end

  def convert_data_search(data)
    if data.to_s.empty?
      return ""
    else
      return data.strip
    end
  end