# temp controller: Todo: Merge to mandoc index
class MandocOutgoingController < ApplicationController
    before_action :authorize
    def outgoing_index
        @newMandoc_dhandle = Mandocdhandle.new
        @departments = Department.all
        @mandocdhandles = Mandocdhandle.all
    end
    def outgoing_update
        mandoc_id = params[:mandoc_id]
        department_id = params[:department_id]
        department_help_ids = params[:department_help_ids]
        deadline = params[:deadline]
        contents = params[:contents]

        # "XULY"
        # "PHOIHOPXL"
        # save department_id
        Mandocdhandle.create({
            mandoc_id: mandoc_id,
            department_id: department_id,
            deadline: deadline,
            contents: contents,
            status: "ACTIVE",
            srole: "XULY"
        })

        # save department help if data exists
        if department_help_ids.kind_of?(Array)
            department_help_ids.each do |id|
                Mandocdhandle.create({
                    mandoc_id: mandoc_id,
                    department_id: id,
                    deadline: deadline,
                    contents: contents,
                    tatus: "ACTIVE",
                    srole: "PHOIHOPXL"
                })
            end
        end
    redirect_to mandoc_outgoing_outgoing_index_path(lang: session[:lang]), notice: department_help_ids.to_json.html_safe      
    end
end