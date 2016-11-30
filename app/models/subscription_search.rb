class SubscriptionSearch
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_accessor :results
  attr_accessor :keywords
  attr_accessor :pending
  attr_accessor :incomplete
  attr_accessor :complete
  attr_accessor :renewal
  attr_accessor :fresh
  attr_accessor :from
  attr_accessor :to
  attr_accessor :time_zone_offset
  
  def initialize(params = {})
    @results = Subscription.all


    # Set defaults
    @keywords = params[:keywords]
    @pending = ["1", "true"].include?(params[:pending].to_s)
    @complete = ["1", "true", ""].include?(params[:complete].to_s)
    @incomplete = ["1", "true", ""].include?(params[:incomplete].to_s)
    @renewal = ["1", "true", ""].include?(params[:renewal].to_s)
    @fresh = ["1", "true", ""].include?(params[:fresh].to_s)

    @time_zone_offset = params[:time_zone_offset].to_i
    @from = Date.today - 7.days
    @to = Date.today

    set_date_attr_from_string(:from, params[:from], params[:time_zone_offset])
    set_date_attr_from_string(:to, params[:to], params[:time_zone_offset])

    # Do some searching
    filter_by_date_range
      
    tokens = (params[:keywords] || "").split(' ')
    unless tokens.blank?
      tokens.each do |t|
        @results = @results.where([<<~SQL] + ["%#{t}%"] * 7)
          person_id in (select id from people where first_name ilike ? or last_name ilike ? or external_id ilike ? or mobile ilike ? or email ilike ?)
          or join_form_id in (select id from join_forms where short_name ilike ?)
          or source ilike ?
        SQL
      end
    end

    pending_sql = "(pending = true)" if @pending
    complete_sql = "(not completed_at is null)" if @complete
    incomplete_sql = "(pending = false and completed_at is null)" if @incomplete
    sql = [pending_sql, complete_sql, incomplete_sql].compact.join(' or ')
    @results = @results.where(sql) unless sql.blank?

    @results = @results.where(renewal: false) unless @renewal
    @results = @results.where(renewal: true) unless @fresh
  end
  
  def persisted?
    false
  end
  
  private
  def set_date_attr_from_string(attribute, date, offset)
    #Time.use_zone("UTC") { Time.zone.parse(date) + offset.to_i.minutes } 
    send("#{attribute}=", Date.parse(date)) unless date.blank?
  rescue ArgumentError
    errors.add attribute, "had an invalid date"
  end

  def filter_by_date_range
    @results = @results.where('subscriptions.updated_at > ?', to_gmt(@from))
    @results = @results.where('subscriptions.updated_at < ?', to_gmt(@to.next_day))
  end

  def to_gmt(date)
    # Convert a raw date into UTC time using client's time zone offset
    # Does this really have to be so hard
    Time.use_zone("UTC") { Time.zone.parse(date.iso8601) + @time_zone_offset.minutes }
  end
end
