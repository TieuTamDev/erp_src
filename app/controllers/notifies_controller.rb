class NotifiesController < ApplicationController
    before_action :authorize, only: [:index]

    include NotifiesHelper

    def index
        page = [params[:page].to_i, 1].max
        per_page = [params[:per_page].to_i, 10].max
        search = params.dig(:search, :value).to_s.strip.downcase
        filter_stype = params[:stype]
        is_handle = params[:is_handle]
        @STYPE = STYPE
        # Khai báo biến
        @oData = []
        gon.notifies_index_path = notifies_index_path(format: :json)
        @oData = Snotice.filtered_snotices(search, session[:user_id], page, per_page, @STYPE, filter_stype, is_handle)
        @totalCount = Snotice.count_filtered_snotices(search, session[:user_id], filter_stype, is_handle)

        respond_to do |format|
          format.html
          format.json { render json: {
            draw: params[:draw],
            recordsTotal: @totalCount,
            recordsFiltered: @totalCount,
            data: @oData
          }}
        end
    end

    def show
        @STYPE = STYPE
        stype = params[:stype]
        @isShow = params[:isShow]
        @notices_count = nil

        if stype.present?
          Snotice.where("user_id = ? AND (isread IS NULL OR isread = ?)", session[:user_id], false).update_all(isread: true, dtread: DateTime.now)
        end

        @notices = Snotice.joins(:notify)
          .select("snotices.*, notifies.*, snotices.id as id, notifies.id as notify_id, snotices.status as status_notice, notifies.status as status_notify")
          .where("snotices.user_id = ? AND snotices.isread = ?", session[:user_id], false)
          .where(created_at: 1.week.ago..Time.current)
          .order(created_at: :DESC, id: :DESC)
          .limit(20)

        @notices_total = Snotice.joins(:notify)
          .where("snotices.user_id = ? AND (snotices.isread IS NULL OR snotices.isread = ?)", session[:user_id], false)
          .where(created_at: 1.week.ago..Time.current)
          .count

        session[:notices_count] = @notices_total.to_i
        session[:notices_cached] = Time.current.to_i

        respond_to do |format|
          format.html
          format.js { render 'notifies/partial/notification' }
        end
    end

    def render_modal
        @isShow = params[:isShow]
        @notice = Snotice.joins(:notify)
                .select("snotices.*, notifies.*, snotices.id as id, notifies.id as notify_id, snotices.status as status_notice, notifies.status as status_notify")
                .find_by("snotices.id = ?", params[:snotices_id])
        @notice.update(isread: true, dtread: DateTime.now)

        @notices_total = Snotice.joins(:notify)
                                .where("snotices.user_id = ? AND (snotices.isread IS NULL OR snotices.isread = ?)", session[:user_id], false)
                                .where(created_at: 1.week.ago..Time.current)
                                .count

        session[:notices_count] = @notices_total.to_i
        session[:notices_cached] = Time.current.to_i

        case @notice.stype
        when "BO_NHIEM", "MIEN_NHIEM"
          @modal = "appointments"
        when "NOTIFICATION"
          @modal = STYPE["NOTIFICATION"]
        else
          @modal = STYPE[@notice&.stype] || STYPE["NOTIFICATION"]
        end
    end
end
