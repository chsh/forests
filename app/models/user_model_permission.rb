class UserModelPermission < ActiveRecord::Base
  include FlagShihTzu

  belongs_to :user
  belongs_to :model, polymorphic: true

  has_flags 1 => :creatable,
            2 => :readable,
            3 => :updatable,
            4 => :destroyable

  scope :assigned, lambda { |model|
    if model.is_a? User
      self.where(user_id: model.id)
    elsif model.is_a? Class
      self.where(model_type: model.name)
    else
      self.where(model_type: model.class.name, model_id: model.id)
    end
  }

  def self.creatable?
    self.creatable.count > 0
  end
  def self.readable?
    self.readable.count > 0
  end
  def self.updatable?
    self.updatable.count > 0
  end
  def self.destroyable?
    self.destroyable.count > 0
  end

  def self.assign(object, *operations)
    operations = [operations].flatten
    transaction do
      instance = nil
      if object.is_a? User
        instance = self.find_by_user_id object
        unless instance
          instance = self.create user: object
        end
      else
        instance = self.find_by_model_type_and_model_id object.class.name, object.id
        unless instance
          instance = self.create model: object
        end
      end
      instance.send :assign_operations, operations
      instance.save
    end
  end
  def self.unassign(object, *operations)
    operations = [operations].flatten
    transaction do
      instance = nil
      if object.is_a? User
        instance = self.find_by_user_id object
        unless instance
          instance = self.create user: object
        end
      else
        instance = self.find_by_model_type_and_model_id object.class.name, object.id
        unless instance
          instance = self.create model: object
        end
      end
      instance.send :assign_operations, operations
      instance.save
    end
  end

  private
  def assign_operations(operations)
    operations.each do |operation|
      self.send("#{operation}=", true)
    end
  end
  def unassign_operations(operations)
    operations.each do |operation|
      self.send("#{operation}=", false)
    end
  end

end
