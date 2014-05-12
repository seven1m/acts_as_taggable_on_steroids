class Tag < ActiveRecord::Base
  has_many :taggings, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  cattr_accessor :destroy_unused
  self.destroy_unused = false
  
  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(name)
    where("name LIKE ?", name).first || create(:name => name)
  end
  
  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  def to_s
    name
  end
  
  def count
    read_attribute(:count).to_i
  end
  
  class << self
    # Calculate the tag counts for all tags.
    #  :start_at - Restrict the tags to those created after a certain time
    #  :end_at - Restrict the tags to those created before a certain time
    #  :conditions - A piece of SQL conditions to add to the query
    #  :limit - The maximum number of tags to return
    #  :order - A piece of SQL to order by. Eg 'count desc' or 'taggings.created_at desc'
    #  :at_least - Exclude tags with a frequency less than the given value
    #  :at_most - Exclude tags with a frequency greater than the given value
    def counts(options = {})
      scope_for_counts(options).all
    end
    
    def scope_for_counts(options = {})
      options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit, :joins
      options = options.dup
      
      start_at = sanitize_sql(["#{Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
      end_at = sanitize_sql(["#{Tagging.table_name}.created_at <= ?", options.delete(:end_at)]) if options[:end_at]
      
      conditions = [
        (sanitize_sql(options.delete(:conditions)) if options[:conditions]),
        start_at,
        end_at
      ].compact
      
      conditions = conditions.join(' AND ') if conditions.any?

      scope = where(conditions)
      
      joins = ["INNER JOIN #{Tagging.table_name} ON #{Tag.table_name}.id = #{Tagging.table_name}.tag_id"]
      joins << options.delete(:joins) if options[:joins]

      scope = scope.joins(joins)

      scope = scope.group("#{Tag.table_name}.id, #{Tag.table_name}.name")

      at_least  = sanitize_sql(['COUNT(*) >= ?', options.delete(:at_least)]) if options[:at_least]
      at_most   = sanitize_sql(['COUNT(*) <= ?', options.delete(:at_most)]) if options[:at_most]
      ['COUNT(*) > 0', at_least, at_most].compact.each do |having|
        scope = scope.having(having)
      end

      scope.select("#{Tag.table_name}.id, #{Tag.table_name}.name, COUNT(*) AS count")
    end
  end
end
