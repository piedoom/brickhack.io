class QuestionnairesController < ApplicationController
  before_filter :logged_in
  before_filter :find_questionnaire, only: [:show, :update, :edit, :destroy]

  def logged_in
    authenticate_user!
  end

  # GET /apply
  # GET /apply.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @questionnaire }
    end
  end

  # GET /apply/new
  # GET /apply/new.json
  def new
    if current_user.questionnaire.present?
      return redirect_to questionnaires_path
    end
    @questionnaire = Questionnaire.new

    if session["devise.provider_data"] && session["devise.provider_data"]["info"]
      @questionnaire.tap do |q|
        q.first_name = session["devise.provider_data"]["info"]["first_name"]
        q.last_name = session["devise.provider_data"]["info"]["last_name"]
        q.phone = session["devise.provider_data"]["info"]["phone_number"]
        q.graduation = session["devise.provider_data"]["info"]["graduation"]
        q.major = session["devise.provider_data"]["info"]["major"]
        q.date_of_birth = session["devise.provider_data"]["info"]["date_of_birth"]
        q.shirt_size = session["devise.provider_data"]["info"]["shirt_size"]
        q.dietary_restrictions = session["devise.provider_data"]["info"]["dietary_restrictions"]
        q.special_needs = session["devise.provider_data"]["info"]["special_needs"]
        q.gender = session["devise.provider_data"]["info"]["gender"]

        school = School.where(name: session["devise.provider_data"]["info"]["school"]["name"]).first_or_create do |s|
          s.name = session["devise.provider_data"]["info"]["school"]["name"]
        end
        q.school_id = school.id
      end
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @questionnaire }
    end
  end

  # GET /apply/edit
  def edit
  end

  # POST /apply
  # POST /apply.json
  def create
    if current_user.questionnaire.present?
      return redirect_to questionnaires_path, notice: 'Application already exists.'
    end
    @questionnaire = Questionnaire.new(convert_school_name_to_id params[:questionnaire])

    respond_to do |format|
      if @questionnaire.save
        current_user.questionnaire = @questionnaire
        @questionnaire.update_attribute(:acc_status, "waitlist")
        Mailer.delay.application_confirmation_email(@questionnaire.id)
        format.html { redirect_to questionnaires_path, notice: 'Application was successfully created.' }
        format.json { render json: @questionnaire, status: :created, location: @questionnaire }
      else
        format.html { render action: "new" }
        format.json { render json: @questionnaire.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /apply
  # PUT /apply.json
  def update
    params[:questionnaire] = convert_school_name_to_id params[:questionnaire]

    respond_to do |format|
      if @questionnaire.update_attributes(params[:questionnaire])
        format.html { redirect_to questionnaires_path, notice: 'Application was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @questionnaire.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /apply
  # DELETE /apply.json
  def destroy
    @questionnaire.destroy

    respond_to do |format|
      format.html { redirect_to questionnaires_url }
      format.json { head :no_content }
    end
  end

  # GET /apply/schools
  def schools
    if params[:name].blank? || params[:name].length < 3
      head 400
      return
    end
    schools = School.where('name LIKE ?', "%#{params[:name]}%").limit(20).select(:name).all
    render json: schools.map(&:name)
  end

  private

  def find_questionnaire
    unless current_user.questionnaire.present?
      return redirect_to new_questionnaires_path
    end
    @questionnaire = current_user.questionnaire
  end

  def convert_school_name_to_id(questionnaire)
    if questionnaire[:school_name]
      school = School.where(name: questionnaire[:school_name]).first
      if school.blank?
        school = School.create(name: questionnaire[:school_name])
      end
      questionnaire[:school_id] = school.id
      questionnaire.delete :school_name
    end
    questionnaire
  end
end
