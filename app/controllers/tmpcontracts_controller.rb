class TmpcontractsController < ApplicationController
  def index
    contracts_types = Contracttype.all
    @contracts_temps = Tmpcontract.all
    @temp_datas = []

    # merge data
    contracts_types.each do |contract_type|
      data = {
        name: contract_type.name,
        id: nil
      }
      @contracts_temps.each do |contracts_temp|
        if contracts_temp.name == data[:name]
          data[:id] = contracts_temp.id
        end
      end
      @temp_datas.push(data)
    end
  end

  def find_one
    temp_id = params[:temp_id]
    temp_name = params[:temp_name]
    copy = params[:copy]
    temp_contract = Tmpcontract.where(id: temp_id).first
    if temp_contract.nil?
      temp_contract = {name: temp_name,scontent: ""}
    end
    respond_to do |format|
      if copy == "true"
        format.js { render js: "doCopy(#{temp_contract.to_json.html_safe});"}
      else
        format.js { render js: "loadTempdata(#{temp_contract.to_json.html_safe});"}
      end
    end
  end

  def update
    temp_id = params[:temp_id]
    temp_name = params[:temp_name]
    scontent = params[:scontent]
    
    temp_contract = Tmpcontract.where(id: temp_id).first
    
    if temp_contract.nil?
      Tmpcontract.create({
        name:temp_name,
        scontent:scontent
      })
      redirect_to tmpcontracts_index_path(lang: session[:lang]), notice: lib_translate("Thêm: #{temp_name}")
    else
      temp_contract.update({
        scontent:scontent,
      })
      redirect_to tmpcontracts_index_path(lang: session[:lang]), notice: lib_translate("Cập nhật: #{temp_name}")
    end

    
  end

end
