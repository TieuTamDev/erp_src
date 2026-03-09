class Mediafile < ApplicationRecord
  has_many :ddocs
  has_many :departments, through: :ddocs
  
  has_many :adocs
  has_many :applies, through: :adocs
  
  has_many :bedocs
  has_many :benefites, through: :bedocs
  
  has_many :ardocs
  has_many :archives, through: :ardocs
  
  has_many :revdocs
  has_many :reviews, through: :revdocs
  
  has_many :holdocs
  has_many :holidays, through: :holdocs
  
    has_many :condocs
  has_many :contracts, through: :condocs
  
      has_many :idendocs
  has_many :identities, through: :idendocs
  
      has_many :adddocs
  has_many :addresses, through: :adddocs
  has_many :mandocfiles, dependent: :destroy
  
  after_destroy :delete_associated_file

  private

  def delete_associated_file
    return unless file_name.present?
    file_path = "/data/hrm/#{file_name}"
    File.delete(file_path) if File.exist?(file_path)
  end
  
end
