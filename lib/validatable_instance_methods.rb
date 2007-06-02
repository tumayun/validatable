module Validatable
  def self.included(klass) #:nodoc:
    klass.extend Validatable::ClassMethods
  end
  
  # call-seq: valid?
  #
  # Returns true if no errors were added otherwise false.
  def valid?
    valid_for_group?
  end
  
  # call-seq: errors
  #
  # Returns the Errors object that holds all information about attribute error messages.
  def errors
    @errors ||= Validatable::Errors.new
  end
  
  def valid_for_group?(group=nil) #:nodoc:
    errors.clear
    self.class.validate_children(self, group)
    self.validate(group)
    errors.empty?
  end
  
  def times_validated(key)
    times_validated_hash[key] || 0
  end
  
  def times_validated_hash
    @times_validated_hash ||= {}
  end
  
  def increment_times_validated_for(validation)
    if validation.key != nil
      if times_validated_hash[validation.key].nil?
        times_validated_hash[validation.key] = 1
      else
        times_validated_hash[validation.key] += 1
      end
    end
  end

  protected
  def validate(group) #:nodoc:
    validation_levels.each do |level|
      validations_for_level_and_group(level, group).each do |validation|
        run_validation(validation) if validation.should_validate?(self)
      end
      return unless self.errors.empty?
    end
  end

  def run_validation(validation) #:nodoc:
    validation_result = validation.valid?(self)
    add_error(validation.attribute, validation.message(self)) unless validation_result
    increment_times_validated_for(validation)
    validation.run_after_validate(validation_result, self, validation.attribute)
  end
  
  def add_error(attribute, message) #:nodoc:
    self.class.add_error(self, attribute, message)
  end
  
  def validations_for_level_and_group(level, group) #:nodoc:
    validations_for_level = self.class.validations.select { |validation| validation.level == level }
    return validations_for_level if group.nil?
    validations_for_level.select { |validation| validation.groups.include?(group) }
  end
  
  def validation_levels #:nodoc:
    self.class.validations.inject([1]) { |accum,validation| accum << validation.level }.uniq.sort
  end
end