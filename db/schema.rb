# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20251024012252) do

  create_table "academicranks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "accesses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "stask_id"
    t.integer  "resource_id"
    t.string   "permision"
    t.datetime "dtfrom"
    t.datetime "dtto"
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["resource_id"], name: "index_accesses_on_resource_id", using: :btree
    t.index ["stask_id"], name: "index_accesses_on_stask_id", using: :btree
  end

  create_table "acchists", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "dlogin"
    t.datetime "dlogout"
    t.string   "location"
    t.string   "browser"
    t.string   "device"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "os"
    t.index ["user_id"], name: "index_acchists_on_user_id", using: :btree
  end

  create_table "adddocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "address_id"
    t.integer  "mediafile_id"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "mdate"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["address_id"], name: "index_adddocs_on_address_id", using: :btree
    t.index ["mediafile_id"], name: "index_adddocs_on_mediafile_id", using: :btree
  end

  create_table "addresses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.integer  "mediafile_id"
    t.string   "country"
    t.string   "province"
    t.string   "city"
    t.string   "district"
    t.string   "ward"
    t.text     "street",       limit: 65535
    t.string   "no"
    t.string   "stype"
    t.string   "status"
    t.text     "note",         limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["mediafile_id"], name: "index_addresses_on_mediafile_id", using: :btree
    t.index ["user_id"], name: "index_addresses_on_user_id", using: :btree
  end

  create_table "adocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "apply_id"
    t.integer  "mediafile_id"
    t.string   "name"
    t.string   "stype"
    t.string   "status"
    t.text     "note",         limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["apply_id"], name: "index_adocs_on_apply_id", using: :btree
    t.index ["mediafile_id"], name: "index_adocs_on_mediafile_id", using: :btree
  end

  create_table "applies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "position"
    t.string   "department"
    t.datetime "issued_date"
    t.string   "status"
    t.string   "interview"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["user_id"], name: "index_applies_on_user_id", using: :btree
  end

  create_table "appointments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "title",                     limit: 65535
    t.integer  "user_id"
    t.integer  "survey_id"
    t.string   "stype"
    t.string   "priority"
    t.string   "new_dept"
    t.string   "new_position"
    t.datetime "dtstart"
    t.string   "result"
    t.string   "status"
    t.text     "note",                      limit: 4294967295
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.string   "is_survey"
    t.datetime "expected_appointment_date"
    t.datetime "appointment_date"
    t.datetime "probation_period"
    t.datetime "trust_collection_period"
    t.index ["survey_id"], name: "index_appointments_on_survey_id", using: :btree
    t.index ["user_id"], name: "index_appointments_on_user_id", using: :btree
  end

  create_table "appointsurveys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "appointment_id"
    t.integer  "user_id"
    t.string   "result"
    t.datetime "dtsent"
    t.datetime "dtfinished"
    t.string   "status"
    t.text     "note",           limit: 65535
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.datetime "dtdeadline"
    t.index ["appointment_id"], name: "index_appointsurveys_on_appointment_id", using: :btree
    t.index ["user_id"], name: "index_appointsurveys_on_user_id", using: :btree
  end

  create_table "archives", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "issued_place"
    t.string   "stype"
    t.datetime "issued_date"
    t.string   "status"
    t.integer  "mediafile_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "issue_id"
    t.string   "issue_type"
    t.string   "issue_level"
    t.index ["mediafile_id"], name: "index_archives_on_mediafile_id", using: :btree
    t.index ["user_id"], name: "index_archives_on_user_id", using: :btree
  end

  create_table "ardocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "archive_id"
    t.integer  "mediafile_id"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "mdate"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["archive_id"], name: "index_ardocs_on_archive_id", using: :btree
    t.index ["mediafile_id"], name: "index_ardocs_on_mediafile_id", using: :btree
  end

  create_table "attendances", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.datetime "dtcheckin"
    t.datetime "dtcheckout"
    t.string   "status"
    t.text     "reason",      limit: 65535
    t.text     "owner",       limit: 65535
    t.text     "docs",        limit: 65535
    t.datetime "approved_at"
    t.text     "approved_by", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["user_id"], name: "index_attendances_on_user_id", using: :btree
  end

  create_table "attenddetails", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "attend_id"
    t.datetime "dtcheckin"
    t.datetime "dtcheckout"
    t.string   "status"
    t.text     "reason",      limit: 65535
    t.text     "owner",       limit: 65535
    t.text     "docs",        limit: 65535
    t.datetime "approved_at"
    t.text     "approved_by", limit: 65535
    t.string   "pic"
    t.string   "stype"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["attend_id"], name: "index_attenddetails_on_attend_id", using: :btree
  end

  create_table "attends", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.datetime "checkin"
    t.datetime "checkout"
    t.string   "stype"
    t.string   "refitem1"
    t.string   "refitem2"
    t.string   "refitem3"
    t.string   "status"
    t.text     "note",              limit: 65535
    t.string   "total_time"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.text     "reason",            limit: 65535
    t.text     "owner",             limit: 65535
    t.text     "docs",              limit: 65535
    t.datetime "approved_at"
    t.text     "approved_by",       limit: 65535
    t.integer  "shiftselection_id"
    t.index ["shiftselection_id"], name: "index_attends_on_shiftselection_id", using: :btree
    t.index ["user_id"], name: "index_attends_on_user_id", using: :btree
  end

  create_table "banks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "branch"
    t.string   "address"
    t.string   "ba_number"
    t.string   "ba_name"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["user_id"], name: "index_banks_on_user_id", using: :btree
  end

  create_table "bedocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "benefit_id"
    t.integer  "mediafile_id"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "mdate"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["benefit_id"], name: "index_bedocs_on_benefit_id", using: :btree
    t.index ["mediafile_id"], name: "index_bedocs_on_mediafile_id", using: :btree
  end

  create_table "benefits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "amount"
    t.string   "stype"
    t.integer  "mediafile_id"
    t.datetime "dtfrom"
    t.datetime "dtto"
    t.string   "status"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.text     "desc",         limit: 65535
    t.string   "syear"
    t.integer  "sbenefit_id"
    t.string   "btype"
    t.index ["mediafile_id"], name: "index_benefits_on_mediafile_id", using: :btree
    t.index ["sbenefit_id"], name: "index_benefits_on_sbenefit_id", using: :btree
    t.index ["user_id"], name: "index_benefits_on_user_id", using: :btree
  end

  create_table "companies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "apply_id"
    t.string   "name"
    t.string   "period"
    t.string   "position"
    t.string   "leader"
    t.text     "comments",   limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "department"
    t.index ["apply_id"], name: "index_companies_on_apply_id", using: :btree
  end

  create_table "condocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "contract_id"
    t.integer  "mediafile_id"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "mdate"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["contract_id"], name: "index_condocs_on_contract_id", using: :btree
    t.index ["mediafile_id"], name: "index_condocs_on_mediafile_id", using: :btree
  end

  create_table "connects", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "stream_id"
    t.string   "nbegin"
    t.string   "nend"
    t.string   "color"
    t.string   "linetype"
    t.string   "endlinetype"
    t.text     "note",        limit: 65535
    t.string   "status"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.text     "path",        limit: 65535
    t.string   "pbegin"
    t.string   "pend"
    t.string   "forms"
    t.string   "idenfity"
    t.index ["stream_id"], name: "index_connects_on_stream_id", using: :btree
  end

  create_table "contractdetails", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "contract_id"
    t.integer  "amount"
    t.string   "stype"
    t.string   "name"
    t.string   "cdparent"
    t.text     "desc",           limit: 65535
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.text     "scontent",       limit: 4294967295
    t.integer  "tmpcontract_id"
    t.index ["contract_id"], name: "index_contractdetails_on_contract_id", using: :btree
    t.index ["tmpcontract_id"], name: "index_contractdetails_on_tmpcontract_id", using: :btree
  end

  create_table "contracts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "mediafile_id"
    t.string   "name"
    t.string   "issued_by"
    t.datetime "issued_date"
    t.string   "issued_place"
    t.datetime "dtfrom"
    t.datetime "dtto"
    t.string   "status"
    t.text     "note",         limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "base_salary"
    t.index ["mediafile_id"], name: "index_contracts_on_mediafile_id", using: :btree
    t.index ["user_id"], name: "index_contracts_on_user_id", using: :btree
  end

  create_table "contracttimes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contracttypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "is_seniority"
  end

  create_table "ddocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "department_id"
    t.integer  "mediafile_id"
    t.text     "note",          limit: 65535
    t.string   "status"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["department_id"], name: "index_ddocs_on_department_id", using: :btree
    t.index ["mediafile_id"], name: "index_ddocs_on_mediafile_id", using: :btree
  end

  create_table "departments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "parents"
    t.string   "children"
    t.datetime "issued_date"
    t.string   "issued_by"
    t.string   "issued_place"
    t.text     "note",            limit: 65535
    t.string   "status"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "issue_id"
    t.string   "stype"
    t.integer  "organization_id"
    t.string   "name_en"
    t.string   "leader"
    t.string   "email"
    t.string   "faculty"
    t.string   "amount"
    t.text     "office",          limit: 65535
    t.text     "deputy",          limit: 65535
    t.string   "is_virtual"
    t.index ["organization_id"], name: "index_departments_on_organization_id", using: :btree
  end

  create_table "departmenttypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "discdocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "mediafile_id"
    t.integer  "discipline_id"
    t.string   "status"
    t.text     "note",          limit: 65535
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["discipline_id"], name: "index_discdocs_on_discipline_id", using: :btree
    t.index ["mediafile_id"], name: "index_discdocs_on_mediafile_id", using: :btree
  end

  create_table "disciplines", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "scode"
    t.text     "note",       limit: 65535
    t.string   "stype"
    t.string   "status"
    t.datetime "mdate"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["user_id"], name: "index_disciplines_on_user_id", using: :btree
  end

  create_table "docs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "mediafile_id"
    t.datetime "udate"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "stype"
    t.index ["mediafile_id"], name: "index_docs_on_mediafile_id", using: :btree
    t.index ["user_id"], name: "index_docs_on_user_id", using: :btree
  end

  create_table "educations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "errlogs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "msg",        limit: 4294967295
    t.text     "msgdetails", limit: 4294967295
    t.string   "owner"
    t.datetime "dtaccess"
    t.text     "surl",       limit: 65535
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "ethnics", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "forms", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "app"
    t.string   "status"
    t.text     "note",       limit: 65535
    t.text     "contents",   limit: 16777215
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "functions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "sname"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gsurveys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "iorder"
    t.string   "status"
    t.text     "note",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "gtasks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "name",       limit: 65535
    t.string   "scode"
    t.text     "sdesc",      limit: 65535
    t.integer  "iorder"
    t.string   "sorg"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "is_root"
  end

  create_table "hismaintenances", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "app"
    t.string   "period"
    t.string   "oips"
    t.string   "opentiming"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "holdetails", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "holiday_id"
    t.text     "name",       limit: 65535
    t.string   "amount"
    t.string   "stype"
    t.text     "note",       limit: 4294967295
    t.string   "status"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.datetime "dtdeadline"
    t.string   "used"
    t.index ["holiday_id"], name: "index_holdetails_on_holiday_id", using: :btree
  end

  create_table "holdocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "holiday_id"
    t.integer  "mediafile_id"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "mdate"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["holiday_id"], name: "index_holdocs_on_holiday_id", using: :btree
    t.index ["mediafile_id"], name: "index_holdocs_on_mediafile_id", using: :btree
  end

  create_table "holidays", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "mediafile_id"
    t.string   "name"
    t.datetime "issued_date"
    t.string   "issued_place"
    t.string   "status"
    t.text     "note",         limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "stype"
    t.string   "total"
    t.string   "used"
    t.string   "year"
    t.index ["mediafile_id"], name: "index_holidays_on_mediafile_id", using: :btree
    t.index ["user_id"], name: "index_holidays_on_user_id", using: :btree
  end

  create_table "holpros", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "stype"
    t.text     "sholtype",          limit: 65535
    t.datetime "dtcreated"
    t.datetime "dtfrom"
    t.datetime "dtto"
    t.text     "handover_receiver", limit: 65535
    t.text     "details",           limit: 65535
    t.string   "status"
    t.string   "priority"
    t.text     "issued_place",      limit: 65535
    t.integer  "holtemp_id"
    t.string   "result"
    t.text     "dttotal",           limit: 65535
    t.text     "note",              limit: 65535
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "holiday_id"
    t.text     "issued_national",   limit: 65535
    t.text     "place_before_hol",  limit: 4294967295
    t.index ["holiday_id"], name: "index_holpros_on_holiday_id", using: :btree
    t.index ["holtemp_id"], name: "index_holpros_on_holtemp_id", using: :btree
  end

  create_table "holprosdetails", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "stype"
    t.text     "sholtype",          limit: 65535
    t.datetime "dtfrom"
    t.datetime "dtto"
    t.text     "handover_receiver", limit: 65535
    t.text     "details",           limit: 65535
    t.string   "status"
    t.string   "priority"
    t.text     "issued_place",      limit: 65535
    t.integer  "holpros_id"
    t.string   "result"
    t.text     "itotal",            limit: 65535
    t.text     "note",              limit: 65535
    t.string   "issued_national"
    t.text     "place_before_hol",  limit: 65535
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["holpros_id"], name: "index_holprosdetails_on_holpros_id", using: :btree
  end

  create_table "holtemps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "title",      limit: 65535
    t.text     "content",    limit: 4294967295
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.string   "dept"
    t.string   "status"
    t.text     "note",       limit: 65535
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "sholtypes"
  end

  create_table "holtypedetails", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "holtype_id"
    t.string   "imax"
    t.string   "salary_rate"
    t.string   "salias"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["holtype_id"], name: "index_holtypedetails_on_holtype_id", using: :btree
  end

  create_table "holtypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "name",       limit: 65535
    t.string   "code"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "sholtemp"
  end

  create_table "idendocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "identity_id"
    t.integer  "mediafile_id"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "mdate"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["identity_id"], name: "index_idendocs_on_identity_id", using: :btree
    t.index ["mediafile_id"], name: "index_idendocs_on_mediafile_id", using: :btree
  end

  create_table "identities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.integer  "mediafile_id"
    t.datetime "issued_date"
    t.string   "issued_by"
    t.string   "issued_place"
    t.datetime "issued_expired"
    t.string   "stype"
    t.string   "status"
    t.text     "note",           limit: 65535
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["mediafile_id"], name: "index_identities_on_mediafile_id", using: :btree
    t.index ["user_id"], name: "index_identities_on_user_id", using: :btree
  end

  create_table "maintenances", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "app"
    t.string   "period"
    t.string   "oips"
    t.string   "opentiming"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mandocbooks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "mandocdhandles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "mandoc_id"
    t.integer  "department_id"
    t.string   "srole"
    t.datetime "deadline"
    t.text     "contents",      limit: 4294967295
    t.string   "status"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.index ["department_id"], name: "index_mandocdhandles_on_department_id", using: :btree
    t.index ["mandoc_id"], name: "index_mandocdhandles_on_mandoc_id", using: :btree
  end

  create_table "mandocfiles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "mandoc_id"
    t.integer  "mediafile_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "dtype"
    t.index ["mandoc_id"], name: "index_mandocfiles_on_mandoc_id", using: :btree
    t.index ["mediafile_id"], name: "index_mandocfiles_on_mediafile_id", using: :btree
  end

  create_table "mandocfroms", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "mandocpriorities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "mandocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "type_book"
    t.string   "sno"
    t.string   "ssymbol"
    t.string   "stype"
    t.string   "signed_by"
    t.text     "contents",               limit: 4294967295
    t.text     "notes",                  limit: 4294967295
    t.string   "slink"
    t.string   "created_by"
    t.datetime "effective_date"
    t.string   "spriority"
    t.string   "number_pages"
    t.datetime "deadline"
    t.datetime "received_at"
    t.string   "status"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "sfrom"
    t.string   "smark"
    t.string   "mdepartment"
    t.string   "received_place"
    t.integer  "organization_id"
    t.datetime "end_date"
    t.string   "dchild"
    t.string   "publish_to_departments"
    t.string   "publish_to_staffs"
    t.text     "publish_email_subject",  limit: 65535
    t.text     "publish_email_content",  limit: 4294967295
    t.text     "comment",                limit: 4294967295
    t.integer  "appointment_id"
    t.integer  "holpros_id"
    t.index ["appointment_id"], name: "index_mandocs_on_appointment_id", using: :btree
    t.index ["holpros_id"], name: "index_mandocs_on_holpros_id", using: :btree
    t.index ["organization_id"], name: "index_mandocs_on_organization_id", using: :btree
  end

  create_table "mandoctypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "mandocuhandles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "mandocdhandle_id"
    t.integer  "user_id"
    t.string   "srole"
    t.datetime "deadline"
    t.text     "contents",         limit: 4294967295
    t.string   "status"
    t.text     "notes",            limit: 4294967295
    t.string   "sread"
    t.datetime "received_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "sothers"
    t.index ["mandocdhandle_id"], name: "index_mandocuhandles_on_mandocdhandle_id", using: :btree
    t.index ["user_id"], name: "index_mandocuhandles_on_user_id", using: :btree
  end

  create_table "mdevices", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "userid"
    t.text     "stoken",     limit: 65535
    t.integer  "icount"
    t.string   "stype"
    t.string   "sversion"
    t.string   "status"
    t.text     "note",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "mediafiles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "file_name"
    t.string   "file_type"
    t.string   "file_size"
    t.string   "owner"
    t.string   "status"
    t.text     "note",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "mhistories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "stable"
    t.string   "srowid"
    t.text     "fvalue",     limit: 65535
    t.text     "tvalue",     limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "owner"
  end

  create_table "msettings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "stype"
    t.string   "name"
    t.string   "scode"
    t.text     "svalue",     limit: 65535
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "myapps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.text     "note",       limit: 65535
    t.string   "spath"
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "mydochis", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "mydoc_id"
    t.text     "fvalue",     limit: 4294967295
    t.string   "tvalue"
    t.string   "sfield"
    t.string   "owner"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.text     "tovalue",    limit: 4294967295
    t.index ["mydoc_id"], name: "index_mydochis_on_mydoc_id", using: :btree
  end

  create_table "mydocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "app"
    t.text     "content",    limit: 4294967295
    t.text     "meta",       limit: 65535
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "mylogs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "userid"
    t.string   "user_name"
    t.string   "user_email"
    t.text     "spath",        limit: 65535
    t.text     "saction_name", limit: 65535
    t.datetime "dtstart"
    t.datetime "dtend"
    t.text     "note",         limit: 4294967295
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "nationalities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nodes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "department_id"
    t.string   "color"
    t.string   "width"
    t.string   "height"
    t.string   "px"
    t.string   "py"
    t.text     "note",          limit: 65535
    t.string   "status"
    t.integer  "stream_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "nfirst"
    t.index ["department_id"], name: "index_nodes_on_department_id", using: :btree
    t.index ["stream_id"], name: "index_nodes_on_stream_id", using: :btree
  end

  create_table "notifies", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "title",      limit: 65535
    t.text     "contents",   limit: 4294967295
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.text     "receivers",  limit: 4294967295
    t.text     "senders",    limit: 65535
    t.string   "status"
    t.string   "stype"
    t.datetime "dtsent"
    t.string   "priority"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "operstreams", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "sfundction"
    t.integer  "organization_id"
    t.integer  "stream_id"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "sfunction"
    t.integer  "function_id"
    t.index ["function_id"], name: "index_operstreams_on_function_id", using: :btree
    t.index ["organization_id"], name: "index_operstreams_on_organization_id", using: :btree
    t.index ["stream_id"], name: "index_operstreams_on_stream_id", using: :btree
  end

  create_table "oqsurveries", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "qsurvey_id"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.integer  "iorder"
    t.text     "optvalue",   limit: 4294967295
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["qsurvey_id"], name: "index_oqsurveries_on_qsurvey_id", using: :btree
  end

  create_table "organizations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payslipdetails", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "payslip_id"
    t.integer  "amount"
    t.string   "name"
    t.string   "cparent"
    t.string   "stype"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["payslip_id"], name: "index_payslipdetails_on_payslip_id", using: :btree
  end

  create_table "payslips", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "smonth"
    t.string   "syear"
    t.integer  "base_salary"
    t.integer  "extra_income"
    t.integer  "dedution"
    t.integer  "snet"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["user_id"], name: "index_payslips_on_user_id", using: :btree
  end

  create_table "permissions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "positionjobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.integer  "department_id"
    t.string   "created_by"
    t.string   "status"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.text     "note",          limit: 65535
    t.string   "holno"
    t.integer  "iorder"
    t.integer  "reqno"
    t.integer  "amount"
    t.string   "is_root"
    t.string   "ignore_attend"
    t.index ["department_id"], name: "index_positionjobs_on_department_id", using: :btree
  end

  create_table "qrcodes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "department_id"
    t.datetime "dtvalidfrom"
    t.datetime "dtvalidto"
    t.text     "svalue",        limit: 65535
    t.text     "name",          limit: 65535
    t.text     "distance",      limit: 65535
    t.string   "status"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["department_id"], name: "index_qrcodes_on_department_id", using: :btree
  end

  create_table "qsurveys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "survey_id"
    t.integer  "gsurvey_id"
    t.integer  "iorder"
    t.text     "content",    limit: 4294967295
    t.string   "stype"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.text     "author",     limit: 65535
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["gsurvey_id"], name: "index_qsurveys_on_gsurvey_id", using: :btree
    t.index ["survey_id"], name: "index_qsurveys_on_survey_id", using: :btree
  end

  create_table "rdocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "regulation_id"
    t.integer  "mediafile_id"
    t.text     "note",          limit: 65535
    t.string   "name"
    t.string   "status"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["mediafile_id"], name: "index_rdocs_on_mediafile_id", using: :btree
    t.index ["regulation_id"], name: "index_rdocs_on_regulation_id", using: :btree
  end

  create_table "regulations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.text     "content",     limit: 65535
    t.string   "stype"
    t.datetime "issued_date"
    t.string   "status"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "relatives", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "apply_id"
    t.string   "name"
    t.datetime "birthday"
    t.string   "phone"
    t.string   "email"
    t.string   "stype"
    t.string   "state"
    t.text     "note",             limit: 65535
    t.string   "status"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "identity"
    t.string   "identity_type"
    t.datetime "identity_date"
    t.string   "identity_place"
    t.string   "taxid"
    t.datetime "identity_expired"
    t.index ["apply_id"], name: "index_relatives_on_apply_id", using: :btree
  end

  create_table "reldocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "relative_id"
    t.integer  "mediafile_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["mediafile_id"], name: "index_reldocs_on_mediafile_id", using: :btree
    t.index ["relative_id"], name: "index_reldocs_on_relative_id", using: :btree
  end

  create_table "releasednotes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.text     "authors",    limit: 65535
    t.text     "contents",   limit: 16777215
    t.string   "dtrelease"
    t.string   "datetime"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "religions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reporttmps", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "filepath"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.string   "lang"
    t.string   "dept"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "resources", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "url",        limit: 65535
    t.string   "scode"
    t.string   "app"
    t.string   "name"
    t.string   "status"
    t.text     "note",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "responsibles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "stask_id"
    t.integer  "positionjob_id"
    t.text     "desc",           limit: 65535
    t.string   "status"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "gtask_id"
    t.index ["gtask_id"], name: "index_responsibles_on_gtask_id", using: :btree
    t.index ["positionjob_id"], name: "index_responsibles_on_positionjob_id", using: :btree
    t.index ["stask_id"], name: "index_responsibles_on_stask_id", using: :btree
  end

  create_table "revdocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "review_id"
    t.integer  "mediafile_id"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "mdate"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["mediafile_id"], name: "index_revdocs_on_mediafile_id", using: :btree
    t.index ["review_id"], name: "index_revdocs_on_review_id", using: :btree
  end

  create_table "reviews", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "mediafile_id"
    t.string   "reviewed_by"
    t.string   "reviewed_place"
    t.datetime "reviewed_date"
    t.text     "content",        limit: 65535
    t.string   "result"
    t.string   "status"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["mediafile_id"], name: "index_reviews_on_mediafile_id", using: :btree
    t.index ["user_id"], name: "index_reviews_on_user_id", using: :btree
  end

  create_table "sbenefits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "tbbenefit_id"
    t.string   "syear"
    t.integer  "amount"
    t.string   "stype"
    t.text     "desc",         limit: 65535
    t.string   "btype"
    t.string   "status"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "name"
    t.string   "scode"
    t.index ["tbbenefit_id"], name: "index_sbenefits_on_tbbenefit_id", using: :btree
  end

  create_table "scheduleweeks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "week_num"
    t.integer  "year"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "status"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.text     "reason",        limit: 4294967295
    t.datetime "checked_at"
    t.string   "checked_by"
    t.integer  "user_id"
    t.string   "time_required"
    t.string   "time_register"
    t.string   "time_worked"
    t.index ["user_id"], name: "index_scheduleweeks_on_user_id", using: :btree
  end

  create_table "schools", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "apply_id"
    t.string   "name"
    t.string   "period"
    t.string   "certificate"
    t.string   "address"
    t.text     "note",        limit: 65535
    t.string   "status"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "level"
    t.datetime "dtexpired"
    t.index ["apply_id"], name: "index_schools_on_apply_id", using: :btree
  end

  create_table "shiftissues", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "shiftselection_id"
    t.string   "stype"
    t.text     "name",              limit: 65535
    t.text     "content",           limit: 4294967295
    t.string   "approved_by"
    t.datetime "approved_at"
    t.string   "status"
    t.text     "note",              limit: 4294967295
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "us_start"
    t.string   "us_end"
    t.string   "ref_shift_changed"
    t.string   "docs"
    t.index ["shiftselection_id"], name: "index_shiftissues_on_shiftselection_id", using: :btree
  end

  create_table "shiftselections", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "workshift_id"
    t.datetime "work_date"
    t.string   "approved_by"
    t.datetime "approved_at"
    t.string   "status"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "start_time"
    t.string   "end_time"
    t.string   "is_day_off"
    t.text     "day_off_reason",  limit: 65535
    t.integer  "scheduleweek_id"
    t.string   "location"
    t.index ["scheduleweek_id"], name: "index_shiftselections_on_scheduleweek_id", using: :btree
    t.index ["user_id"], name: "index_shiftselections_on_user_id", using: :btree
    t.index ["workshift_id"], name: "index_shiftselections_on_workshift_id", using: :btree
  end

  create_table "signatures", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "mediafile_id"
    t.integer  "user_id"
    t.datetime "dtcreated"
    t.boolean  "isdefault"
    t.string   "status"
    t.text     "note",         limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["mediafile_id"], name: "index_signatures_on_mediafile_id", using: :btree
    t.index ["user_id"], name: "index_signatures_on_user_id", using: :btree
  end

  create_table "signdocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "mandoc_id"
    t.text     "tmp_file",   limit: 65535
    t.text     "stype",      limit: 65535
    t.text     "name",       limit: 65535
    t.text     "sprocess",   limit: 65535
    t.string   "status"
    t.text     "note",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["mandoc_id"], name: "index_signdocs_on_mandoc_id", using: :btree
  end

  create_table "signs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "signdoc_id"
    t.string   "swidth"
    t.string   "sheight"
    t.string   "px"
    t.string   "py"
    t.text     "signed_by",      limit: 65535
    t.string   "nopage"
    t.datetime "signed_at"
    t.text     "signer_email",   limit: 65535
    t.text     "signer_fn",      limit: 65535
    t.text     "signer_ln",      limit: 65535
    t.text     "signer_title",   limit: 65535
    t.text     "note",           limit: 65535
    t.string   "signatureid"
    t.text     "signature_path", limit: 65535
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.index ["signdoc_id"], name: "index_signs_on_signdoc_id", using: :btree
  end

  create_table "snotices", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "notify_id"
    t.integer  "user_id"
    t.string   "username"
    t.boolean  "isread"
    t.datetime "dtreceived"
    t.datetime "dtread"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notify_id"], name: "index_snotices_on_notify_id", using: :btree
    t.index ["user_id"], name: "index_snotices_on_user_id", using: :btree
  end

  create_table "socials", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "slink"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["user_id"], name: "index_socials_on_user_id", using: :btree
  end

  create_table "stasks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.text     "desc",             limit: 65535
    t.datetime "dtfrom"
    t.datetime "dtto"
    t.string   "created_by"
    t.string   "status"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.text     "frequency",        limit: 65535
    t.string   "level_handling"
    t.string   "level_difficulty"
    t.string   "priority"
    t.string   "handling_process"
    t.integer  "tfunction_id"
    t.text     "note",             limit: 65535
    t.integer  "gtask_id"
    t.string   "is_root"
    t.index ["gtask_id"], name: "index_stasks_on_gtask_id", using: :btree
    t.index ["tfunction_id"], name: "index_stasks_on_tfunction_id", using: :btree
  end

  create_table "streams", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "surveyrecords", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "qsurvey_id"
    t.text     "answer",           limit: 4294967295
    t.datetime "dtanswer"
    t.integer  "appointsurvey_id"
    t.string   "status"
    t.text     "note",             limit: 65535
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["appointsurvey_id"], name: "index_surveyrecords_on_appointsurvey_id", using: :btree
    t.index ["qsurvey_id"], name: "index_surveyrecords_on_qsurvey_id", using: :btree
  end

  create_table "surveys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "code"
    t.string   "stype"
    t.text     "note",       limit: 65535
    t.string   "status"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "syslogs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "userid"
    t.string   "user_name"
    t.string   "user_email"
    t.text     "spath",        limit: 65535
    t.text     "saction_name", limit: 65535
    t.datetime "dtstart"
    t.datetime "dtend"
    t.text     "note",         limit: 4294967295
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "taskdocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "mediafile_id"
    t.integer  "stask_id"
    t.text     "sdesc",        limit: 65535
    t.string   "note"
    t.string   "status"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["mediafile_id"], name: "index_taskdocs_on_mediafile_id", using: :btree
    t.index ["stask_id"], name: "index_taskdocs_on_stask_id", using: :btree
  end

  create_table "tbarchivelevels", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tbarchivetypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tbbenefits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tbdepartmenttypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tbhospitals", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tbuserstatuses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tbusertypes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "scode"
    t.string   "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tfunctions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "name",          limit: 65535
    t.string   "scode"
    t.text     "sdesc",         limit: 65535
    t.string   "sorg"
    t.string   "stype"
    t.integer  "department_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "parent"
    t.string   "is_root"
    t.index ["department_id"], name: "index_tfunctions_on_department_id", using: :btree
  end

  create_table "tmpcontracts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.text     "scontent",   limit: 4294967295
    t.string   "status"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "uctokens", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "contractdetail_id"
    t.string   "token"
    t.text     "svalue",            limit: 65535
    t.string   "status"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["contractdetail_id"], name: "index_uctokens_on_contractdetail_id", using: :btree
  end

  create_table "uorgs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "organization_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["organization_id"], name: "index_uorgs_on_organization_id", using: :btree
    t.index ["user_id"], name: "index_uorgs_on_user_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "sid"
    t.string   "username"
    t.string   "email"
    t.string   "password_digest"
    t.string   "gender"
    t.string   "nationality"
    t.string   "ethnic"
    t.string   "religion"
    t.string   "marriage"
    t.string   "insurance_no"
    t.string   "education"
    t.string   "academic_rank"
    t.string   "stype"
    t.string   "status"
    t.string   "token"
    t.datetime "expired"
    t.text     "note",                limit: 65535
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "birthday"
    t.string   "taxid"
    t.string   "insurance_reg_place"
    t.string   "place_of_birth"
    t.string   "email1"
    t.string   "phone"
    t.string   "mobile"
    t.string   "avatar"
    t.string   "staff_status"
    t.string   "staff_type"
    t.string   "benefit_type"
    t.string   "isvalid"
    t.string   "tmppwd"
    t.datetime "valid_to"
    t.text     "ilog",                limit: 65535
    t.text     "twofa",               limit: 65535
    t.integer  "login_failed"
    t.integer  "login_failed_2fa"
    t.string   "twofa_exam"
    t.text     "m_place_of_birth",    limit: 65535
    t.datetime "termination_date"
    t.string   "sroom"
    t.string   "ignore_attend"
  end

  create_table "wdocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "work_id"
    t.integer  "mediafile_id"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["mediafile_id"], name: "index_wdocs_on_mediafile_id", using: :btree
    t.index ["work_id"], name: "index_wdocs_on_work_id", using: :btree
  end

  create_table "windocs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "workin_id"
    t.integer  "mediafile_id"
    t.text     "note",         limit: 65535
    t.string   "status"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["mediafile_id"], name: "index_windocs_on_mediafile_id", using: :btree
    t.index ["workin_id"], name: "index_windocs_on_workin_id", using: :btree
  end

  create_table "workins", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "department_id"
    t.datetime "dtstart"
    t.datetime "dtend"
    t.datetime "dtsigned"
    t.string   "signedby"
    t.text     "note",          limit: 65535
    t.string   "status"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["department_id"], name: "index_workins_on_department_id", using: :btree
    t.index ["user_id"], name: "index_workins_on_user_id", using: :btree
  end

  create_table "works", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "user_id"
    t.integer  "positionjob_id"
    t.text     "desc",           limit: 65535
    t.string   "status"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "stask_id"
    t.integer  "gtask_id"
    t.index ["gtask_id"], name: "index_works_on_gtask_id", using: :btree
    t.index ["positionjob_id"], name: "index_works_on_positionjob_id", using: :btree
    t.index ["stask_id"], name: "index_works_on_stask_id", using: :btree
    t.index ["user_id"], name: "index_works_on_user_id", using: :btree
  end

  create_table "workshifts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "name",           limit: 65535
    t.string   "start_time"
    t.string   "end_time"
    t.string   "checkin_start"
    t.string   "checkin_end"
    t.string   "checkout_start"
    t.string   "checkout_end"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_foreign_key "accesses", "resources"
  add_foreign_key "accesses", "stasks"
  add_foreign_key "acchists", "users"
  add_foreign_key "adddocs", "addresses"
  add_foreign_key "adddocs", "mediafiles"
  add_foreign_key "addresses", "mediafiles"
  add_foreign_key "addresses", "users"
  add_foreign_key "adocs", "applies"
  add_foreign_key "adocs", "mediafiles"
  add_foreign_key "applies", "users"
  add_foreign_key "appointments", "surveys"
  add_foreign_key "appointments", "users"
  add_foreign_key "appointsurveys", "appointments"
  add_foreign_key "appointsurveys", "users"
  add_foreign_key "archives", "mediafiles"
  add_foreign_key "archives", "users"
  add_foreign_key "ardocs", "archives"
  add_foreign_key "ardocs", "mediafiles"
  add_foreign_key "attendances", "users"
  add_foreign_key "attenddetails", "attends"
  add_foreign_key "attends", "shiftselections"
  add_foreign_key "attends", "users"
  add_foreign_key "banks", "users"
  add_foreign_key "bedocs", "benefits"
  add_foreign_key "bedocs", "mediafiles"
  add_foreign_key "benefits", "mediafiles"
  add_foreign_key "benefits", "sbenefits"
  add_foreign_key "benefits", "users"
  add_foreign_key "companies", "applies"
  add_foreign_key "condocs", "contracts"
  add_foreign_key "condocs", "mediafiles"
  add_foreign_key "connects", "streams"
  add_foreign_key "contractdetails", "contracts"
  add_foreign_key "contractdetails", "tmpcontracts"
  add_foreign_key "contracts", "mediafiles"
  add_foreign_key "contracts", "users"
  add_foreign_key "ddocs", "departments"
  add_foreign_key "ddocs", "mediafiles"
  add_foreign_key "departments", "organizations"
  add_foreign_key "discdocs", "disciplines"
  add_foreign_key "discdocs", "mediafiles"
  add_foreign_key "disciplines", "users"
  add_foreign_key "docs", "mediafiles"
  add_foreign_key "docs", "users"
  add_foreign_key "holdetails", "holidays"
  add_foreign_key "holdocs", "holidays"
  add_foreign_key "holdocs", "mediafiles"
  add_foreign_key "holidays", "mediafiles"
  add_foreign_key "holidays", "users"
  add_foreign_key "holpros", "holidays"
  add_foreign_key "holpros", "holtemps"
  add_foreign_key "holprosdetails", "holpros", column: "holpros_id"
  add_foreign_key "holtypedetails", "holtypes"
  add_foreign_key "idendocs", "identities"
  add_foreign_key "idendocs", "mediafiles"
  add_foreign_key "identities", "mediafiles"
  add_foreign_key "identities", "users"
  add_foreign_key "mandocdhandles", "departments"
  add_foreign_key "mandocdhandles", "mandocs"
  add_foreign_key "mandocfiles", "mandocs"
  add_foreign_key "mandocfiles", "mediafiles"
  add_foreign_key "mandocs", "appointments"
  add_foreign_key "mandocs", "holpros", column: "holpros_id"
  add_foreign_key "mandocs", "organizations"
  add_foreign_key "mandocuhandles", "mandocdhandles"
  add_foreign_key "mandocuhandles", "users"
  add_foreign_key "mydochis", "mydocs"
  add_foreign_key "nodes", "departments"
  add_foreign_key "nodes", "streams"
  add_foreign_key "operstreams", "functions"
  add_foreign_key "operstreams", "organizations"
  add_foreign_key "operstreams", "streams"
  add_foreign_key "oqsurveries", "qsurveys"
  add_foreign_key "payslipdetails", "payslips"
  add_foreign_key "payslips", "users"
  add_foreign_key "positionjobs", "departments"
  add_foreign_key "qrcodes", "departments"
  add_foreign_key "qsurveys", "gsurveys"
  add_foreign_key "qsurveys", "surveys"
  add_foreign_key "rdocs", "mediafiles"
  add_foreign_key "rdocs", "regulations"
  add_foreign_key "relatives", "applies"
  add_foreign_key "reldocs", "mediafiles"
  add_foreign_key "reldocs", "relatives"
  add_foreign_key "responsibles", "gtasks"
  add_foreign_key "responsibles", "positionjobs"
  add_foreign_key "responsibles", "stasks"
  add_foreign_key "revdocs", "mediafiles"
  add_foreign_key "revdocs", "reviews"
  add_foreign_key "reviews", "mediafiles"
  add_foreign_key "reviews", "users"
  add_foreign_key "sbenefits", "tbbenefits"
  add_foreign_key "scheduleweeks", "users"
  add_foreign_key "schools", "applies"
  add_foreign_key "shiftissues", "shiftselections"
  add_foreign_key "shiftselections", "scheduleweeks"
  add_foreign_key "shiftselections", "users"
  add_foreign_key "shiftselections", "workshifts"
  add_foreign_key "signatures", "mediafiles"
  add_foreign_key "signatures", "users"
  add_foreign_key "signdocs", "mandocs"
  add_foreign_key "signs", "signdocs"
  add_foreign_key "snotices", "notifies"
  add_foreign_key "snotices", "users"
  add_foreign_key "socials", "users"
  add_foreign_key "stasks", "gtasks"
  add_foreign_key "stasks", "tfunctions"
  add_foreign_key "surveyrecords", "appointsurveys"
  add_foreign_key "surveyrecords", "qsurveys"
  add_foreign_key "taskdocs", "mediafiles"
  add_foreign_key "taskdocs", "stasks"
  add_foreign_key "tfunctions", "departments"
  add_foreign_key "uctokens", "contractdetails"
  add_foreign_key "uorgs", "organizations"
  add_foreign_key "uorgs", "users"
  add_foreign_key "wdocs", "mediafiles"
  add_foreign_key "wdocs", "works"
  add_foreign_key "windocs", "mediafiles"
  add_foreign_key "windocs", "workins"
  add_foreign_key "workins", "departments"
  add_foreign_key "workins", "users"
  add_foreign_key "works", "gtasks"
  add_foreign_key "works", "positionjobs"
  add_foreign_key "works", "stasks"
  add_foreign_key "works", "users"
end
