module SigndocConcern extend ActiveSupport::Concern
  require 'open-uri'
  require 'fileutils'
  require 'combine_pdf'

  # Generate PDF with sign
  def generate_pdf_file(template,signs,signdoc_id,data)
    begin
      scale = 1.3333333333333333
      pdf_temp_path = ""
      output_pdf_path = ""
      # generate PDF by template
      margin = { top: 10, bottom: 10, left: 10, right: 10 }
      pdf_html = ActionController::Base.new.render_to_string(
        template: "templates/#{template}",
        locals: {
          :signs => "",
          :signdoc_id => signdoc_id,
          :data => data,
        }
      )
      pdf = WickedPdf.new.pdf_from_string(pdf_html,
        encoding: "UTF-8",
        margin: margin,
        page_size: 'A4',
        orientation: 'Portrait'
      ).dup
      pdf_temp_path = save_temp_pdf(pdf)
      pdf_file = CombinePDF.load(pdf_temp_path.dup)

      @temp_path = "/data/erp/mediafiles_tmp/"
      if !File.directory?(@temp_path)
        FileUtils.mkdir_p(@temp_path)
      end
      # generate PDF signs
      if signs.size > 0
        output_pdf_path = "#{@temp_path}#{Time.now.to_i}_#{random_string(10)}.pdf"
        # calc page size
        page_size = [(pdf_file.pages[0].page_size[2]).to_i,(pdf_file.pages[0].page_size[3]).to_i]
        font_path = "#{Rails.root}/app/assets/fonts/timesbd.ttf"
        Prawn::Document.generate(output_pdf_path,margin:[0,0,0,0],page_size:page_size) do |pdf_prawn|
          # add pages
          pdf_file.pages.each { |page| pdf_prawn.start_new_page()}
          # font
          pdf_prawn.font_families.update(
            "Times New Roman" => {
              normal: font_path,
              bold: font_path,
              italic: font_path,
              bold_italic: font_path,
            }
          )
          pdf_prawn.font "Times New Roman"
          # insert sign
          signs.each do |sign|
            pdf_prawn.go_to_page(sign.nopage.to_i)
            # image_path = downloadTempImage()
            # temp_images_path.push(image_path)
            # tọa độ PDF của prawn bắt đầu bằng góc dưới bên trái (WTH???)
            pos = [sign.px.to_i,sign.py.to_i]
            page_height = pdf_prawn.cursor
            pos[1] = page_height - pos[1]
            image_width = sign.swidth.to_i
            pdf_prawn.image open(sign.signature_path), at:pos, width:image_width
            # user sign name: font-size : 16px
            sign_user_name = sign.signer_fn || ""
            font_size = 12
            text_width = pdf_prawn.width_of(sign_user_name, size: font_size)
            image_height = sign.sheight.to_i
            offset = 10
            pos[1] = pos[1] - image_height - offset
            pos[0] = pos[0] + ((image_width - text_width)/2)
            pdf_prawn.draw_text sign_user_name, at: pos, size: font_size
          end
        end
        # merger pdf
        pdf_sign_file = CombinePDF.load(output_pdf_path)
        pdf_file.pages.each_with_index {|page,index|page << pdf_sign_file.pages[index]}
      end
      # delete template file
      removeTempFiles([pdf_temp_path])
      removeTempFiles([output_pdf_path])
    rescue => e
      # delete template file
      removeTempFiles([pdf_temp_path])
      removeTempFiles([output_pdf_path])
      raise e
    end
    
    pdf_file.to_pdf.dup
  end


    # save temp pdf
    def save_temp_pdf(pdf)
      @temp_path = "/data/erp/mediafiles_tmp/"
      if !File.directory?(@temp_path)
        FileUtils.mkdir_p(@temp_path)
      end
      file_name = random_string(10);
      temp_file_path = "#{@temp_path}#{file_name}.pdf"
      File.open(temp_file_path, 'wb') do |file|
        file << pdf
      end
      return temp_file_path
    end
  
    def downloadTempImage(path)
      @temp_path = "/data/erp/mediafiles_tmp/"
      if !File.directory?(@temp_path)
        FileUtils.mkdir_p(@temp_path)
      end
      image_url = path
      file_name = File.basename(image_url)
      temp_file_path = "#{@temp_path}#{"sign_#{random_string(10)}_#{Time.now.to_i}_#{file_name}"}"
      open(image_url) do |image|
        File.open(temp_file_path, 'wb') do |file|
          file.write(image.read)
        end
      end
      return temp_file_path
    end
  
    def removeTempFiles paths
      paths.each do |path|
        if !path.nil? && path != ""
          File.delete(path) if File.exist?(path)
        end
      end
    end
  
    def random_string(length)
      o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
      string = (0...length).map { o[rand(o.length)] }.join
      return string
    end

  def check_folder
    
  end

  def check_sign_exist(signdoc_id)
    return Sign.find_by(signdoc_id:signdoc_id,signed_by:session[:user_id_login]).present?
  end

end