class Manage::BusListsController < Manage::ApplicationController
  before_filter :set_bus_list, only: [:show, :edit, :update, :destroy, :toggle_bus_captain]

  respond_to :html

  def index
    @bus_lists = BusList.all
    respond_with(:manage, @bus_lists)
  end

  def show
    respond_with(:manage, @bus_list)
  end

  def new
    @bus_list = BusList.new
    respond_with(:manage, @bus_list)
  end

  def edit
  end

  def create
    @bus_list = BusList.new(params[:bus_list])
    @bus_list.save
    respond_with(:manage, @bus_list)
  end

  def update
    @bus_list.update_attributes(params[:bus_list])
    respond_with(:manage, @bus_list)
  end

  def destroy
    School.where(bus_list_id: @bus_list.id).each do |school|
      school.questionnaires.where(riding_bus: true).map { |q| q.update_attribute(:riding_bus, false) }
      school.update_attribute(:bus_list_id, nil)
    end
    @bus_list.destroy
    respond_with(:manage, @bus_list)
  end

  def toggle_bus_captain
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    is_bus_captain = params[:bus_captain] == "1"
    @questionnaire.update_attribute(:is_bus_captain, is_bus_captain)
    redirect_to [:manage, @bus_list]
  end

  private
    def set_bus_list
      @bus_list = BusList.find(params[:id])
    end
end
