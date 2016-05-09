class JoinFormsController < ApplicationController
  before_action :set_join_form, only: [:edit, :update, :destroy, :show]
  before_action :forbid, only: [:edit, :update]
  
  # GET /join_forms
  # GET /join_forms.json
  def index
    #@join_forms = JoinForm.all
    redirect_to union_path(@union)
  end

  def show
    redirect_to subscription_form_path(Subscription.new(join_form: @join_form, person: Person.new))
  end

  # GET /join_forms/new
  def new
    @join_form = JoinForm.new
    @join_form.union = @union
  end

  # GET /join_forms/1/edit
  def edit
  end

  # POST /join_forms
  # POST /join_forms.json
  def create
    @join_form = JoinForm.new(join_form_params)
    @join_form.authorizer = current_person
    
    respond_to do |format|
      if @join_form.save
        notify

        format.html { redirect_to @join_form.union, notice: "Your new join form was successfully created." }
        format.json { render :show, status: :created, location: @join_form }
      else
        format.html { render :new }
        format.json { render json: @join_form.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /join_forms/1
  # PATCH/PUT /join_forms/1.json
  def update
    @join_form.authorizer = current_person
    respond_to do |format|
      if @join_form.update(join_form_params)
        format.html { redirect_to @join_form.union, notice: 'The join form was successfully updated.' }
        format.json { render :show, status: :ok, location: @join_form }
      else
        format.html { render :edit }
        format.json { render json: @join_form.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /join_forms/1
  # DELETE /join_forms/1.json
  def destroy
    union = @join_form.union
    @join_form.destroy
    respond_to do |format|
      format.html { redirect_to union, notice: 'The join form was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_join_form
      @join_form = JoinForm.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def join_form_params
      result = params.require(:join_form).permit(:short_name, :description, :css, :header, :page_title, :base_rate_id, :base_rate_establishment, :base_rate_weekly, :base_rate_fortnightly, :base_rate_monthly, :base_rate_quarterly, :base_rate_half_yearly, :base_rate_yearly, :union_id, :person_id, :message_types => [])
      result['message_types'].delete("") if result['message_types']
      result
    end

    def forbid
      return forbidden unless can_edit_union?(@join_form.union)
    end

    def notification_recipients(join_form)
      join_form.union.people.reject { |p| p.id == current_person.id || p.invitation_accepted_at.blank? }
    end

    def notify
      notification_recipients(@join_form).each do |p|
        PersonMailer.join_form_notice(p, @join_form, request).deliver_now
      end
    end
end
