class User < ActiveRecord::Base
	rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :email, :password, :password_confirmation, :remember_me
  attr_accessible :login, :email, :password, :password_confirmation, :remember_me, :level,
                  as: :admin
  has_many :one_tables, dependent: :destroy
  has_many :mongo_attachments
  has_many :blocks
  has_many :owner_users, :foreign_key => :owner_id, :dependent => :delete_all
  has_many :fav_users, :through => :owner_users, :source => :user
  has_many :user_owners, :class_name => 'OwnerUser', :dependent => :delete_all
  has_many :faved_users, :through => :user_owners, :source => :owner
  has_many :search_word_lists, :order => 'name', :dependent => :destroy
  has_many :sites, :order => 'name', :dependent => :delete_all

  has_many :permissions, dependent: :delete_all, class_name: 'UserModelPermission'

  has_many :activities, order: 'created_at desc'

  scope :loginable, where('level > 0')

  LEVEL_INACTIVE = 0
  LEVEL_VIEWABLE = 2
  LEVEL_EDITABLE = 4
  LEVEL_REMOVABLE = 6
  LEVEL_ADMIN = 8

  # DEPRECATED
  LEVEL_SITEADMIN = 6
  # DEPRECATED
  LEVEL_SYSTEMADMIN = 9

  LEVELS = [
          ['inactive', 0],
          ['data_viewable', 2],
          ['data_editable', 4],
          ['data_removable', 6],
          ['admin', 8],
  ]

  LEVELS_I18N = LEVELS.map { |level| [I18n.t("role.#{level[0]}"), level[1]] }

  LEVELS_HASH = Hash[*LEVELS.map { |level| level.reverse }.flatten]

  before_create :regenerate_api_tokens

  before_save do
    set_level_inactive_if_empty
    reset_roles
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    where(warden_conditions).loginable.first
  end

  def reset_roles
    cl = changes['level']
    return unless cl.present?
    self.roles.destroy_all
    level_key = LEVELS_HASH[cl[1]]
    if level_key =~ /^data_/
      self.add_role level_key, OneTable
    else
      self.add_role level_key
    end
  end

  def set_level_inactive_if_empty
    self[:level] ||= LEVEL_INACTIVE
  end

  def admin?; self.admin end
  def admin
    self.has_role? :admin
  end

  def data_viewable?; data_viewable end
  def data_viewable
    self.has_role :viewable, OneTable
  end

  # an alias of permissions
  def acl(*args)
    permissions(*args)
  end

  def accessible_sites
    self.permissions.accessible_instances(Site)
  end

  def level_as_string
    I18n.t "role.#{self.roles.first.try(:name) || 'inactive'}"
  end

  # list permitted one_tables
  def accessible_one_tables
    self.permissions.assigned_instances OneTable
  end
  def accessible_one_table_records
    self.permissions.accessible_instances OneTableRecord
  end

  def self.find_by_login_or_email(value)
    self.find_by_login(value) || self.find_by_email(value)
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserMailer.deliver_password_reset_instructions(self)
  end

  def create_attachment(value)
    self.mongo_attachments.create :file => value
  end

  def regenerate_api_tokens(save_after_op = false)
    self[:api_public_token] = RandomString.generate(:ascii_small, :numbers, :length => 40)
    self[:api_secret_token] = RandomString.generate(:ascii, :numbers, :symbols, :length => 40)
    if save_after_op
      save
    end
  end

end
